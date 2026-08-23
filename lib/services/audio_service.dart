/// Reproducción de efectos de sonido.
///
/// Los efectos de un Tetris se disparan muy seguidos —mover la pieza suena
/// varias veces por segundo— así que hay dos decisiones importantes aquí:
///
/// 1. Un pool de reproductores por sonido, para que un efecto no corte al
///    anterior ni haya que crear un reproductor nuevo cada vez.
/// 2. Los archivos se precargan al arrancar. Si no, el primer "Tetris" de la
///    partida llegaría con retraso audible.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx {
  move,
  rotate,
  lock,
  hardDrop,
  hold,
  clear,
  tetris,
  tSpin,
  levelUp,
  gameOver,
}

extension on Sfx {
  /// Ruta relativa a `assets/`, que es como las quiere audioplayers.
  String get asset => switch (this) {
        Sfx.move => 'audio/move.wav',
        Sfx.rotate => 'audio/rotate.wav',
        Sfx.lock => 'audio/lock.wav',
        Sfx.hardDrop => 'audio/harddrop.wav',
        Sfx.hold => 'audio/hold.wav',
        Sfx.clear => 'audio/clear.wav',
        Sfx.tetris => 'audio/tetris.wav',
        Sfx.tSpin => 'audio/tspin.wav',
        Sfx.levelUp => 'audio/levelup.wav',
        Sfx.gameOver => 'audio/gameover.wav',
      };

  /// Cuántos reproductores simultáneos. Los sonidos rápidos y repetitivos
  /// necesitan más; una fanfarria de fin de partida, uno basta.
  int get voices => switch (this) {
        Sfx.move || Sfx.rotate || Sfx.lock => 3,
        _ => 1,
      };
}

class AudioService {
  final Map<Sfx, List<AudioPlayer>> _pools = {};
  final Map<Sfx, int> _nextVoice = {};

  bool enabled = true;

  // --- música ---

  static const String _musicAsset = 'audio/music_loop.wav';

  /// Volumen de la música. Muy por debajo de los efectos: acompaña la partida,
  /// no compite con ella.
  static const double _musicVolume = 0.32;

  AudioPlayer? _musicPlayer;

  /// Lo que el jugador quiere, según Ajustes.
  bool _musicEnabled = true;

  /// Pausas temporales que no son decisión del jugador: la app se fue a
  /// segundo plano, o hay un anuncio a pantalla completa sonando.
  ///
  /// Se cuentan en vez de usar un booleano porque las dos cosas pueden
  /// solaparse: si un anuncio manda la app al fondo, al volver no debe
  /// reanudarse la música hasta que ambas hayan terminado.
  int _suspensions = 0;

  /// Si la precarga falla (formato no soportado, permisos), el juego debe
  /// seguir funcionando sin sonido en vez de caerse.
  bool _ready = false;

  Future<void> init() async {
    try {
      for (final sfx in Sfx.values) {
        final players = <AudioPlayer>[];
        for (var i = 0; i < sfx.voices; i++) {
          final player = AudioPlayer()
            ..setReleaseMode(ReleaseMode.stop)
            ..setPlayerMode(PlayerMode.lowLatency);
          await player.setSource(AssetSource(sfx.asset));
          players.add(player);
        }
        _pools[sfx] = players;
        _nextVoice[sfx] = 0;
      }
      _ready = true;
    } catch (e) {
      debugPrint('Audio no disponible, el juego sigue sin sonido: $e');
      _ready = false;
    }
  }

  void play(Sfx sfx) {
    if (!enabled || !_ready) return;
    final pool = _pools[sfx];
    if (pool == null || pool.isEmpty) return;

    // Rotamos entre las voces del pool: así dos golpes seguidos suenan
    // solapados en lugar de cortarse.
    final index = _nextVoice[sfx] ?? 0;
    _nextVoice[sfx] = (index + 1) % pool.length;

    final player = pool[index];
    // No esperamos al future: un efecto que tarda no debe frenar el frame.
    player.stop().then((_) => player.resume()).catchError((Object _) {});
  }

  // --- música ---

  /// Enciende o apaga la música según los Ajustes.
  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    if (value) {
      await _startMusic();
    } else {
      await _stopMusic();
    }
  }

  /// Pausa la música por un motivo ajeno al jugador: la app pasó a segundo
  /// plano, o empezó un anuncio a pantalla completa con su propio audio.
  Future<void> suspendMusic() async {
    _suspensions++;
    if (_suspensions == 1) {
      try {
        await _musicPlayer?.pause();
      } catch (_) {}
    }
  }

  /// Deshace una llamada a [suspendMusic]. Solo reanuda cuando no queda
  /// ninguna suspensión pendiente y el jugador tiene la música activada.
  Future<void> resumeMusic() async {
    if (_suspensions > 0) _suspensions--;
    if (_suspensions == 0 && _musicEnabled) {
      try {
        if (_musicPlayer == null) {
          await _startMusic();
        } else {
          await _musicPlayer!.resume();
        }
      } catch (_) {}
    }
  }

  Future<void> _startMusic() async {
    if (!_musicEnabled || _suspensions > 0) return;
    try {
      final player = _musicPlayer ??= AudioPlayer()
        // `loop` hace que el bucle lo repita el reproductor nativo, sin
        // silencio entre repeticiones ni trabajo desde Dart.
        ..setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_musicVolume);
      await player.play(AssetSource(_musicAsset));
    } catch (e) {
      debugPrint('Música no disponible: $e');
    }
  }

  Future<void> _stopMusic() async {
    try {
      await _musicPlayer?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final pool in _pools.values) {
      for (final player in pool) {
        await player.dispose();
      }
    }
    _pools.clear();
    await _musicPlayer?.dispose();
    _musicPlayer = null;
  }
}
