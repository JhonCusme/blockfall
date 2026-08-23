/// Estado global: ajustes, repositorio local y audio.
///
/// Riverpod se encarga de que un cambio de tema o de volumen llegue a todas
/// las pantallas sin pasarlo a mano de widget en widget.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_repository.dart';
import '../services/ads_service.dart';
import '../services/audio_service.dart';
import '../ui/theme.dart';

/// Se sobrescribe en `main()` con la instancia ya abierta: así ninguna
/// pantalla tiene que lidiar con un estado "todavía cargando".
final localRepositoryProvider = Provider<LocalRepository>(
  (ref) => throw UnimplementedError('Se define en main()'),
);

final audioServiceProvider = Provider<AudioService>(
  (ref) => throw UnimplementedError('Se define en main()'),
);

final adsServiceProvider = Provider<AdsService>(
  (ref) => throw UnimplementedError('Se define en main()'),
);

/// Suscripción "sin anuncios".
///
/// De momento solo lee la marca local. Cuando se implemente la suscripción de
/// verdad, este notifier consultará Google Play Billing al arrancar y ante
/// cada cambio de compra.
class PremiumNotifier extends StateNotifier<bool> {
  final LocalRepository _repo;
  final AdsService _ads;

  PremiumNotifier(this._repo, this._ads) : super(_repo.isPremium) {
    _ads.onPremiumChanged(state);
  }

  Future<void> setPremium(bool value) async {
    state = value;
    _ads.onPremiumChanged(value);
    await _repo.setPremium(value);
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(
    ref.watch(localRepositoryProvider),
    ref.watch(adsServiceProvider),
  );
});

class SettingsNotifier extends StateNotifier<Settings> {
  final LocalRepository _repo;
  final AudioService _audio;

  SettingsNotifier(this._repo, this._audio) : super(_repo.loadSettings()) {
    _audio.enabled = state.soundEnabled;
  }

  Future<void> _update(Settings next) async {
    final musicChanged = next.musicEnabled != state.musicEnabled;
    state = next;
    _audio.enabled = next.soundEnabled;
    if (musicChanged) await _audio.setMusicEnabled(next.musicEnabled);
    await _repo.saveSettings(next);
  }

  Future<void> toggleSound() =>
      _update(state.copyWith(soundEnabled: !state.soundEnabled));

  Future<void> toggleMusic() =>
      _update(state.copyWith(musicEnabled: !state.musicEnabled));

  Future<void> toggleVibration() =>
      _update(state.copyWith(vibrationEnabled: !state.vibrationEnabled));

  Future<void> toggleGhost() =>
      _update(state.copyWith(showGhost: !state.showGhost));

  Future<void> toggleButtons() =>
      _update(state.copyWith(showButtons: !state.showButtons));

  Future<void> setTheme(String id) => _update(state.copyWith(themeId: id));

  /// Cadena vacía = seguir el idioma del teléfono.
  Future<void> setLanguage(String code) =>
      _update(state.copyWith(languageCode: code));
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier(
    ref.watch(localRepositoryProvider),
    ref.watch(audioServiceProvider),
  );
});

/// El tema activo, derivado de los ajustes.
final themeProvider = Provider<BlockTheme>(
  (ref) => themeById(ref.watch(settingsProvider).themeId),
);

/// Idioma forzado por el jugador, o `null` para que mande el del teléfono.
///
/// Devolver `null` es justo lo que espera `MaterialApp.locale`: delega en el
/// sistema y aplica la resolución normal de idiomas.
final localeProvider = Provider<Locale?>((ref) {
  final code = ref.watch(settingsProvider).languageCode;
  return code.isEmpty ? null : Locale(code);
});
