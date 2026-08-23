/// Puntuación, niveles, combos y detección de T-Spin.
library;

import 'board.dart';
import 'tetromino.dart';

/// Qué tipo de jugada acaba de hacer el jugador. Determina puntos y ataque.
enum ClearKind {
  none,
  single,
  double_,
  triple,
  tetris,
  tSpinMini,
  tSpinSingle,
  tSpinDouble,
  tSpinTriple,
}

extension ClearKindInfo on ClearKind {
  /// ¿Cuenta para la racha "back to back"? Solo las jugadas difíciles.
  bool get isDifficult =>
      this == ClearKind.tetris ||
      this == ClearKind.tSpinMini ||
      this == ClearKind.tSpinSingle ||
      this == ClearKind.tSpinDouble ||
      this == ClearKind.tSpinTriple;

  /// Líneas de basura que envía al rival en multijugador.
  int get garbageSent => switch (this) {
        ClearKind.none => 0,
        ClearKind.single => 0,
        ClearKind.double_ => 1,
        ClearKind.triple => 2,
        ClearKind.tetris => 4,
        ClearKind.tSpinMini => 0,
        ClearKind.tSpinSingle => 2,
        ClearKind.tSpinDouble => 4,
        ClearKind.tSpinTriple => 6,
      };

  int get baseScore => switch (this) {
        ClearKind.none => 0,
        ClearKind.single => 100,
        ClearKind.double_ => 300,
        ClearKind.triple => 500,
        ClearKind.tetris => 800,
        ClearKind.tSpinMini => 100,
        ClearKind.tSpinSingle => 800,
        ClearKind.tSpinDouble => 1200,
        ClearKind.tSpinTriple => 1600,
      };
}

/// Lleva la cuenta de la partida.
class Scoring {
  int score = 0;
  int lines = 0;
  int level = 1;

  /// Jugadas difíciles encadenadas. -1 = no hay racha activa.
  int backToBack = -1;

  /// Líneas hechas en turnos consecutivos. -1 = sin combo.
  int combo = -1;

  /// Nivel de arranque; en modo Maratón es 1, pero se puede empezar más alto.
  final int startLevel;

  Scoring({this.startLevel = 1}) : level = startLevel;

  /// Registra una jugada y devuelve los puntos ganados.
  int register(ClearKind kind) {
    if (kind == ClearKind.none) {
      combo = -1;
      return 0;
    }

    var points = kind.baseScore * level;

    // Back-to-back: dos jugadas difíciles seguidas valen un 50% más.
    if (kind.isDifficult) {
      backToBack++;
      if (backToBack > 0) points = (points * 1.5).round();
    } else {
      backToBack = -1;
    }

    combo++;
    if (combo > 0) points += 50 * combo * level;

    final cleared = _linesOf(kind);
    lines += cleared;
    score += points;

    // Un nivel cada diez líneas, contando desde el nivel inicial.
    level = startLevel + (lines ~/ 10);

    return points;
  }

  void addSoftDrop(int cells) => score += cells;
  void addHardDrop(int cells) => score += cells * 2;

  static int _linesOf(ClearKind kind) => switch (kind) {
        ClearKind.single || ClearKind.tSpinSingle => 1,
        ClearKind.double_ || ClearKind.tSpinDouble => 2,
        ClearKind.triple || ClearKind.tSpinTriple => 3,
        ClearKind.tetris => 4,
        _ => 0,
      };

  /// Basura total a enviar, incluyendo el bonus por combo.
  int garbageFor(ClearKind kind) {
    if (kind == ClearKind.none) return 0;
    var g = kind.garbageSent;
    if (backToBack > 0 && kind.isDifficult) g += 1;
    if (combo >= 1) g += (combo / 2).floor();
    return g;
  }
}

/// Milisegundos que tarda la pieza en bajar una celda, según el nivel.
///
/// Sigue la curva de la Tetris Guideline: suave al principio, brutal a partir
/// del nivel 13.
int gravityMs(int level) {
  final l = level.clamp(1, 20);
  final seconds = _pow(0.8 - ((l - 1) * 0.007), l - 1);
  return (seconds * 1000).round().clamp(16, 1000);
}

double _pow(double base, int exp) {
  var r = 1.0;
  for (var i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}

/// Detecta si la última colocación fue un T-Spin.
///
/// Regla estándar de las "tres esquinas": la pieza debe ser una T, el último
/// movimiento debe haber sido una rotación, y al menos tres de las cuatro
/// esquinas de su caja de 3x3 deben estar ocupadas (o fuera del tablero).
///
/// Si las dos esquinas del "frente" de la T están ocupadas es un T-Spin
/// completo; si solo una, es un mini.
ClearKind detectTSpin({
  required Board board,
  required ActivePiece piece,
  required bool lastMoveWasRotation,
  required bool usedKick,
  required int linesCleared,
}) {
  if (piece.type != PieceType.t || !lastMoveWasRotation) {
    return switch (linesCleared) {
      1 => ClearKind.single,
      2 => ClearKind.double_,
      3 => ClearKind.triple,
      4 => ClearKind.tetris,
      _ => ClearKind.none,
    };
  }

  bool occupied(int x, int y) {
    if (x < 0 || x >= Board.width || y >= Board.height) return true;
    if (y < 0) return false;
    return board.at(x, y) != null;
  }

  // Esquinas de la caja 3x3, en orden: superior-izq, superior-der,
  // inferior-izq, inferior-der.
  final corners = [
    occupied(piece.x, piece.y),
    occupied(piece.x + 2, piece.y),
    occupied(piece.x, piece.y + 2),
    occupied(piece.x + 2, piece.y + 2),
  ];
  final filled = corners.where((c) => c).length;
  if (filled < 3) {
    return switch (linesCleared) {
      1 => ClearKind.single,
      2 => ClearKind.double_,
      3 => ClearKind.triple,
      _ => ClearKind.none,
    };
  }

  // Las dos esquinas hacia las que "apunta" la T según su rotación.
  final front = switch (piece.rotation) {
    Rotation.spawn => [corners[0], corners[1]],
    Rotation.right => [corners[1], corners[3]],
    Rotation.flip => [corners[2], corners[3]],
    Rotation.left => [corners[0], corners[2]],
  };
  final isFull = front.every((c) => c);

  // Un giro que necesitó el último kick cuenta como T-Spin completo aunque el
  // frente no esté lleno: es la excepción clásica del "T-Spin Triple".
  if (!isFull && !usedKick) {
    return linesCleared == 0 ? ClearKind.none : ClearKind.tSpinMini;
  }

  return switch (linesCleared) {
    0 => ClearKind.none,
    1 => ClearKind.tSpinSingle,
    2 => ClearKind.tSpinDouble,
    _ => ClearKind.tSpinTriple,
  };
}
