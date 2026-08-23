/// Temas visuales de Blockfall.
///
/// Cada tema define un color por pieza más los colores del marco. Los colores
/// de pieza siguen la convención clásica (I cian, O amarillo, T morado...)
/// porque los jugadores la reconocen al instante.
library;

import 'package:flutter/material.dart';

import '../game/tetromino.dart';

class BlockTheme {
  final String id;

  /// Nombre en español, solo como respaldo. El texto que ve el jugador sale
  /// de las traducciones: ver `nombreTema` en settings_screen.dart.
  final String name;
  final Color background;
  final Color boardBackground;
  final Color gridLine;
  final Color text;
  final Color accent;
  final Map<PieceType, Color> pieces;

  const BlockTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.boardBackground,
    required this.gridLine,
    required this.text,
    required this.accent,
    required this.pieces,
  });

  Color colorOf(PieceType type) => pieces[type] ?? Colors.grey;

  /// Color de la basura enviada por el rival: gris, para distinguirla.
  Color get garbage => const Color(0xFF5A5A66);
}

const _classicPieces = {
  PieceType.i: Color(0xFF31C7EF),
  PieceType.o: Color(0xFFF7D308),
  PieceType.t: Color(0xFFAD4D9C),
  PieceType.s: Color(0xFF42B642),
  PieceType.z: Color(0xFFEF2029),
  PieceType.j: Color(0xFF5A65AD),
  PieceType.l: Color(0xFFEF7921),
};

const darkTheme = BlockTheme(
  id: 'dark',
  name: 'Oscuro',
  background: Color(0xFF0E0E14),
  boardBackground: Color(0xFF16161F),
  gridLine: Color(0xFF23232F),
  text: Color(0xFFECECF2),
  accent: Color(0xFF31C7EF),
  pieces: _classicPieces,
);

const lightTheme = BlockTheme(
  id: 'light',
  name: 'Claro',
  background: Color(0xFFF2F3F7),
  boardBackground: Color(0xFFFFFFFF),
  gridLine: Color(0xFFE2E4EC),
  text: Color(0xFF1A1A22),
  accent: Color(0xFF2A78D0),
  pieces: _classicPieces,
);

const neonTheme = BlockTheme(
  id: 'neon',
  name: 'Neón',
  background: Color(0xFF07000F),
  boardBackground: Color(0xFF11021F),
  gridLine: Color(0xFF2A0A45),
  text: Color(0xFFF0E6FF),
  accent: Color(0xFFFF2FD0),
  pieces: {
    PieceType.i: Color(0xFF00F0FF),
    PieceType.o: Color(0xFFFFE600),
    PieceType.t: Color(0xFFFF2FD0),
    PieceType.s: Color(0xFF39FF14),
    PieceType.z: Color(0xFFFF3B3B),
    PieceType.j: Color(0xFF4D6BFF),
    PieceType.l: Color(0xFFFF9A00),
  },
);

const retroTheme = BlockTheme(
  id: 'retro',
  name: 'Retro',
  background: Color(0xFF1B2416),
  boardBackground: Color(0xFF2A331F),
  gridLine: Color(0xFF3A462C),
  text: Color(0xFFC8D69A),
  accent: Color(0xFF9BBC0F),
  pieces: {
    PieceType.i: Color(0xFF9BBC0F),
    PieceType.o: Color(0xFF8BAC0F),
    PieceType.t: Color(0xFF7B9C0E),
    PieceType.s: Color(0xFF6B8C0D),
    PieceType.z: Color(0xFF5B7C0C),
    PieceType.j: Color(0xFF4B6C0B),
    PieceType.l: Color(0xFFAECD1F),
  },
);

const allThemes = [darkTheme, lightTheme, neonTheme, retroTheme];

BlockTheme themeById(String id) =>
    allThemes.firstWhere((t) => t.id == id, orElse: () => darkTheme);
