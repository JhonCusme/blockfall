/// Genera la música de fondo de Blockfall.
///
/// La melodía es **original**. Es tentador usar «Korobéiniki», la canción
/// popular rusa del Tetris clásico: la melodía es de dominio público y usarla
/// sería legal. Pero suena tan asociada a la marca Tetris que echaría por
/// tierra el trabajo de haber elegido un nombre propio, y da pie a discusiones
/// de imagen comercial que no interesa tener.
///
/// Se sintetiza por código igual que los efectos: sin licencias de terceros,
/// versionado, y retocable cambiando unos números.
///
/// Ejecutar desde la raíz del proyecto:
///   dart run tool/generate_music.dart
///
/// Produce assets/audio/music_loop.wav, un bucle sin costura de 16 compases.
library;

import 'dart:io';
import 'dart:math';

import 'wav.dart';

// --- Parámetros de la pieza ---

const double bpm = 128;
const int beatsPerBar = 4;
const int bars = 16;

double get secondsPerBeat => 60 / bpm;
int get totalSamples =>
    (sampleRate * secondsPerBeat * beatsPerBar * bars).round();

// Notas MIDI que se usan (69 = la4 = 440 Hz).
const a3 = 57, b3 = 59, c4 = 60, d4 = 62, e4 = 64, f4 = 65, g4 = 67;
const a4 = 69, b4 = 71, c5 = 72, d5 = 74, e5 = 76, f5 = 77, g5 = 79, a5 = 81;

/// Un acorde: sus notas para el arpegio y su fundamental para el bajo.
class Chord {
  final String name;
  final int bass;
  final List<int> tones;
  const Chord(this.name, this.bass, this.tones);
}

// La menor. Progresión clásica pero con un giro en los compases 7-8 y 15-16
// para que el bucle no se haga plano a los cinco minutos.
const am = Chord('Am', 45, [a3, c4, e4]);
const f = Chord('F', 41, [f4, a3, c4]);
const c = Chord('C', 48, [c4, e4, g4]);
const g = Chord('G', 43, [g4, b3, d4]);
const dm = Chord('Dm', 50, [d4, f4, a4]);
const e = Chord('E', 40, [e4, g4, b4]);

const progression = <Chord>[
  am, f, c, g, am, f, dm, e, //
  am, f, c, g, am, f, e, am,
];

/// Una nota de la melodía: altura MIDI (o `null` para silencio) y duración en
/// tiempos.
class Note {
  final int? midi;
  final double beats;
  const Note(this.midi, this.beats);
}

/// La melodía, 16 compases de 4 tiempos.
///
/// Está construida con movimiento por grados conjuntos y saltos a notas del
/// acorde, y termina resolviendo en la: así el final enlaza con el principio
/// sin que se note el corte del bucle.
const melody = <Note>[
  // 1 Am
  Note(e5, 1), Note(c5, 1), Note(a4, 1), Note(c5, 1),
  // 2 F
  Note(d5, 1), Note(c5, 1), Note(a4, 2),
  // 3 C
  Note(e5, 1), Note(g5, 1), Note(e5, 1), Note(c5, 1),
  // 4 G
  Note(d5, 2), Note(b4, 2),
  // 5 Am
  Note(c5, 1), Note(e5, 1), Note(a5, 1), Note(e5, 1),
  // 6 F
  Note(f5, 1), Note(e5, 1), Note(c5, 2),
  // 7 Dm
  Note(d5, 1), Note(f5, 1), Note(a4, 1), Note(d5, 1),
  // 8 E
  Note(e5, 2), Note(b4, 2),
  // 9 Am — variación: arranque con anacrusa de corcheas
  Note(a4, 0.5), Note(b4, 0.5), Note(c5, 1), Note(e5, 1), Note(d5, 1),
  // 10 F
  Note(c5, 1), Note(a4, 1), Note(f5, 2),
  // 11 C
  Note(e5, 1), Note(c5, 1), Note(d5, 1), Note(e5, 1),
  // 12 G
  Note(g5, 2), Note(d5, 2),
  // 13 Am
  Note(e5, 1), Note(c5, 1), Note(a4, 1), Note(b4, 1),
  // 14 F
  Note(c5, 2), Note(a4, 2),
  // 15 E
  Note(b4, 1), Note(e5, 1), Note(g5, 1), Note(e5, 1),
  // 16 Am — resuelve y deja respirar antes de volver al principio
  Note(a4, 3), Note(null, 1),
];

/// Escribe una nota en el buffer.
///
/// [start] y [duration] van en segundos. La envolvente evita el chasquido de
/// empezar y acabar una onda en seco.
void renderNote(
  List<double> buffer,
  Wave wave,
  double freq,
  double start,
  double duration,
  double volume, {
  double attack = 0.01,
  double release = 0.25,
}) {
  final from = (start * sampleRate).round();
  final count = (duration * sampleRate).round();
  if (count <= 0) return;

  final rnd = Random(from);
  var phase = 0.0;
  final step = 2 * pi * freq / sampleRate;

  for (var i = 0; i < count; i++) {
    final index = from + i;
    // Se recorta en el final del bucle: así no hay cola sonando por encima
    // del principio cuando se repite.
    if (index >= buffer.length) break;

    final t = i / count;
    double env;
    if (t < attack) {
      env = t / attack;
    } else if (t > 1 - release) {
      env = (1 - t) / release;
    } else {
      env = 1;
    }

    phase += step;
    buffer[index] += waveAt(wave, phase, rnd) * env * volume;
  }
}

/// Golpe grave de bombo: un barrido rápido de frecuencia hacia abajo.
void renderKick(List<double> buffer, double start, double volume) {
  final from = (start * sampleRate).round();
  final count = (0.09 * sampleRate).round();
  var phase = 0.0;
  for (var i = 0; i < count; i++) {
    final index = from + i;
    if (index >= buffer.length) break;
    final t = i / count;
    final freq = 130 - 80 * t;
    phase += 2 * pi * freq / sampleRate;
    final env = pow(1 - t, 2.5).toDouble();
    buffer[index] += sin(phase) * env * volume;
  }
}

/// Caja: ruido con caída muy rápida.
void renderSnare(List<double> buffer, double start, double volume) {
  final from = (start * sampleRate).round();
  final count = (0.07 * sampleRate).round();
  final rnd = Random(from);
  for (var i = 0; i < count; i++) {
    final index = from + i;
    if (index >= buffer.length) break;
    final t = i / count;
    final env = pow(1 - t, 3).toDouble();
    buffer[index] += (rnd.nextDouble() * 2 - 1) * env * volume;
  }
}

void main() {
  final buffer = List<double>.filled(totalSamples, 0);
  final beat = secondsPerBeat;

  // --- Bajo: fundamental del acorde en los tiempos 1 y 3 ---
  for (var bar = 0; bar < bars; bar++) {
    final chord = progression[bar];
    final barStart = bar * beatsPerBar * beat;
    for (final offset in [0.0, 2.0]) {
      renderNote(
        buffer,
        Wave.triangle,
        midiToHz(chord.bass),
        barStart + offset * beat,
        beat * 1.8,
        0.30,
        release: 0.35,
      );
    }
  }

  // --- Arpegio: corcheas recorriendo las notas del acorde ---
  //
  // Es el relleno que da movimiento. Va bajo de volumen a propósito: tiene que
  // sostener la melodía, no competir con ella ni con los efectos del juego.
  for (var bar = 0; bar < bars; bar++) {
    final chord = progression[bar];
    final barStart = bar * beatsPerBar * beat;
    for (var eighth = 0; eighth < beatsPerBar * 2; eighth++) {
      final tone = chord.tones[eighth % chord.tones.length];
      renderNote(
        buffer,
        Wave.triangle,
        midiToHz(tone + 12),
        barStart + eighth * beat / 2,
        beat * 0.45,
        0.085,
        release: 0.5,
      );
    }
  }

  // --- Melodía ---
  var cursor = 0.0;
  for (final note in melody) {
    final duration = note.beats * beat;
    if (note.midi != null) {
      renderNote(
        buffer,
        Wave.square,
        midiToHz(note.midi!),
        cursor,
        duration * 0.92,
        0.20,
        release: 0.3,
      );
    }
    cursor += duration;
  }

  // --- Percusión: bombo en 1 y 3, caja en 2 y 4 ---
  for (var bar = 0; bar < bars; bar++) {
    final barStart = bar * beatsPerBar * beat;
    renderKick(buffer, barStart, 0.22);
    renderKick(buffer, barStart + 2 * beat, 0.18);
    renderSnare(buffer, barStart + beat, 0.055);
    renderSnare(buffer, barStart + 3 * beat, 0.055);
  }

  final dir = Directory('assets/audio');
  dir.createSync(recursive: true);
  final bytes = toWav(buffer, master: 0.9);
  File('${dir.path}/music_loop.wav').writeAsBytesSync(bytes);

  final seconds = totalSamples / sampleRate;
  stdout.writeln('music_loop.wav  '
      '${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB  '
      '${seconds.toStringAsFixed(1)} s  ·  $bars compases a $bpm BPM');
  if (melody.fold<double>(0, (sum, n) => sum + n.beats) != bars * beatsPerBar) {
    stdout.writeln('AVISO: la melodía no cuadra con la duración del bucle.');
  }
}
