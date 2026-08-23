/// Genera el gráfico destacado de la ficha de Google Play.
///
/// Play lo exige en **1024 x 500 px**, JPG o PNG de 24 bits sin transparencia.
/// Es la imagen ancha que aparece arriba en la ficha y en las colecciones
/// destacadas.
///
/// Dos reglas que se saltan muchos y hacen que la imagen se vea mal:
///
///  1. Play **recorta los bordes** en algunos sitios. Nada importante puede
///     tocar el borde: hay que dejar margen de seguridad.
///  2. En muchas superficies **se superpone el nombre de la app**, así que el
///     gráfico no debe repetirlo en grande ni llenar el centro de texto.
///
/// Ejecutar desde la raíz del proyecto:
///   dart run tool/generate_feature_graphic.dart
library;

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';

const int anchoTotal = 1024;
const int altoTotal = 500;

final fondo = ColorRgb8(14, 14, 20);
final rejillaColor = ColorRgba8(255, 255, 255, 12);

final cian = ColorRgb8(49, 199, 239);
final amarillo = ColorRgb8(247, 211, 8);
final magenta = ColorRgb8(173, 77, 156);
final verde = ColorRgb8(66, 182, 66);
final naranja = ColorRgb8(239, 121, 33);
final azul = ColorRgb8(90, 101, 173);
final rojo = ColorRgb8(239, 32, 41);

/// Bloque con el mismo bisel que las piezas del juego.
void bloque(Image img, int x, int y, int lado, Color color) {
  final radio = (lado * 0.14).round();
  final m = max(1, (lado * 0.05).round());
  final rect = [x + m, y + m, x + lado - m, y + lado - m];

  fillRect(img,
      x1: rect[0], y1: rect[1], x2: rect[2], y2: rect[3],
      radius: radio, color: color);
  fillRect(img,
      x1: rect[0] + m,
      y1: rect[1] + m,
      x2: rect[2] - m,
      y2: rect[1] + ((rect[3] - rect[1]) * 0.32).round(),
      radius: (radio * 0.7).round(),
      color: ColorRgba8(255, 255, 255, 52));
  drawRect(img,
      x1: rect[0], y1: rect[1], x2: rect[2], y2: rect[3],
      radius: radio,
      color: ColorRgba8(0, 0, 0, 110),
      thickness: max(1, lado ~/ 30));
}

void main() {
  final img = Image(width: anchoTotal, height: altoTotal, numChannels: 3);
  fill(img, color: fondo);

  // Rejilla de fondo, como el tablero.
  const paso = 50;
  for (var x = paso; x < anchoTotal; x += paso) {
    drawLine(img, x1: x, y1: 0, x2: x, y2: altoTotal, color: rejillaColor);
  }
  for (var y = paso; y < altoTotal; y += paso) {
    drawLine(img, x1: 0, y1: y, x2: anchoTotal, y2: y, color: rejillaColor);
  }

  // Composición: una pila asentada abajo, como el fondo de un tablero real, y
  // piezas cayendo encima. Se lee como el juego de un vistazo, en vez de como
  // cuadrados sueltos.
  //
  // La mitad superior derecha se deja despejada: es donde Play superpone el
  // icono y el nombre de la app en varias de sus superficies.
  const lado = 56;
  const filas = 8;
  const columnas = anchoTotal ~/ lado + 1;
  // La última fila tiene que apoyarse exactamente en el borde inferior.
  const offsetY = altoTotal - filas * lado;

  void poner(int col, int fila, Color color) {
    bloque(img, col * lado, offsetY + fila * lado, lado, color);
  }

  // Pila del fondo: dos filas casi completas con huecos, para que parezca una
  // partida avanzada y no una cuadrícula perfecta.
  const huecosAbajo = {3, 11};
  const huecosMedio = {2, 3, 6, 10, 11, 14, 15, 16};
  final coloresPila = [
    magenta, verde, amarillo, cian, naranja, azul, rojo, verde,
    amarillo, magenta, cian, naranja, rojo, azul, verde, amarillo, cian,
  ];

  for (var col = 0; col < columnas; col++) {
    if (!huecosAbajo.contains(col)) {
      poner(col, 7, coloresPila[col % coloresPila.length]);
    }
    if (!huecosMedio.contains(col)) {
      poner(col, 6, coloresPila[(col + 3) % coloresPila.length]);
    }
  }

  // Piezas cayendo, todas en la mitad izquierda y a distintas alturas.
  // Son tetrominós de verdad: I, T, S y O.
  const iPieza = [[0, 1], [1, 1], [2, 1], [3, 1]];
  const tPieza = [[1, 0], [0, 1], [1, 1], [2, 1]];
  const sPieza = [[1, 0], [2, 0], [0, 1], [1, 1]];
  const oPieza = [[0, 0], [1, 0], [0, 1], [1, 1]];

  void ponerPieza(List<List<int>> celdas, int col, int fila, Color color) {
    for (final c in celdas) {
      poner(col + c[0], fila + c[1], color);
    }
  }

  ponerPieza(iPieza, 1, 0, cian);
  ponerPieza(tPieza, 7, 1, magenta);
  ponerPieza(sPieza, 2, 3, verde);
  ponerPieza(oPieza, 11, 3, amarillo);

  final dir = Directory('store');
  dir.createSync(recursive: true);
  final bytes = encodePng(img);
  File('${dir.path}/feature_graphic.png').writeAsBytesSync(bytes);

  stdout.writeln('feature_graphic.png  ${anchoTotal}x$altoTotal  '
      '${(bytes.length / 1024).toStringAsFixed(0)} KB  ->  store/');
}
