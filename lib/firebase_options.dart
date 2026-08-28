/// Configuración de Firebase.
///
/// ─────────────────────────────────────────────────────────────────────────
///  CÓMO RELLENAR ESTO
///
///  1. Entra en https://console.firebase.google.com y crea un proyecto
///     llamado "Blockfall".
///  2. Dentro del proyecto, añade una app **Android** con el nombre de
///     paquete exacto:  com.cusme.blockfall
///  3. Firebase te dará un archivo google-services.json. No hace falta
///     descargarlo: ábrelo (o mira la pantalla de configuración) y copia
///     estos cuatro valores aquí abajo.
///  4. En la consola, activa:
///       · Authentication → método "Anónimo"
///       · Firestore Database → crear en modo producción
///  5. Copia el contenido de firestore.rules (raíz del proyecto) en la
///     pestaña Reglas de Firestore y publica.
///
///  Alternativa automática: instalar la CLI y ejecutar `flutterfire configure`,
///  que sobrescribe este archivo solo. Requiere iniciar sesión con tu cuenta.
///
///  Mientras los valores sigan vacíos, el juego funciona con normalidad pero
///  sin ranking online: no se cae ni da errores, simplemente esa pestaña
///  avisa de que no está disponible.
/// ─────────────────────────────────────────────────────────────────────────
library;

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

/// Cliente OAuth **web** del proyecto de Firebase.
///
/// Aunque la app sea Android, google_sign_in necesita el ID del cliente web:
/// es el que identifica al servidor que va a validar el token. Sale del
/// google-services.json, en `oauth_client` con `client_type: 3`.
///
/// Poner aquí el cliente de Android por error es el fallo más común al montar
/// Google Sign-In: el inicio de sesión falla sin decir por qué.
const String googleServerClientId =
    '480651674209-k6ginl3a2f6t8610lq6ke57emm2dmi8f.apps.googleusercontent.com';

/// Cliente OAuth de **iOS**, del `GoogleService-Info.plist` (campo
/// `CLIENT_ID`, no `REVERSED_CLIENT_ID`).
///
/// En Android este dato lo obtiene el plugin solo, leyendo
/// `google-services.json` a través del Gradle plugin. En iOS normalmente se
/// lee de un `GoogleService-Info.plist` empaquetado en el proyecto de Xcode,
/// pero como este proyecto se compila sin Xcode (vía GitHub Actions, sin
/// Mac), no hay forma de verificar que ese archivo quedó bien referenciado en
/// el `.pbxproj`. Pasar el ID aquí, explícito, evita depender de eso.
const String googleIosClientId =
    '480651674209-uci10edmurl50kidglvs66542664kbg3.apps.googleusercontent.com';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  // --- Android ---
  static const _androidApiKey = 'AIzaSyCs5H3ZxUbBAKAm45um9-yhcv2Sxg5CCmY';
  static const _androidAppId = '1:480651674209:android:f4b1dc1a7965e6a3806020';
  static const _messagingSenderId = '480651674209';
  static const _projectId = 'blockfall-593';

  // Coincide con el "storage_bucket" del google-services.json. No se usa hoy
  // (no subimos archivos), pero Firebase lo pide.
  static String get _storageBucket =>
      _projectId.isEmpty ? '' : '$_projectId.firebasestorage.app';

  // --- iOS ---
  static const _iosApiKey = 'AIzaSyCxSGhmZ0CDSlqNLPxCZDXfYdeBGqsZd0Q';
  static const _iosAppId = '1:480651674209:ios:c1908b58ff6d3f63806020';
  static const _iosBundleId = 'com.cusme.blockfall';

  /// ¿Hay datos suficientes para intentar conectar?
  ///
  /// Se comprueba antes de inicializar: llamar a Firebase con cadenas vacías
  /// lanza una excepción fea en el arranque.
  static bool get isConfigured {
    if (Platform.isAndroid) {
      return _androidApiKey.isNotEmpty &&
          _androidAppId.isNotEmpty &&
          _projectId.isNotEmpty;
    }
    if (Platform.isIOS) {
      return _iosApiKey.isNotEmpty && _iosAppId.isNotEmpty;
    }
    return false;
  }

  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return FirebaseOptions(
        apiKey: _androidApiKey,
        appId: _androidAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );
    }
    if (Platform.isIOS) {
      return FirebaseOptions(
        apiKey: _iosApiKey,
        appId: _iosAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId,
      );
    }
    throw UnsupportedError('Blockfall solo soporta Android e iOS.');
  }
}
