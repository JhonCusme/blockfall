/// Generador de piezas "7-bag".
///
/// Se baraja el conjunto de las siete piezas y se reparten todas antes de
/// volver a barajar. Garantiza que nunca pasas más de 12 piezas sin ver una I,
/// que es justo lo que hace injusto un generador puramente aleatorio.
///
/// Acepta una semilla: con la misma semilla sale la misma secuencia, lo que
/// hace los tests deterministas y permite que en multijugador ambos jugadores
/// reciban exactamente las mismas piezas.
library;

import 'dart:math';

import 'tetromino.dart';

class PieceBag {
  final Random _random;
  final List<PieceType> _queue = [];

  PieceBag({int? seed}) : _random = Random(seed);

  /// Rellena la cola hasta tener al menos [n] piezas visibles por delante.
  void _ensure(int n) {
    while (_queue.length < n) {
      final bag = List<PieceType>.from(PieceType.values)..shuffle(_random);
      _queue.addAll(bag);
    }
  }

  /// Saca la siguiente pieza.
  PieceType next() {
    _ensure(1);
    return _queue.removeAt(0);
  }

  /// Las próximas [n] piezas sin sacarlas, para el panel "Next".
  List<PieceType> peek(int n) {
    _ensure(n);
    return _queue.take(n).toList();
  }
}
