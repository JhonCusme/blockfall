/// Utilidades compartidas para generar audio: síntesis de ondas y empaquetado
/// en WAV.
///
/// Lo usan `generate_sfx.dart` (efectos) y `generate_music.dart` (música).
library;

import 'dart:math';
import 'dart:typed_data';

/// Frecuencia de muestreo de todo el audio del juego.
///
/// 22050 Hz es la mitad de la calidad de un CD: de sobra para sonidos de
/// consola y ocupa la mitad de espacio en el APK.
const int sampleRate = 22050;

/// Forma de onda. La cuadrada suena a consola antigua; la sinusoidal, suave.
enum Wave { square, sine, triangle, saw, noise }

/// Valor de la onda [w] en la fase [phase] (en radianes).
double waveAt(Wave w, double phase, Random rnd) {
  switch (w) {
    case Wave.square:
      return sin(phase) >= 0 ? 1 : -1;
    case Wave.sine:
      return sin(phase);
    case Wave.triangle:
      return 2 / pi * asin(sin(phase));
    case Wave.saw:
      // Diente de sierra a partir de la fase normalizada a [0,1).
      final x = (phase / (2 * pi)) % 1.0;
      return x * 2 - 1;
    case Wave.noise:
      return rnd.nextDouble() * 2 - 1;
  }
}

/// Convierte muestras en coma flotante (rango aproximado [-1, 1]) a un WAV
/// mono de 16 bits.
///
/// Aplica un limitador suave: en vez de recortar en seco lo que se pasa de
/// rango —que suena a distorsión sucia— comprime los picos con una tangente
/// hiperbólica.
Uint8List toWav(List<double> samples, {double master = 1.0}) {
  final pcm = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    final x = samples[i] * master;
    // tanh como limitador: transparente por debajo de ~0.6, y a partir de ahí
    // dobla los picos en lugar de cortarlos.
    final limited = _tanh(x);
    pcm[i] = (limited * 32767).round().clamp(-32768, 32767);
  }

  final data = pcm.buffer.asUint8List();
  final header = ByteData(44);

  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + data.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // tamaño del bloque fmt
  header.setUint16(20, 1, Endian.little); // PCM sin comprimir
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little); // bytes por segundo
  header.setUint16(32, 2, Endian.little); // alineación de bloque
  header.setUint16(34, 16, Endian.little); // bits por muestra
  ascii(36, 'data');
  header.setUint32(40, data.length, Endian.little);

  return Uint8List.fromList([...header.buffer.asUint8List(), ...data]);
}

double _tanh(double x) {
  if (x > 4) return 1;
  if (x < -4) return -1;
  final e = exp(2 * x);
  return (e - 1) / (e + 1);
}

/// Frecuencia en hercios de una nota MIDI. 69 = la4 = 440 Hz.
double midiToHz(int note) => 440 * pow(2, (note - 69) / 12).toDouble();
