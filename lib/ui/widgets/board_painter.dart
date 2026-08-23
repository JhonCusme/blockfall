/// Dibujo del tablero.
///
/// Un Tetris son rectángulos en una grilla, así que un `CustomPainter` es más
/// rápido y más simple que construir un árbol de 200 widgets por frame.
library;

import 'package:flutter/material.dart';

import '../../game/board.dart';
import '../../game/game_engine.dart';
import '../../game/tetromino.dart';
import '../theme.dart';

class BoardPainter extends CustomPainter {
  final GameEngine engine;
  final BlockTheme theme;

  /// Filas que están destellando tras completarse, con su progreso de 0 a 1.
  final List<int> flashingRows;
  final double flashProgress;

  /// La sombra de caída se puede desactivar en Ajustes: hay quien la considera
  /// una ayuda excesiva.
  final bool showGhost;

  BoardPainter({
    required this.engine,
    required this.theme,
    this.flashingRows = const [],
    this.flashProgress = 0,
    this.showGhost = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / Board.width;

    _paintBackground(canvas, size);
    _paintGrid(canvas, size, cell);
    _paintLockedCells(canvas, cell);
    if (showGhost) _paintGhost(canvas, cell);
    _paintCurrent(canvas, cell);
    _paintFlash(canvas, size, cell);
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = theme.boardBackground,
    );
  }

  void _paintGrid(Canvas canvas, Size size, double cell) {
    final paint = Paint()
      ..color = theme.gridLine
      ..strokeWidth = 1;
    for (var x = 1; x < Board.width; x++) {
      canvas.drawLine(
          Offset(x * cell, 0), Offset(x * cell, size.height), paint);
    }
    for (var y = 1; y < Board.visibleHeight; y++) {
      canvas.drawLine(Offset(0, y * cell), Offset(size.width, y * cell), paint);
    }
  }

  /// Convierte una fila de la grilla interna a coordenadas de pantalla.
  /// Las dos primeras filas están ocultas, así que se restan.
  double _screenY(int gridY, double cell) => (gridY - Board.hiddenRows) * cell;

  void _paintLockedCells(Canvas canvas, double cell) {
    for (var y = Board.hiddenRows; y < Board.height; y++) {
      for (var x = 0; x < Board.width; x++) {
        final type = engine.board.at(x, y);
        if (type == null) continue;
        _drawBlock(
            canvas, x * cell, _screenY(y, cell), cell, theme.colorOf(type));
      }
    }
  }

  void _paintGhost(Canvas canvas, double cell) {
    final ghost = engine.ghost;
    final current = engine.current;
    if (ghost == null || current == null) return;
    // Si la sombra está justo donde la pieza, no la dibujamos: solo emborrona.
    if (ghost.y == current.y) return;

    // Con poca opacidad la sombra desaparece en los temas de fondo muy oscuro,
    // así que se dibuja el contorno bien marcado y un relleno muy tenue.
    final base = theme.colorOf(ghost.type);
    final color = base.withValues(alpha: 0.55);
    for (final c in ghost.boardCells) {
      if (c.y < Board.hiddenRows) continue;
      final rect = Rect.fromLTWH(
        c.x * cell + 1,
        _screenY(c.y, cell) + 1,
        cell - 2,
        cell - 2,
      );
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.12));
      canvas.drawRRect(
        rrect,
        Paint()..color = base.withValues(alpha: 0.13),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _paintCurrent(Canvas canvas, double cell) {
    final piece = engine.current;
    if (piece == null) return;
    final color = theme.colorOf(piece.type);
    for (final c in piece.boardCells) {
      if (c.y < Board.hiddenRows) continue;
      _drawBlock(canvas, c.x * cell, _screenY(c.y, cell), cell, color);
    }
  }

  /// Destello blanco sobre las filas que se acaban de completar.
  void _paintFlash(Canvas canvas, Size size, double cell) {
    if (flashingRows.isEmpty) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (1 - flashProgress) * 0.85);
    for (final row in flashingRows) {
      if (row < Board.hiddenRows) continue;
      canvas.drawRect(
        Rect.fromLTWH(0, _screenY(row, cell), size.width, cell),
        paint,
      );
    }
  }

  /// Un bloque con un borde claro arriba y sombra abajo: da volumen sin
  /// necesidad de imágenes.
  void _drawBlock(Canvas canvas, double x, double y, double cell, Color color) {
    final rect = Rect.fromLTWH(x + 1, y + 1, cell - 2, cell - 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.12));

    canvas.drawRRect(rrect, Paint()..color = color);

    // Brillo superior.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.35),
        Radius.circular(cell * 0.12),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Contorno oscuro para separar bloques del mismo color.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}

/// Dibuja una pieza suelta, para los paneles "Next" y "Hold".
class PiecePreviewPainter extends CustomPainter {
  final PieceType? type;
  final BlockTheme theme;
  final bool dimmed;

  PiecePreviewPainter({
    required this.type,
    required this.theme,
    this.dimmed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = type;
    if (t == null) return;
    final shape = Tetromino.of(t);
    final cells = shape.cells(Rotation.spawn);

    // Encuadrar la pieza en su caja real, no en la de rotación: si no, la I y
    // la O se ven descentradas.
    final minX = cells.map((c) => c.x).reduce((a, b) => a < b ? a : b);
    final maxX = cells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final minY = cells.map((c) => c.y).reduce((a, b) => a < b ? a : b);
    final maxY = cells.map((c) => c.y).reduce((a, b) => a > b ? a : b);
    final w = maxX - minX + 1;
    final h = maxY - minY + 1;

    final cell = (size.width / (w + 0.5)).clamp(0.0, size.height / (h + 0.5));
    final offsetX = (size.width - w * cell) / 2;
    final offsetY = (size.height - h * cell) / 2;

    var color = theme.colorOf(t);
    if (dimmed) color = color.withValues(alpha: 0.3);

    for (final c in cells) {
      final rect = Rect.fromLTWH(
        offsetX + (c.x - minX) * cell + 1,
        offsetY + (c.y - minY) * cell + 1,
        cell - 2,
        cell - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.12)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PiecePreviewPainter old) =>
      old.type != type || old.dimmed != dimmed || old.theme.id != theme.id;
}
