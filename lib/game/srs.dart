/// Super Rotation System: las tablas de "wall kick".
///
/// Cuando una pieza no cabe al girar, no se rechaza el giro directamente: se
/// prueban cinco desplazamientos en orden y se acepta el primero que quepa.
/// Esto es lo que permite las maniobras finas contra la pared y los T-Spin, y
/// es la diferencia entre un Tetris que se siente moderno y uno que no.
///
/// Las tablas oficiales están escritas con la Y hacia ARRIBA. Nuestro motor usa
/// la Y hacia abajo, así que aquí se guardan tal cual y se invierte el signo al
/// aplicarlas — ver [kicks].
library;

import 'tetromino.dart';

/// Un desplazamiento candidato, en la convención oficial (Y hacia arriba).
class Kick {
  final int x;
  final int y;
  const Kick(this.x, this.y);
}

/// Clave de transición entre dos rotaciones.
int _key(Rotation from, Rotation to) => from.index * 4 + to.index;

/// Tabla para J, L, S, T, Z.
final Map<int, List<Kick>> _jlstz = {
  _key(Rotation.spawn, Rotation.right): const [
    Kick(0, 0),
    Kick(-1, 0),
    Kick(-1, 1),
    Kick(0, -2),
    Kick(-1, -2),
  ],
  _key(Rotation.right, Rotation.spawn): const [
    Kick(0, 0),
    Kick(1, 0),
    Kick(1, -1),
    Kick(0, 2),
    Kick(1, 2),
  ],
  _key(Rotation.right, Rotation.flip): const [
    Kick(0, 0),
    Kick(1, 0),
    Kick(1, -1),
    Kick(0, 2),
    Kick(1, 2),
  ],
  _key(Rotation.flip, Rotation.right): const [
    Kick(0, 0),
    Kick(-1, 0),
    Kick(-1, 1),
    Kick(0, -2),
    Kick(-1, -2),
  ],
  _key(Rotation.flip, Rotation.left): const [
    Kick(0, 0),
    Kick(1, 0),
    Kick(1, 1),
    Kick(0, -2),
    Kick(1, -2),
  ],
  _key(Rotation.left, Rotation.flip): const [
    Kick(0, 0),
    Kick(-1, 0),
    Kick(-1, -1),
    Kick(0, 2),
    Kick(-1, 2),
  ],
  _key(Rotation.left, Rotation.spawn): const [
    Kick(0, 0),
    Kick(-1, 0),
    Kick(-1, -1),
    Kick(0, 2),
    Kick(-1, 2),
  ],
  _key(Rotation.spawn, Rotation.left): const [
    Kick(0, 0),
    Kick(1, 0),
    Kick(1, 1),
    Kick(0, -2),
    Kick(1, -2),
  ],
};

/// Tabla para la I, que tiene la suya propia por ocupar una caja de 4x4.
final Map<int, List<Kick>> _iPiece = {
  _key(Rotation.spawn, Rotation.right): const [
    Kick(0, 0),
    Kick(-2, 0),
    Kick(1, 0),
    Kick(-2, -1),
    Kick(1, 2),
  ],
  _key(Rotation.right, Rotation.spawn): const [
    Kick(0, 0),
    Kick(2, 0),
    Kick(-1, 0),
    Kick(2, 1),
    Kick(-1, -2),
  ],
  _key(Rotation.right, Rotation.flip): const [
    Kick(0, 0),
    Kick(-1, 0),
    Kick(2, 0),
    Kick(-1, 2),
    Kick(2, -1),
  ],
  _key(Rotation.flip, Rotation.right): const [
    Kick(0, 0),
    Kick(1, 0),
    Kick(-2, 0),
    Kick(1, -2),
    Kick(-2, 1),
  ],
  _key(Rotation.flip, Rotation.left): const [
    Kick(0, 0),
    Kick(2, 0),
    Kick(-1, 0),
    Kick(2, 1),
    Kick(-1, -2),
  ],
  _key(Rotation.left, Rotation.flip): const [
    Kick(0, 0),
    Kick(-2, 0),
    Kick(1, 0),
    Kick(-2, -1),
    Kick(1, 2),
  ],
  _key(Rotation.left, Rotation.spawn): const [
    Kick(0, 0),
    Kick(1, 0),
    Kick(-2, 0),
    Kick(1, -2),
    Kick(-2, 1),
  ],
  _key(Rotation.spawn, Rotation.left): const [
    Kick(0, 0),
    Kick(-1, 0),
    Kick(2, 0),
    Kick(-1, 2),
    Kick(2, -1),
  ],
};

/// Desplazamientos a probar para pasar de [from] a [to], ya convertidos a la
/// convención del motor (Y hacia abajo).
///
/// La O nunca gira de verdad, así que solo se le ofrece el desplazamiento nulo.
List<Kick> kicks(PieceType type, Rotation from, Rotation to) {
  if (type == PieceType.o) return const [Kick(0, 0)];
  final table = type == PieceType.i ? _iPiece : _jlstz;
  final raw = table[_key(from, to)] ?? const [Kick(0, 0)];
  return raw.map((k) => Kick(k.x, -k.y)).toList();
}
