import 'package:blockfall/data/remote_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comprueba el filtro que descarta puntuaciones imposibles antes de subirlas
/// al ranking global.
///
/// Estas mismas reglas están repetidas en `firestore.rules`, porque el cliente
/// se puede modificar y el servidor no. Si se cambia una, hay que cambiar la
/// otra.
void main() {
  String? reject({
    int score = 1000,
    int lines = 10,
    int level = 2,
    int durationMs = 60000,
  }) =>
      ScoreValidator.reject(
        score: score,
        lines: lines,
        level: level,
        durationMs: durationMs,
      );

  group('Puntuaciones válidas', () {
    test('una partida normal pasa', () {
      expect(reject(), isNull);
    });

    test('una partida larga y buena pasa', () {
      expect(
        reject(score: 150000, lines: 200, level: 21, durationMs: 1800000),
        isNull,
      );
    });

    test('un Sprint rápido pero humano pasa', () {
      // 40 líneas en 45 segundos: récord mundial aproximado, pero posible.
      expect(
        reject(score: 5000, lines: 40, level: 5, durationMs: 45000),
        isNull,
      );
    });
  });

  group('Puntuaciones rechazadas', () {
    test('puntuación negativa', () {
      expect(reject(score: -1), isNotNull);
    });

    test('partida sin puntuación', () {
      expect(reject(score: 0), isNotNull);
    });

    test('muchos puntos sin haber hecho líneas', () {
      expect(reject(score: 999999, lines: 0, level: 1), isNotNull);
    });

    test('más puntos de los posibles para esas líneas', () {
      expect(reject(score: 10000000, lines: 10, level: 2), isNotNull);
    });

    test('nivel imposible para las líneas hechas', () {
      // Nivel 50 exigiría casi 500 líneas.
      expect(reject(score: 5000, lines: 10, level: 50), isNotNull);
    });

    test('demasiadas líneas en muy poco tiempo', () {
      // 500 líneas en 3 segundos.
      expect(
        reject(score: 100000, lines: 500, level: 51, durationMs: 3000),
        isNotNull,
      );
    });

    test('duración absurda', () {
      expect(
        reject(score: 1000, lines: 10, level: 2, durationMs: 999999999),
        isNotNull,
      );
    });
  });

  group('Los límites son coherentes', () {
    test('el mínimo de tiempo escala con las líneas', () {
      // Justo en el límite: 100 líneas necesitan 25 s.
      expect(
        reject(score: 20000, lines: 100, level: 11, durationMs: 25000),
        isNull,
      );
      // Un milisegundo menos y ya no cuela.
      expect(
        reject(score: 20000, lines: 100, level: 11, durationMs: 24999),
        isNotNull,
      );
    });

    test('el nivel máximo es una línea más de lo que dan las líneas', () {
      expect(reject(lines: 100, level: 11, score: 20000), isNull);
      expect(reject(lines: 100, level: 12, score: 20000), isNotNull);
    });
  });
}
