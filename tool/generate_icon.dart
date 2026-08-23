/// Genera el icono de Blockfall.
///
/// Se dibuja por código en lugar de usar una imagen suelta: así el icono queda
/// versionado, se puede retocar cambiando cuatro números, y usa exactamente
/// los mismos colores y el mismo bisel que las piezas del juego.
///
/// Ejecutar desde la raíz del proyecto:
///   dart run tool/generate_icon.dart
///   dart run flutter_launcher_icons
///
/// Produce dos archivos:
///   assets/icon/icon.png             icono completo (iOS y Android antiguo)
///   assets/icon/icon_foreground.png  capa frontal del icono adaptativo
///
/// En Android moderno el icono es "adaptativo": el sistema recorta la capa
/// frontal con la forma que quiera el lanzador (círculo, cuadrado redondeado,
/// gota...). Solo el 66% central está garantizado, así que el dibujo se hace
/// pequeño y centrado en la capa frontal.
library;

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';

const int size = 1024;

// Paleta: la misma del tema oscuro del juego.
final fondo = ColorRgb8(14, 14, 20);
final cian = ColorRgb8(49, 199, 239);
final amarillo = ColorRgb8(247, 211, 8);
final magenta = ColorRgb8(173, 77, 156);
final verde = ColorRgb8(66, 182, 66);

/// Dibuja un bloque con el mismo aspecto que en el tablero: cuerpo de color,
/// brillo arriba y contorno oscuro para separarlo de sus vecinos.
void bloque(Image img, int x, int y, int lado, Color color) {
  final radio = (lado * 0.14).round();
  final margen = (lado * 0.04).round();
  final x1 = x + margen;
  final y1 = y + margen;
  final x2 = x + lado - margen;
  final y2 = y + lado - margen;

  fillRect(img, x1: x1, y1: y1, x2: x2, y2: y2, radius: radio, color: color);

  // Brillo en el tercio superior.
  fillRect(
    img,
    x1: x1 + margen,
    y1: y1 + margen,
    x2: x2 - margen,
    y2: y1 + ((y2 - y1) * 0.32).round(),
    radius: (radio * 0.7).round(),
    color: ColorRgba8(255, 255, 255, 56),
  );

  drawRect(
    img,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    radius: radio,
    color: ColorRgba8(0, 0, 0, 110),
    thickness: max(2, lado ~/ 34),
  );
}

/// La composición: tres bloques asentados formando una L y uno cayendo encima,
/// desplazado. La idea es que se lea "bloques que caen" —el nombre del juego—
/// incluso a 48 píxeles.
///
/// [escala] permite dibujar más pequeño para la capa adaptativa.
void composicion(Image img, double escala) {
  final lado = (size * 0.30 * escala).round();

  // Hueco entre el bloque que cae y la fila. Suficiente para que se lea el
  // movimiento, pero corto: una separación de una celda entera dispersa el
  // dibujo y a 48 píxeles se ve como puntos sueltos en vez de una figura.
  final hueco = (lado * 0.34).round();

  final ancho = lado * 3;
  final alto = lado * 2 + hueco;
  final ox = (size - ancho) ~/ 2;
  final oy = (size - alto) ~/ 2;

  int cx(int col) => ox + lado * col;
  final yFila = oy + lado + hueco;

  // Fila de abajo: tres bloques ya asentados.
  bloque(img, cx(0), yFila, lado, magenta);
  bloque(img, cx(1), yFila, lado, verde);
  bloque(img, cx(2), yFila, lado, amarillo);

  // El bloque que cae, justo encima de la columna central.
  bloque(img, cx(1), oy, lado, cian);
}

void main() {
  final dir = Directory('assets/icon');
  dir.createSync(recursive: true);

  // --- Icono completo, con fondo ---
  final completo = Image(width: size, height: size, numChannels: 4);
  fill(completo, color: fondo);
  _rejilla(completo);
  composicion(completo, 1.0);
  File('${dir.path}/icon.png').writeAsBytesSync(encodePng(completo));

  // --- Capa frontal del icono adaptativo, transparente y más pequeña ---
  //
  // Se dibuja algo más pequeño que el icono completo para sobrevivir al
  // recorte circular, pero apurando: si se queda corto, el dibujo aparece
  // diminuto en medio de un círculo vacío.
  final frontal = Image(width: size, height: size, numChannels: 4);
  fill(frontal, color: ColorRgba8(0, 0, 0, 0));
  composicion(frontal, 0.98);
  File('${dir.path}/icon_foreground.png').writeAsBytesSync(encodePng(frontal));

  stdout.writeln('icon.png y icon_foreground.png generados en assets/icon/');
}

/// Rejilla muy tenue de fondo, como la del tablero.
void _rejilla(Image img) {
  const celdas = 8;
  const paso = size ~/ celdas;
  final color = ColorRgba8(255, 255, 255, 10);
  for (var i = 1; i < celdas; i++) {
    drawLine(img, x1: i * paso, y1: 0, x2: i * paso, y2: size, color: color);
    drawLine(img, x1: 0, y1: i * paso, x2: size, y2: i * paso, color: color);
  }
}
