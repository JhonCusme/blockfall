/// Las siete piezas y sus rotaciones.
///
/// No importa nada de Flutter a propósito: todo este directorio es lógica pura
/// y se puede testear sin emulador.
///
/// Convención de coordenadas en TODO el motor: `x` crece hacia la derecha,
/// `y` crece hacia ABAJO. Es la convención de pantalla, no la matemática.
library;

/// Una celda dentro de la caja de rotación de una pieza.
class Cell {
  final int x;
  final int y;
  const Cell(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

/// Los siete tipos de pieza. El orden importa: define el orden de la bolsa.
enum PieceType { i, o, t, s, z, j, l }

/// Estado de rotación. `spawn` es la orientación inicial; `right` es un giro
/// horario desde ahí, y así sucesivamente.
enum Rotation {
  spawn,
  right,
  flip,
  left;

  Rotation get cw => Rotation.values[(index + 1) % 4];
  Rotation get ccw => Rotation.values[(index + 3) % 4];
}

/// Definición estática de una pieza: sus celdas en las cuatro rotaciones.
class Tetromino {
  final PieceType type;

  /// Tamaño de la caja de rotación: 4 para la I, 2 para la O, 3 para el resto.
  final int boxSize;

  /// Celdas por rotación, indexadas por `Rotation.index`.
  final List<List<Cell>> _states;

  const Tetromino._(this.type, this.boxSize, this._states);

  List<Cell> cells(Rotation r) => _states[r.index];

  /// Construye las cuatro rotaciones girando la forma inicial dentro de su caja.
  ///
  /// Girar horario en una caja de lado `n` con la Y hacia abajo es:
  /// `(x, y) -> (n - 1 - y, x)`.
  static Tetromino _build(PieceType type, int boxSize, List<Cell> spawn) {
    final states = <List<Cell>>[];
    var current = spawn;
    for (var i = 0; i < 4; i++) {
      states.add(current);
      current = current.map((c) => Cell(boxSize - 1 - c.y, c.x)).toList();
    }
    return Tetromino._(type, boxSize, states);
  }

  /// La O no gira: sus cuatro estados son idénticos. Si la rotáramos dentro de
  /// una caja de 2x2 la pieza "bailaría" en pantalla.
  static Tetromino _buildFixed(PieceType type, int boxSize, List<Cell> shape) =>
      Tetromino._(type, boxSize, [shape, shape, shape, shape]);

  static final Map<PieceType, Tetromino> _all = {
    PieceType.i: _build(PieceType.i, 4, const [
      Cell(0, 1),
      Cell(1, 1),
      Cell(2, 1),
      Cell(3, 1),
    ]),
    PieceType.o: _buildFixed(PieceType.o, 2, const [
      Cell(0, 0),
      Cell(1, 0),
      Cell(0, 1),
      Cell(1, 1),
    ]),
    PieceType.t: _build(PieceType.t, 3, const [
      Cell(1, 0),
      Cell(0, 1),
      Cell(1, 1),
      Cell(2, 1),
    ]),
    PieceType.s: _build(PieceType.s, 3, const [
      Cell(1, 0),
      Cell(2, 0),
      Cell(0, 1),
      Cell(1, 1),
    ]),
    PieceType.z: _build(PieceType.z, 3, const [
      Cell(0, 0),
      Cell(1, 0),
      Cell(1, 1),
      Cell(2, 1),
    ]),
    PieceType.j: _build(PieceType.j, 3, const [
      Cell(0, 0),
      Cell(0, 1),
      Cell(1, 1),
      Cell(2, 1),
    ]),
    PieceType.l: _build(PieceType.l, 3, const [
      Cell(2, 0),
      Cell(0, 1),
      Cell(1, 1),
      Cell(2, 1),
    ]),
  };

  static Tetromino of(PieceType type) => _all[type]!;
}

/// Una pieza concreta en juego: qué es, dónde está y cómo está girada.
///
/// `x`/`y` son la esquina superior izquierda de su caja de rotación, en
/// coordenadas del tablero.
class ActivePiece {
  final PieceType type;
  final Rotation rotation;
  final int x;
  final int y;

  const ActivePiece({
    required this.type,
    required this.rotation,
    required this.x,
    required this.y,
  });

  Tetromino get shape => Tetromino.of(type);

  /// Celdas que ocupa en el tablero.
  Iterable<Cell> get boardCells =>
      shape.cells(rotation).map((c) => Cell(x + c.x, y + c.y));

  ActivePiece moved(int dx, int dy) => ActivePiece(
        type: type,
        rotation: rotation,
        x: x + dx,
        y: y + dy,
      );

  ActivePiece rotated(Rotation r) => ActivePiece(
        type: type,
        rotation: r,
        x: x,
        y: y,
      );
}
