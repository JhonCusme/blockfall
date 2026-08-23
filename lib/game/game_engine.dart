/// El bucle del juego: aparición de piezas, gravedad, lock delay, game over.
///
/// El motor no sabe nada de tiempo real ni de Flutter. La UI le va dando
/// [tick] con los milisegundos transcurridos y él avanza. Eso lo hace
/// simulable a máxima velocidad en un test.
library;

import 'bag.dart';
import 'board.dart';
import 'scoring.dart';
import 'srs.dart';
import 'tetromino.dart';

enum GameStatus { ready, playing, paused, gameOver }

/// Modos de juego. El motor los conoce porque cambian la condición de final.
enum GameMode {
  /// Sin final: sube de nivel hasta que pierdes.
  marathon,

  /// Carrera a 40 líneas, lo más rápido posible.
  sprint,

  /// Máxima puntuación en dos minutos.
  ultra,

  /// Sin presión ni game over.
  zen,

  /// Uno contra uno.
  versus,
}

/// Lo que acaba de pasar, para que la UI dispare sonido, vibración y animación.
class GameEvent {
  final ClearKind kind;
  final List<int> clearedRows;
  final int garbageSent;
  final bool pieceLocked;
  final bool leveledUp;

  const GameEvent({
    this.kind = ClearKind.none,
    this.clearedRows = const [],
    this.garbageSent = 0,
    this.pieceLocked = false,
    this.leveledUp = false,
  });
}

class GameEngine {
  static const int nextQueueSize = 5;
  static const int lockDelayMs = 500;

  /// Cuántas veces se puede reiniciar el lock delay moviendo la pieza. Sin este
  /// límite se puede mantener una pieza flotando para siempre.
  static const int maxLockResets = 15;

  final GameMode mode;
  final Board board = Board();
  final PieceBag _bag;
  late final Scoring scoring;

  GameStatus status = GameStatus.ready;
  ActivePiece? current;
  PieceType? held;

  /// El hold solo se puede usar una vez por pieza.
  bool _holdUsedThisPiece = false;

  int _gravityAccumulator = 0;
  int _lockTimer = 0;
  int _lockResets = 0;
  bool _touchingGround = false;

  bool _lastMoveWasRotation = false;
  bool _lastRotationUsedKick = false;

  /// Milisegundos jugados. Los modos Ultra y Sprint lo necesitan.
  int elapsedMs = 0;

  /// Basura pendiente de recibir en multijugador. Se aplica al fijar la pieza,
  /// no al instante, para que el jugador pueda reaccionar.
  int pendingGarbage = 0;

  GameEngine({this.mode = GameMode.marathon, int? seed, int startLevel = 1})
      : _bag = PieceBag(seed: seed) {
    scoring = Scoring(startLevel: startLevel);
  }

  List<PieceType> get nextPieces => _bag.peek(nextQueueSize);

  bool get isRunning => status == GameStatus.playing;

  void start() {
    status = GameStatus.playing;
    _spawn();
  }

  void pause() {
    if (status == GameStatus.playing) status = GameStatus.paused;
  }

  void resume() {
    if (status == GameStatus.paused) status = GameStatus.playing;
  }

  /// Avanza el juego [deltaMs] milisegundos. Devuelve lo que haya ocurrido.
  GameEvent tick(int deltaMs) {
    if (!isRunning) return const GameEvent();
    elapsedMs += deltaMs;

    if (mode == GameMode.ultra && elapsedMs >= 120000) {
      status = GameStatus.gameOver;
      return const GameEvent();
    }

    final piece = current;
    if (piece == null) return const GameEvent();

    _touchingGround = !board.fits(piece.moved(0, 1));

    if (_touchingGround) {
      // Apoyada: corre el reloj de fijación.
      _lockTimer += deltaMs;
      _gravityAccumulator = 0;
      if (_lockTimer >= lockDelayMs) return _lockPiece();
    } else {
      _lockTimer = 0;
      _gravityAccumulator += deltaMs;
      final step = gravityMs(scoring.level);
      while (_gravityAccumulator >= step) {
        _gravityAccumulator -= step;
        final moved = piece.moved(0, 1);
        if (board.fits(moved)) {
          current = moved;
          _lastMoveWasRotation = false;
        } else {
          break;
        }
      }
    }
    return const GameEvent();
  }

  bool moveLeft() => _translate(-1, 0);
  bool moveRight() => _translate(1, 0);

  /// Baja una celda por orden del jugador. Suma un punto.
  bool softDrop() {
    if (_translate(0, 1)) {
      scoring.addSoftDrop(1);
      return true;
    }
    return false;
  }

  /// Baja la pieza hasta el fondo y la fija de inmediato.
  GameEvent hardDrop() {
    final piece = current;
    if (piece == null || !isRunning) return const GameEvent();
    var distance = 0;
    var p = piece;
    while (board.fits(p.moved(0, 1))) {
      p = p.moved(0, 1);
      distance++;
    }
    current = p;
    scoring.addHardDrop(distance);
    if (distance > 0) _lastMoveWasRotation = false;
    return _lockPiece();
  }

  bool rotateCw() => _rotate(current?.rotation.cw);
  bool rotateCcw() => _rotate(current?.rotation.ccw);

  /// Guarda la pieza actual, o la intercambia con la guardada.
  bool hold() {
    final piece = current;
    if (piece == null || !isRunning || _holdUsedThisPiece) return false;
    final previous = held;
    held = piece.type;
    _holdUsedThisPiece = true;
    if (previous == null) {
      _spawn();
    } else {
      _spawnType(previous);
    }
    return true;
  }

  /// Dónde caería la pieza actual: la sombra que se dibuja en el tablero.
  ActivePiece? get ghost {
    final piece = current;
    if (piece == null) return null;
    var p = piece;
    while (board.fits(p.moved(0, 1))) {
      p = p.moved(0, 1);
    }
    return p;
  }

  /// Encola basura enviada por el rival.
  void receiveGarbage(int lines) => pendingGarbage += lines;

  /// Cuántas filas despeja un revivir.
  static const int reviveClearedRows = 8;

  /// Si el jugador ya gastó su única oportunidad de revivir.
  bool reviveUsed = false;

  /// ¿Se puede ofrecer revivir ahora mismo?
  ///
  /// Solo tras un game over de verdad, una vez por partida, y nunca en Zen
  /// (que no tiene game over) ni en versus (revivir rompería el duelo).
  bool get canRevive =>
      status == GameStatus.gameOver &&
      !reviveUsed &&
      mode != GameMode.zen &&
      mode != GameMode.versus &&
      // En Sprint el final por 40 líneas es una victoria, no una derrota.
      !(mode == GameMode.sprint && scoring.lines >= 40) &&
      !(mode == GameMode.ultra && elapsedMs >= 120000);

  /// Continúa la partida tras ver el anuncio. Devuelve `false` si no procedía.
  bool revive() {
    if (!canRevive) return false;
    reviveUsed = true;
    board.clearTopRows(reviveClearedRows);
    pendingGarbage = 0;
    status = GameStatus.playing;
    _holdUsedThisPiece = false;
    _spawn();
    // Si ni despejando ocho filas cabe la pieza, el revivir no vale de nada.
    return status == GameStatus.playing;
  }

  // --- interna ---

  bool _translate(int dx, int dy) {
    final piece = current;
    if (piece == null || !isRunning) return false;
    final moved = piece.moved(dx, dy);
    if (!board.fits(moved)) return false;
    current = moved;
    _lastMoveWasRotation = false;
    _resetLockTimer();
    return true;
  }

  bool _rotate(Rotation? target) {
    final piece = current;
    if (piece == null || target == null || !isRunning) return false;

    final candidates = kicks(piece.type, piece.rotation, target);
    for (var i = 0; i < candidates.length; i++) {
      final k = candidates[i];
      final rotated = piece.rotated(target).moved(k.x, k.y);
      if (board.fits(rotated)) {
        current = rotated;
        _lastMoveWasRotation = true;
        // El último kick de la tabla es el que habilita el T-Spin Triple.
        _lastRotationUsedKick = i == candidates.length - 1;
        _resetLockTimer();
        return true;
      }
    }
    return false;
  }

  /// Mover o girar una pieza apoyada le devuelve tiempo antes de fijarse, pero
  /// solo un número limitado de veces.
  void _resetLockTimer() {
    if (_touchingGround && _lockResets < maxLockResets) {
      _lockTimer = 0;
      _lockResets++;
    }
  }

  GameEvent _lockPiece() {
    final piece = current;
    if (piece == null) return const GameEvent();

    board.lock(piece);
    final levelBefore = scoring.level;

    final result = board.clearLines();
    final kind = detectTSpin(
      board: board,
      piece: piece,
      lastMoveWasRotation: _lastMoveWasRotation,
      usedKick: _lastRotationUsedKick,
      linesCleared: result.linesCleared,
    );
    scoring.register(kind);
    final garbage = mode == GameMode.versus ? scoring.garbageFor(kind) : 0;

    // La basura recibida solo entra si no has despejado nada este turno: hacer
    // líneas cancela el ataque pendiente, que es la regla que hace interesante
    // el versus.
    if (result.linesCleared == 0 && pendingGarbage > 0) {
      final hole = DateTime.now().microsecondsSinceEpoch % Board.width;
      board.addGarbage(pendingGarbage, hole);
      pendingGarbage = 0;
    } else if (result.linesCleared > 0) {
      pendingGarbage = (pendingGarbage - result.linesCleared).clamp(0, 9999);
    }

    if (mode == GameMode.sprint && scoring.lines >= 40) {
      status = GameStatus.gameOver;
    }

    current = null;
    _holdUsedThisPiece = false;
    if (status == GameStatus.playing) _spawn();

    return GameEvent(
      kind: kind,
      clearedRows: result.clearedRows,
      garbageSent: garbage,
      pieceLocked: true,
      leveledUp: scoring.level > levelBefore,
    );
  }

  void _spawn() => _spawnType(_bag.next());

  void _spawnType(PieceType type) {
    final shape = Tetromino.of(type);
    // Centrada, y arrancando en las filas ocultas.
    final x = ((Board.width - shape.boxSize) / 2).floor();
    final piece = ActivePiece(
      type: type,
      rotation: Rotation.spawn,
      x: x,
      y: 0,
    );

    _gravityAccumulator = 0;
    _lockTimer = 0;
    _lockResets = 0;
    _lastMoveWasRotation = false;
    _lastRotationUsedKick = false;

    // Block out: si la pieza nueva no cabe, se acabó.
    if (!board.fits(piece)) {
      current = piece;
      if (mode != GameMode.zen) status = GameStatus.gameOver;
      return;
    }
    current = piece;
  }
}
