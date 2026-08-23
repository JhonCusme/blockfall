/// Paneles laterales: puntuación, próximas piezas y pieza guardada.
library;

import 'package:flutter/material.dart';

import '../../game/game_engine.dart';
import '../../game/tetromino.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';
import 'board_painter.dart';

class HudPanel extends StatelessWidget {
  final String label;
  final Widget child;
  final BlockTheme theme;

  const HudPanel({
    super.key,
    required this.label,
    required this.child,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: theme.text.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.boardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.gridLine),
          ),
          child: child,
        ),
      ],
    );
  }
}

class HoldBox extends StatelessWidget {
  final PieceType? piece;
  final bool available;
  final BlockTheme theme;

  const HoldBox({
    super.key,
    required this.piece,
    required this.available,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      label: L.of(context).hudHold,
      theme: theme,
      child: SizedBox(
        width: 44,
        height: 34,
        child: CustomPaint(
          painter: PiecePreviewPainter(
            type: piece,
            theme: theme,
            dimmed: !available,
          ),
        ),
      ),
    );
  }
}

/// Las próximas piezas en fila horizontal.
///
/// En un móvil vertical el ancho es oro: una columna lateral de "next" encoge
/// el tablero mucho más de lo que aporta. En horizontal cabe arriba y el
/// tablero se queda con toda la pantalla.
class NextStrip extends StatelessWidget {
  final List<PieceType> pieces;
  final BlockTheme theme;

  const NextStrip({super.key, required this.pieces, required this.theme});

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      label: L.of(context).hudNext,
      theme: theme,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in pieces)
            SizedBox(
              width: 34,
              height: 30,
              child: CustomPaint(
                painter: PiecePreviewPainter(type: p, theme: theme),
              ),
            ),
        ],
      ),
    );
  }
}

/// Puntos, nivel y líneas en una sola fila compacta.
class StatsRow extends StatelessWidget {
  final GameEngine engine;
  final BlockTheme theme;

  const StatsRow({super.key, required this.engine, required this.theme});

  @override
  Widget build(BuildContext context) {
    final s = engine.scoring;
    final t = L.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _cell(t.hudScore, formatScore(s.score), big: true),
        _cell(t.hudLevel, '${s.level}'),
        _cell(t.hudLines, '${s.lines}'),
        if (engine.mode == GameMode.sprint)
          _cell(t.hudRemaining, '${(40 - s.lines).clamp(0, 40)}'),
        if (engine.mode == GameMode.ultra)
          _cell(t.hudTime, formatClock(120000 - engine.elapsedMs)),
        if (s.combo > 0) _cell(t.hudCombo, '${s.combo}x'),
      ],
    );
  }

  /// El separador va dentro de la celda y no en el `Row`: dentro de un
  /// `FittedBox` el ancho no está acotado, así que `spaceEvenly` no separa
  /// nada y las etiquetas se pegan unas a otras.
  Widget _cell(String label, String value, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: theme.text.withValues(alpha: 0.55),
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: theme.text,
                fontSize: big ? 20 : 15,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
}

/// Separador de miles, para que 128400 se lea de un vistazo.
///
/// Se usa el punto en ambos idiomas: el marcador de un juego se lee igual en
/// todas partes y cambiarlo por idioma solo confundiría al comparar récords.
String formatScore(int score) {
  final s = score.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

/// Minutos y segundos, para la cuenta atrás del modo Ultra.
String formatClock(int ms) {
  final clamped = ms.clamp(0, 999999);
  final totalSeconds = clamped ~/ 1000;
  final m = totalSeconds ~/ 60;
  final sec = totalSeconds % 60;
  return '$m:${sec.toString().padLeft(2, '0')}';
}
