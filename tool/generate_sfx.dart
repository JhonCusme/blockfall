/// Genera los efectos de sonido de Blockfall como archivos WAV.
///
/// Se sintetizan por código en vez de usar samples descargados: así son
/// originales, sin problemas de licencia, y pesan unos pocos KB cada uno.
///
/// Ejecutar desde la raíz del proyecto:
///   dart run tool/generate_sfx.dart
///
/// Solo hace falta volver a ejecutarlo si se cambian los sonidos.
library;

import 'dart:io';
import 'dart:math';

import 'wav.dart';

class Tone {
  final double freq;
  final double startFreq;
  final int ms;
  final Wave wave;
  final double volume;

  const Tone(
    this.freq,
    this.ms, {
    this.wave = Wave.square,
    this.volume = 0.35,
    double? from,
  }) : startFreq = from ?? freq;
}

/// Convierte una secuencia de tonos en muestras.
List<double> render(List<Tone> tones) {
  final samples = <double>[];
  final rnd = Random(1);

  for (final tone in tones) {
    final count = (sampleRate * tone.ms / 1000).round();
    var phase = 0.0;

    for (var i = 0; i < count; i++) {
      final t = i / count;

      // Barrido de frecuencia: permite los "swoop" de subir y bajar.
      final freq = tone.startFreq + (tone.freq - tone.startFreq) * t;
      phase += 2 * pi * freq / sampleRate;

      // Envolvente: ataque muy corto y caída suave. Sin esto se oye un "clic"
      // al principio y al final de cada tono.
      const attack = 0.02;
      final envelope = t < attack
          ? t / attack
          : pow(1 - (t - attack) / (1 - attack), 1.6).toDouble();

      samples.add(waveAt(tone.wave, phase, rnd) * envelope * tone.volume);
    }
  }
  return samples;
}

/// Los sonidos del juego. Las frecuencias siguen una escala pentatónica para
/// que nada suene desafinado aunque se solapen dos efectos.
final Map<String, List<Tone>> sounds = {
  // Mover: un clic seco y grave, se oye cien veces por partida así que tiene
  // que ser discreto.
  'move': [const Tone(220, 25, volume: 0.15)],

  // Rotar: un poco más agudo que mover.
  'rotate': [const Tone(440, 35, wave: Wave.triangle, volume: 0.2)],

  // Fijar pieza: golpe grave y corto.
  'lock': [
    const Tone(140, 45, wave: Wave.square, volume: 0.25),
    const Tone(90, 35, wave: Wave.noise, volume: 0.12),
  ],

  // Hard drop: barrido descendente, sensación de caída.
  'harddrop': [const Tone(120, 90, from: 500, wave: Wave.square, volume: 0.28)],

  // Hold: dos notas ascendentes.
  'hold': [
    const Tone(392, 45, wave: Wave.triangle, volume: 0.22),
    const Tone(587, 60, wave: Wave.triangle, volume: 0.22),
  ],

  // Una línea: arpegio corto hacia arriba.
  'clear': [
    const Tone(523, 60, wave: Wave.triangle, volume: 0.3),
    const Tone(659, 80, wave: Wave.triangle, volume: 0.3),
  ],

  // Tetris: la fanfarria. Cuatro notas, más largas y más fuertes.
  'tetris': [
    const Tone(523, 70, wave: Wave.square, volume: 0.32),
    const Tone(659, 70, wave: Wave.square, volume: 0.32),
    const Tone(784, 70, wave: Wave.square, volume: 0.32),
    const Tone(1047, 180, wave: Wave.square, volume: 0.34),
  ],

  // T-Spin: distinto del Tetris a propósito, para reconocerlo de oído.
  'tspin': [
    const Tone(880, 60, wave: Wave.sine, volume: 0.3),
    const Tone(1175, 60, wave: Wave.sine, volume: 0.3),
    const Tone(1568, 140, wave: Wave.sine, volume: 0.32),
  ],

  // Subir de nivel.
  'levelup': [
    const Tone(659, 70, wave: Wave.triangle, volume: 0.3),
    const Tone(880, 70, wave: Wave.triangle, volume: 0.3),
    const Tone(1319, 200, wave: Wave.triangle, volume: 0.32),
  ],

  // Fin de partida: barrido descendente, largo y triste.
  'gameover': [
    const Tone(330, 200, from: 440, wave: Wave.triangle, volume: 0.3),
    const Tone(220, 200, from: 330, wave: Wave.triangle, volume: 0.3),
    const Tone(110, 400, from: 220, wave: Wave.triangle, volume: 0.3),
  ],
};

void main() {
  final dir = Directory('assets/audio');
  dir.createSync(recursive: true);

  for (final entry in sounds.entries) {
    final bytes = toWav(render(entry.value));
    final file = File('${dir.path}/${entry.key}.wav');
    file.writeAsBytesSync(bytes);
    stdout.writeln(
        '${entry.key}.wav  ${(bytes.length / 1024).toStringAsFixed(1)} KB');
  }
  stdout.writeln('\n${sounds.length} efectos generados en assets/audio/');
}
