/// Identificadores de AdMob.
///
/// ─────────────────────────────────────────────────────────────────────────
///  IMPORTANTE: mientras `useTestAds` sea `true` se usan los bloques de
///  prueba oficiales de Google. NUNCA pongas los IDs reales para probar en tu
///  propio teléfono: Google considera eso "tráfico inválido" y cierra la
///  cuenta de AdMob de forma permanente, quedándose con lo que hubiera
///  pendiente de pago. Tampoco pidas a nadie que haga clic en tus anuncios.
///
///  Android ya está en producción: bloques reales en release, de prueba en
///  depuración, sin tocar nada. iOS sigue pendiente de crear sus bloques
///  (llegará en la fase de iOS).
/// ─────────────────────────────────────────────────────────────────────────
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

/// En depuración SIEMPRE anuncios de prueba. En release, los reales.
///
/// Atarlo a `kDebugMode` en vez de a una constante a mano evita el accidente
/// más caro posible: publicar con los bloques de prueba (ingresos cero) o,
/// peor, desarrollar contra los reales y que te cierren la cuenta.
const bool useTestAds = kDebugMode;

/// Dispositivos donde se sirven anuncios de prueba aunque la compilación sea
/// release.
///
/// Los emuladores ya cuentan como dispositivo de prueba automáticamente, pero
/// un teléfono real NO. Si vas a instalarte el APK de release en tu móvil,
/// añade aquí su identificador o corres el riesgo de tocar un anuncio real
/// tuyo, que es tráfico inválido.
///
/// Para encontrarlo: instala la app, ábrela con el móvil conectado y busca en
/// el log una línea como
///   `Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList("33BE2250B43518CCDA7DE426D04EE231"))`
/// Ese texto entre comillas es el identificador.
const List<String> testDeviceIds = <String>[
  // 'PON_AQUI_EL_ID_DE_TU_MOVIL',
];

// --- Bloques de prueba oficiales de Google (se pueden pulsar sin riesgo) ---

const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

// --- Bloques reales de la cuenta de AdMob (editor 9365652468083873) ---
//
// App ID de Android: ca-app-pub-9365652468083873~1544364533
// (va en AndroidManifest.xml, no aquí; fíjate en la virgulilla: el App ID usa
// «~» y los bloques usan «/». Confundirlos hace que no cargue ningún anuncio.)

const _realBannerAndroid = 'ca-app-pub-9365652468083873/8443930324';
const _realInterstitialAndroid = 'ca-app-pub-9365652468083873/2920035705';
const _realRewardedAndroid = 'ca-app-pub-9365652468083873/9231282864';

/// Comodín para lo que aún no exista. Hoy no queda ningún bloque pendiente,
/// pero se deja definido por si se añade una plataforma nueva más adelante.
const _pendiente = 'PENDIENTE';

const _realBannerIos = 'ca-app-pub-9365652468083873/9200914151';
const _realInterstitialIos = 'ca-app-pub-9365652468083873/9723658333';
const _realRewardedIos = 'ca-app-pub-9365652468083873/7887832487';

class AdIds {
  const AdIds._();

  static String get banner => _pick(
        testAndroid: _testBannerAndroid,
        testIos: _testBannerIos,
        realAndroid: _realBannerAndroid,
        realIos: _realBannerIos,
      );

  static String get interstitial => _pick(
        testAndroid: _testInterstitialAndroid,
        testIos: _testInterstitialIos,
        realAndroid: _realInterstitialAndroid,
        realIos: _realInterstitialIos,
      );

  static String get rewarded => _pick(
        testAndroid: _testRewardedAndroid,
        testIos: _testRewardedIos,
        realAndroid: _realRewardedAndroid,
        realIos: _realRewardedIos,
      );

  static String _pick({
    required String testAndroid,
    required String testIos,
    required String realAndroid,
    required String realIos,
  }) {
    final isAndroid = Platform.isAndroid;
    if (useTestAds) return isAndroid ? testAndroid : testIos;

    final real = isAndroid ? realAndroid : realIos;
    // Red de seguridad para iOS, que aún no tiene bloques: pedir un ID
    // inválido no rompe nada, pero deja la pantalla sin anuncio y sin pista
    // de por qué. Mejor caer al de prueba y avisar en el log.
    if (real == _pendiente) {
      debugPrint('AdMob: falta el bloque real de esta plataforma, '
          'se usa el de prueba.');
      return isAndroid ? testAndroid : testIos;
    }
    return real;
  }
}

/// Reglas de negocio de la monetización, en un solo sitio para poder ajustarlas
/// sin bucear por la app.
class AdPolicy {
  const AdPolicy._();

  /// Un intersticial cada tantas partidas terminadas.
  static const int gamesPerInterstitial = 3;

  /// Revivir viendo un vídeo: una sola vez por partida, sin excepciones.
  static const int maxRevivesPerGame = 1;

  /// Tiempo mínimo entre dos intersticiales, por si el jugador encadena
  /// partidas de diez segundos.
  static const Duration minInterstitialGap = Duration(seconds: 90);
}
