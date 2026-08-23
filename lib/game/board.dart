/// El tablero: la grilla de celdas fijadas, las colisiones y el borrado de
/// líneas.
library;

import 'tetromino.dart';

/// Resultado de fijar una pieza y limpiar líneas.
class ClearResult {
  /// Cuántas líneas se completaron (0 a 4).
  final int linesCleared;

  /// Índices de las filas borradas, de arriba abajo. La UI los necesita para
  /// animar el destello antes de compactar.
  final List<int> clearedRows;

  const ClearResult(this.linesCleared, this.clearedRows);
}

class Board {
  /// Ancho estándar.
  static const int width = 10;

  /// Alto visible.
  static const int visibleHeight = 20;

  /// Filas ocultas por encima del área visible donde aparecen las piezas.
  /// Sin ellas, una pieza que aparece sobre una pila alta no tendría sitio.
  static const int hiddenRows = 2;

  /// Alto total de la grilla interna.
  static const int height = visibleHeight + hiddenRows;

  /// `null` = celda vacía. Si no, el tipo de pieza que la ocupa, para pintarla
  /// con su color.
  final List<List<PieceType?>> grid;

  Board()
      : grid =
            List.generate(height, (_) => List<PieceType?>.filled(width, null));

  Board._(this.grid);

  /// Copia independiente, útil para el rival en multijugador y para tests.
  Board clone() =>
      Board._(grid.map((row) => List<PieceType?>.from(row)).toList());

  bool _inside(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  PieceType? at(int x, int y) => _inside(x, y) ? grid[y][x] : null;

  /// ¿Cabe la pieza aquí? Falso si se sale por los lados, por abajo, o pisa una
  /// celda ya ocupada.
  ///
  /// Salirse por ARRIBA sí se permite: las piezas nacen parcialmente en las
  /// filas ocultas y deben poder moverse ahí.
  bool fits(ActivePiece piece) {
    for (final c in piece.boardCells) {
      if (c.x < 0 || c.x >= width) return false;
      if (c.y >= height) return false;
      if (c.y < 0) continue;
      if (grid[c.y][c.x] != null) return false;
    }
    return true;
  }

  /// Escribe la pieza en la grilla de forma permanente.
  void lock(ActivePiece piece) {
    for (final c in piece.boardCells) {
      if (_inside(c.x, c.y)) grid[c.y][c.x] = piece.type;
    }
  }

  /// Borra las filas completas y deja caer todo lo que quedaba encima.
  ClearResult clearLines() {
    final cleared = <int>[];
    for (var y = 0; y < height; y++) {
      if (grid[y].every((cell) => cell != null)) cleared.add(y);
    }
    if (cleared.isEmpty) return const ClearResult(0, []);

    // Reconstruir conservando solo las filas que sobreviven, y rellenar por
    // arriba con filas vacías. Más simple y menos propenso a errores que
    // desplazar índices en el sitio.
    final survivors = <List<PieceType?>>[];
    for (var y = 0; y < height; y++) {
      if (!cleared.contains(y)) survivors.add(grid[y]);
    }
    final empties = List.generate(
      cleared.length,
      (_) => List<PieceType?>.filled(width, null),
    );
    final rebuilt = [...empties, ...survivors];
    for (var y = 0; y < height; y++) {
      grid[y] = rebuilt[y];
    }
    return ClearResult(cleared.length, cleared);
  }

  /// Altura de la pila, en filas ocupadas desde abajo. La usa la IA del bot y
  /// el indicador de peligro.
  int get stackHeight {
    for (var y = 0; y < height; y++) {
      if (grid[y].any((cell) => cell != null)) return height - y;
    }
    return 0;
  }

  /// Borra los bloques de las [count] filas superiores.
  ///
  /// Es lo que hace "revivir": el game over ocurre porque la pila llegó
  /// arriba, así que despejar la zona alta devuelve espacio para seguir sin
  /// regalar la partida entera.
  void clearTopRows(int count) {
    for (var y = 0; y < count && y < height; y++) {
      for (var x = 0; x < width; x++) {
        grid[y][x] = null;
      }
    }
  }

  /// Añade [count] filas de basura por abajo con un hueco en [holeColumn].
  /// Es el mecanismo de ataque del multijugador.
  void addGarbage(int count, int holeColumn) {
    for (var i = 0; i < count; i++) {
      grid.removeAt(0);
      final row = List<PieceType?>.filled(width, PieceType.o);
      row[holeColumn] = null;
      grid.add(row);
    }
  }
}
