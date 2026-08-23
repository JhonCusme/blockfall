/// La pantalla de juego: tablero, HUD, controles y bucle de render.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_repository.dart';
import '../../game/board.dart';
import '../../game/game_engine.dart';
import '../../game/scoring.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';
import '../../state/online_state.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/board_painter.dart';
import '../widgets/hud.dart';

class GameScreen extends ConsumerStatefulWidget {
  final GameMode mode;

  const GameScreen({super.key, this.mode = GameMode.marathon});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameEngine engine;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  /// Filas destellando y desde cuándo, para la animación de borrado.
  List<int> _flashRows = const [];
  int _flashElapsed = 0;
  static const int _flashDurationMs = 180;

  /// Texto grande que aparece un instante al hacer una jugada buena.
  String? _toast;
  int _toastElapsed = 0;

  /// Evita guardar dos veces el récord si el diálogo se reconstruye.
  bool _recordSaved = false;

  // Accesos cortos al estado global. Se usa `read` y no `watch` porque estos
  // se consultan dentro del bucle de juego, donde no queremos reconstruir.
  BlockTheme get _theme => ref.read(themeProvider);
  Settings get _settings => ref.read(settingsProvider);
  AudioService get _audio => ref.read(audioServiceProvider);

  @override
  void initState() {
    super.initState();
    engine = GameEngine(mode: widget.mode)..start();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final deltaMs = (elapsed - _last).inMilliseconds;
    if (deltaMs <= 0) return;
    _last = elapsed;

    // Un frame muy largo (la app estuvo en segundo plano) no debe teletransportar
    // la pieza al fondo.
    final delta = deltaMs.clamp(0, 100);

    final event = engine.tick(delta);
    _consume(event);

    if (_flashRows.isNotEmpty) {
      _flashElapsed += delta;
      if (_flashElapsed >= _flashDurationMs) _flashRows = const [];
    }
    if (_toast != null) {
      _toastElapsed += delta;
      if (_toastElapsed > 900) _toast = null;
    }

    setState(() {});
  }

  void _consume(GameEvent event) {
    final vibrate = _settings.vibrationEnabled;

    if (event.clearedRows.isNotEmpty) {
      _flashRows = event.clearedRows;
      _flashElapsed = 0;
      if (vibrate) HapticFeedback.mediumImpact();
      _audio.play(switch (event.kind) {
        ClearKind.tetris => Sfx.tetris,
        ClearKind.tSpinSingle ||
        ClearKind.tSpinDouble ||
        ClearKind.tSpinTriple ||
        ClearKind.tSpinMini =>
          Sfx.tSpin,
        _ => Sfx.clear,
      });
    } else if (event.pieceLocked) {
      if (vibrate) HapticFeedback.selectionClick();
      _audio.play(Sfx.lock);
    }

    if (event.leveledUp) _audio.play(Sfx.levelUp);

    final name = _nameOf(event.kind);
    if (name != null) {
      _toast = name;
      _toastElapsed = 0;
    }

    if (engine.status == GameStatus.gameOver) {
      _audio.play(Sfx.gameOver);
      if (vibrate) HapticFeedback.heavyImpact();
      _showGameOver();
    }
  }

  String? _nameOf(ClearKind kind) {
    final t = L.of(context);
    return switch (kind) {
      ClearKind.tetris => t.clearTetris,
      ClearKind.triple => t.clearTriple,
      ClearKind.tSpinSingle => t.clearTSpin,
      ClearKind.tSpinDouble => t.clearTSpinDouble,
      ClearKind.tSpinTriple => t.clearTSpinTriple,
      ClearKind.tSpinMini => t.clearTSpinMini,
      _ => null,
    };
  }

  void _showGameOver() {
    if (_recordSaved) return;
    _ticker.stop();

    // Si aún queda la oportunidad de revivir, no se guarda nada todavía: la
    // partida puede continuar y el resultado final sería otro.
    if (engine.canRevive && ref.read(adsServiceProvider).isRewardedReady) {
      _showReviveOffer();
      return;
    }

    _finishGame();
  }

  /// Cierra la partida: guarda el récord y enseña el resultado.
  void _finishGame() {
    if (_recordSaved) return;
    _recordSaved = true;

    // Zen no tiene récords: es un modo para jugar sin presión.
    if (widget.mode != GameMode.zen) {
      ref.read(localRepositoryProvider).saveRecord(
            widget.mode,
            ScoreRecord(
              score: engine.scoring.score,
              lines: engine.scoring.lines,
              level: engine.scoring.level,
              durationMs: engine.elapsedMs,
              date: DateTime.now(),
            ),
          );

      // Y al ranking global. Si no hay red se encola y sube más tarde; el
      // jugador no tiene que enterarse de nada.
      final remote = ref.read(remoteRepositoryProvider);
      if (remote != null) {
        unawaited(
          remote.submitScore(
            mode: widget.mode,
            score: engine.scoring.score,
            lines: engine.scoring.lines,
            level: engine.scoring.level,
            durationMs: engine.elapsedMs,
          ),
        );
      }
    }

    // El intersticial va DESPUÉS de enseñar el resultado, nunca antes: tapar
    // la puntuación con un anuncio es la forma más rápida de que desinstalen
    // el juego.
    unawaited(ref.read(adsServiceProvider).onGameFinished());

    final t = L.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _theme.boardBackground,
        title: Text(
          widget.mode == GameMode.sprint && engine.scoring.lines >= 40
              ? t.gameCompletedTitle
              : t.gameOverTitle,
          style: TextStyle(color: _theme.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.gameOverScore(engine.scoring.score),
                style: TextStyle(color: _theme.text)),
            Text(t.gameOverLines(engine.scoring.lines),
                style: TextStyle(color: _theme.text)),
            Text(t.gameOverLevel(engine.scoring.level),
                style: TextStyle(color: _theme.text)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(t.actionExit),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                // Reiniciar es crear un motor nuevo: nada de estado residual.
                engine.board.grid
                  ..clear()
                  ..addAll(Board().grid);
              });
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => GameScreen(mode: widget.mode),
                ),
              );
            },
            child: Text(t.actionRetry),
          ),
        ],
      ),
    );
  }

  /// Ofrece continuar la partida a cambio de ver un vídeo.
  ///
  /// Es una sola oportunidad por partida. El diálogo no se puede esquivar
  /// tocando fuera: hay que elegir, o revivir o terminar.
  void _showReviveOffer() {
    final theme = _theme;
    final t = L.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.boardBackground,
        title: Text(t.reviveTitle, style: TextStyle(color: theme.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.reviveBody(engine.scoring.score),
              style: TextStyle(color: theme.text),
            ),
            const SizedBox(height: 10),
            Text(
              t.reviveOnce,
              style: TextStyle(
                color: theme.text.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _finishGame();
            },
            child: Text(t.reviveDecline),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: theme.accent),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final earned = await ref.read(adsServiceProvider).showRewarded();
              if (!mounted) return;
              // Solo revive quien vio el vídeo entero. Si lo cerró antes, o
              // si falló, la partida termina — pero sin gastarle el intento.
              if (earned && engine.revive()) {
                setState(() {
                  _toast = null;
                  _flashRows = const [];
                  _last = Duration.zero;
                });
                _ticker.start();
              } else {
                _finishGame();
              }
            },
            icon: const Icon(Icons.play_circle_outline),
            label: Text(t.reviveAccept),
          ),
        ],
      ),
    );
  }

  void _togglePause() {
    setState(() {
      if (engine.status == GameStatus.playing) {
        engine.pause();
      } else {
        engine.resume();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(theme),
            _infoStrip(theme),
            Expanded(child: _playfield(theme)),
            if (ref.watch(settingsProvider).showButtons) _controls(theme),
          ],
        ),
      ),
    );
  }

  /// Coloca tablero y paneles.
  ///
  /// El tablero se dimensiona a partir de la ALTURA disponible, no del ancho
  /// sobrante: con la proporción 10x20, dejarlo al ancho lo encoge y deja un
  /// hueco muerto debajo. Solo si así no cabe a lo ancho se reduce.
  Widget _playfield(BlockTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // El tablero se lleva todo el ancho disponible, y si con eso se sale
        // por abajo, manda la altura.
        final maxWidth = constraints.maxWidth - 16;
        final maxHeight = constraints.maxHeight - 8;

        var boardWidth = maxHeight * Board.width / Board.visibleHeight;
        if (boardWidth > maxWidth) boardWidth = maxWidth;
        final boardHeight = boardWidth * Board.visibleHeight / Board.width;

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: _boardArea(theme),
          ),
        );
      },
    );
  }

  /// Franja superior con hold, marcador y próximas piezas.
  Widget _infoStrip(BlockTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HoldBox(piece: engine.held, available: true, theme: theme),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              // En pantallas estrechas el marcador se encoge en vez de
              // desbordarse con las rayas amarillas de Flutter.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: StatsRow(engine: engine, theme: theme),
              ),
            ),
          ),
          NextStrip(pieces: engine.nextPieces, theme: theme),
        ],
      ),
    );
  }

  Widget _topBar(BlockTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            'BLOCKFALL',
            style: TextStyle(
              color: theme.accent,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _togglePause,
            icon: Icon(
              engine.status == GameStatus.paused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              color: theme.text,
            ),
          ),
        ],
      ),
    );
  }

  // --- gestos ---
  //
  // Arrastrar mueve la pieza celda a celda: se acumula el desplazamiento y se
  // dispara un movimiento cada vez que supera el ancho de una celda. Un toque
  // seco rota; un arrastre rápido hacia abajo es hard drop; hacia arriba, hold.

  double _dragX = 0;
  double _dragY = 0;
  bool _dragMoved = false;
  double _cellSize = 24;

  void _onPanStart(DragStartDetails _) {
    _dragX = 0;
    _dragY = 0;
    _dragMoved = false;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _dragX += d.delta.dx;
    _dragY += d.delta.dy;

    final threshold = _cellSize * 0.8;
    while (_dragX.abs() >= threshold) {
      final moved = _dragX > 0 ? engine.moveRight() : engine.moveLeft();
      _dragX += _dragX > 0 ? -threshold : threshold;
      if (moved) _audio.play(Sfx.move);
      _dragMoved = true;
    }

    // Soft drop mientras se arrastra hacia abajo, pero solo si el gesto es
    // claramente vertical: si no, mover en diagonal haría caer la pieza.
    if (_dragY >= threshold && _dragX.abs() < threshold) {
      engine.softDrop();
      _dragY -= threshold;
      _dragMoved = true;
    }
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    if (v.dy > 1200 && v.dy.abs() > v.dx.abs()) {
      _audio.play(Sfx.hardDrop);
      _consume(engine.hardDrop());
    } else if (v.dy < -1200 && v.dy.abs() > v.dx.abs()) {
      if (engine.hold()) _audio.play(Sfx.hold);
    }
    setState(() {});
  }

  void _onTapUp(TapUpDetails d) {
    if (_dragMoved) return;
    if (engine.rotateCw()) _audio.play(Sfx.rotate);
    setState(() {});
  }

  Widget _boardArea(BlockTheme theme) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapUp: _onTapUp,
      onLongPress: _togglePause,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _cellSize = constraints.maxWidth / Board.width;
          return _boardStack(theme);
        },
      ),
    );
  }

  Widget _boardStack(BlockTheme theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CustomPaint(
            painter: BoardPainter(
              engine: engine,
              theme: theme,
              flashingRows: _flashRows,
              flashProgress: _flashElapsed / _flashDurationMs,
              showGhost: _settings.showGhost,
            ),
            size: Size.infinite,
          ),
        ),
        if (_toast != null)
          Text(
            _toast!,
            style: TextStyle(
              color: theme.accent,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 8),
              ],
            ),
          ),
        if (engine.status == GameStatus.paused)
          Container(
            color: Colors.black.withValues(alpha: 0.85),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  L.of(context).hudPause,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 32),
                // Banner solo con el juego detenido, y separado del centro
                // para que nadie lo toque al ir a reanudar.
                const AdBanner(),
              ],
            ),
          ),
      ],
    );
  }

  /// Botones en pantalla, como alternativa a los gestos. Hay gente que los
  /// prefiere, y en pantallas pequeñas son más precisos.
  Widget _controls(BlockTheme theme) {
    Widget button(IconData icon, VoidCallback onTap, {int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: theme.boardBackground,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                onTap();
                setState(() {});
              },
              child: SizedBox(
                height: 56,
                child: Icon(icon, color: theme.text),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          button(Icons.swap_horiz_rounded, () {
            if (engine.hold()) _audio.play(Sfx.hold);
          }),
          button(Icons.arrow_left_rounded, () {
            if (engine.moveLeft()) _audio.play(Sfx.move);
          }, flex: 2),
          button(Icons.rotate_right_rounded, () {
            if (engine.rotateCw()) _audio.play(Sfx.rotate);
          }),
          button(Icons.arrow_right_rounded, () {
            if (engine.moveRight()) _audio.play(Sfx.move);
          }, flex: 2),
          button(Icons.keyboard_double_arrow_down_rounded, () {
            _audio.play(Sfx.hardDrop);
            _consume(engine.hardDrop());
          }),
        ],
      ),
    );
  }
}
