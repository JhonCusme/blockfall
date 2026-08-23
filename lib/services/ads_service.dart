/// Carga y muestra los anuncios de AdMob.
///
/// Reglas del juego (decididas en el diseño, no aquí):
///   · Banner en menús y pausa. **Nunca durante la partida.**
///   · Intersticial cada 3 partidas terminadas.
///   · Vídeo recompensado para revivir, una vez por partida.
///
/// Todo se salta si el jugador es premium. Y todo falla en silencio: quedarse
/// sin conexión no puede impedir jugar.
library;

import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';

class AdsService {
  /// Lo pone el estado de la app: si es premium, aquí no se muestra nada.
  bool premium = false;

  /// Avisos de que empieza y termina un anuncio a pantalla completa.
  ///
  /// Los usa `main()` para silenciar la música mientras suena el audio del
  /// anuncio: dos músicas a la vez es de las cosas que más molestan.
  Future<void> Function()? onFullScreenStart;
  Future<void> Function()? onFullScreenEnd;

  bool _initialized = false;

  final Completer<void> _ready = Completer<void>();

  /// Se completa cuando el SDK terminó de arrancar, haya ido bien o mal.
  ///
  /// Los widgets deben esperarlo antes de pedir un banner: `init()` es
  /// asíncrono y el primer frame de la app llega mucho antes de que termine.
  Future<void> get ready => _ready.future;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  int _gamesSinceInterstitial = 0;
  DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);

  /// Arranca el SDK y pide el consentimiento cuando hace falta.
  Future<void> init() async {
    if (_initialized) return;
    try {
      // En iOS hay que pedir el permiso de seguimiento ANTES de arrancar el
      // SDK de anuncios. Si se hace después, la primera petición ya se envió
      // sin identificador y se pierde.
      await _requestTrackingIos();

      await MobileAds.instance.initialize();

      // Dispositivos marcados como de prueba: reciben anuncios de prueba
      // aunque la compilación sea release. Es la única forma segura de
      // probar el APK final en un móvil propio sin arriesgar la cuenta.
      if (testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: testDeviceIds),
        );
      }

      _initialized = true;
      await _requestConsent();
      _preloadInterstitial();
      _preloadRewarded();
    } catch (e) {
      debugPrint('AdMob no arrancó, se sigue sin anuncios: $e');
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  /// Pide el permiso de seguimiento de Apple (App Tracking Transparency).
  ///
  /// Solo aplica en iOS; en Android no existe y la llamada se salta. Si el
  /// jugador dice que no, el juego funciona igual: los anuncios pasan a ser no
  /// personalizados y se paga menos por ellos, nada más.
  ///
  /// Apple exige además que el diálogo no sea lo primerísimo que ve alguien al
  /// abrir la app por primera vez, así que se espera un momento a que la
  /// interfaz esté montada.
  Future<void> _requestTrackingIos() async {
    if (!Platform.isIOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('Permiso de seguimiento no disponible: $e');
    }
  }

  /// Formulario de consentimiento (UMP).
  ///
  /// Es **obligatorio** para usuarios del Espacio Económico Europeo y Reino
  /// Unido. Sin él, Google puede dejar de servir anuncios personalizados o
  /// bloquear la cuenta. Fuera de esas zonas no aparece nada.
  Future<void> _requestConsent() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            ConsentForm.loadAndShowConsentFormIfRequired((_) {
              if (!completer.isCompleted) completer.complete();
            });
          } else {
            if (!completer.isCompleted) completer.complete();
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (error) {
        debugPrint('Consentimiento no disponible: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    // No dejamos la app esperando indefinidamente por el formulario.
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  // --- banner ---

  /// Crea un banner nuevo. Cada pantalla necesita el suyo: un mismo objeto
  /// `BannerAd` no se puede montar en dos sitios a la vez.
  BannerAd? createBanner({VoidCallback? onLoaded}) {
    if (premium || !_initialized) return null;
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner falló: ${error.message}');
          ad.dispose();
        },
      ),
    );
    ad.load();
    return ad;
  }

  // --- intersticial ---

  void _preloadInterstitial() {
    if (premium || !_initialized || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Intersticial falló: ${error.message}');
          _interstitial = null;
        },
      ),
    );
  }

  /// Avisa de que ha terminado una partida y muestra el intersticial si toca.
  ///
  /// Devuelve `true` si se mostró, para que la pantalla sepa que perdió el
  /// foco un momento.
  Future<bool> onGameFinished() async {
    if (premium || !_initialized) return false;

    _gamesSinceInterstitial++;
    if (_gamesSinceInterstitial < AdPolicy.gamesPerInterstitial) return false;

    // Cortafuegos contra el encadenado de partidas cortas.
    if (DateTime.now().difference(_lastInterstitial) <
        AdPolicy.minInterstitialGap) {
      return false;
    }

    final ad = _interstitial;
    if (ad == null) {
      _preloadInterstitial();
      return false;
    }

    final shown = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _preloadInterstitial();
        onFullScreenEnd?.call();
        if (!shown.isCompleted) shown.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        _preloadInterstitial();
        onFullScreenEnd?.call();
        if (!shown.isCompleted) shown.complete(false);
      },
    );

    _gamesSinceInterstitial = 0;
    _lastInterstitial = DateTime.now();
    _interstitial = null;
    await onFullScreenStart?.call();
    await ad.show();
    return shown.future;
  }

  // --- vídeo recompensado (revivir) ---

  void _preloadRewarded() {
    if (premium || !_initialized || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Recompensado falló: ${error.message}');
          _rewarded = null;
        },
      ),
    );
  }

  /// ¿Hay un vídeo listo? La pantalla de game over solo debe ofrecer revivir
  /// si la respuesta es sí: un botón que no funciona es peor que no tenerlo.
  ///
  /// El premium no ve anuncios, pero revivir es una ventaja de juego, no un
  /// anuncio: se le concede directamente sin vídeo.
  bool get isRewardedReady => premium || _rewarded != null;

  /// Muestra el vídeo. Devuelve `true` solo si el jugador se lo ganó viéndolo
  /// entero. Cerrarlo antes no cuenta.
  Future<bool> showRewarded() async {
    if (premium) return true;
    final ad = _rewarded;
    if (ad == null) {
      _preloadRewarded();
      return false;
    }

    var earned = false;
    final done = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        _preloadRewarded();
        onFullScreenEnd?.call();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewarded = null;
        _preloadRewarded();
        onFullScreenEnd?.call();
        if (!done.isCompleted) done.complete(false);
      },
    );

    _rewarded = null;
    await onFullScreenStart?.call();
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }

  /// Al hacerse premium se tira todo lo cargado y se deja de pedir más.
  void onPremiumChanged(bool isPremium) {
    premium = isPremium;
    if (isPremium) {
      _interstitial?.dispose();
      _interstitial = null;
      _rewarded?.dispose();
      _rewarded = null;
    } else {
      _preloadInterstitial();
      _preloadRewarded();
    }
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
