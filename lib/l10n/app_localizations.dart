import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @modeMarathon.
  ///
  /// In es, this message translates to:
  /// **'Maratón'**
  String get modeMarathon;

  /// No description provided for @modeSprint.
  ///
  /// In es, this message translates to:
  /// **'Sprint · 40 líneas'**
  String get modeSprint;

  /// No description provided for @modeUltra.
  ///
  /// In es, this message translates to:
  /// **'Ultra · 2 minutos'**
  String get modeUltra;

  /// No description provided for @modeZen.
  ///
  /// In es, this message translates to:
  /// **'Zen · sin fin'**
  String get modeZen;

  /// No description provided for @modeMarathonShort.
  ///
  /// In es, this message translates to:
  /// **'Maratón'**
  String get modeMarathonShort;

  /// No description provided for @modeSprintShort.
  ///
  /// In es, this message translates to:
  /// **'Sprint'**
  String get modeSprintShort;

  /// No description provided for @modeUltraShort.
  ///
  /// In es, this message translates to:
  /// **'Ultra'**
  String get modeUltraShort;

  /// No description provided for @menuRecords.
  ///
  /// In es, this message translates to:
  /// **'Récords'**
  String get menuRecords;

  /// No description provided for @menuSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get menuSettings;

  /// No description provided for @menuBest.
  ///
  /// In es, this message translates to:
  /// **'Tu récord: {score}'**
  String menuBest(String score);

  /// No description provided for @hudHold.
  ///
  /// In es, this message translates to:
  /// **'Hold'**
  String get hudHold;

  /// No description provided for @hudNext.
  ///
  /// In es, this message translates to:
  /// **'Next'**
  String get hudNext;

  /// No description provided for @hudScore.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get hudScore;

  /// No description provided for @hudLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get hudLevel;

  /// No description provided for @hudLines.
  ///
  /// In es, this message translates to:
  /// **'Líneas'**
  String get hudLines;

  /// No description provided for @hudRemaining.
  ///
  /// In es, this message translates to:
  /// **'Faltan'**
  String get hudRemaining;

  /// No description provided for @hudTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get hudTime;

  /// No description provided for @hudCombo.
  ///
  /// In es, this message translates to:
  /// **'Combo'**
  String get hudCombo;

  /// No description provided for @hudPause.
  ///
  /// In es, this message translates to:
  /// **'PAUSA'**
  String get hudPause;

  /// No description provided for @clearTetris.
  ///
  /// In es, this message translates to:
  /// **'¡TETRIS!'**
  String get clearTetris;

  /// No description provided for @clearTriple.
  ///
  /// In es, this message translates to:
  /// **'TRIPLE'**
  String get clearTriple;

  /// No description provided for @clearTSpin.
  ///
  /// In es, this message translates to:
  /// **'T-SPIN'**
  String get clearTSpin;

  /// No description provided for @clearTSpinDouble.
  ///
  /// In es, this message translates to:
  /// **'T-SPIN DOBLE'**
  String get clearTSpinDouble;

  /// No description provided for @clearTSpinTriple.
  ///
  /// In es, this message translates to:
  /// **'T-SPIN TRIPLE'**
  String get clearTSpinTriple;

  /// No description provided for @clearTSpinMini.
  ///
  /// In es, this message translates to:
  /// **'T-SPIN MINI'**
  String get clearTSpinMini;

  /// No description provided for @gameOverTitle.
  ///
  /// In es, this message translates to:
  /// **'Fin de la partida'**
  String get gameOverTitle;

  /// No description provided for @gameCompletedTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Completado!'**
  String get gameCompletedTitle;

  /// No description provided for @gameOverScore.
  ///
  /// In es, this message translates to:
  /// **'Puntos: {score}'**
  String gameOverScore(int score);

  /// No description provided for @gameOverLines.
  ///
  /// In es, this message translates to:
  /// **'Líneas: {lines}'**
  String gameOverLines(int lines);

  /// No description provided for @gameOverLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel: {level}'**
  String gameOverLevel(int level);

  /// No description provided for @actionExit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get actionExit;

  /// No description provided for @actionRetry.
  ///
  /// In es, this message translates to:
  /// **'Otra vez'**
  String get actionRetry;

  /// No description provided for @reviveTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Continuar?'**
  String get reviveTitle;

  /// No description provided for @reviveBody.
  ///
  /// In es, this message translates to:
  /// **'Ve un vídeo y sigue jugando con la parte de arriba despejada, conservando tus {score} puntos.'**
  String reviveBody(int score);

  /// No description provided for @reviveOnce.
  ///
  /// In es, this message translates to:
  /// **'Solo una vez por partida.'**
  String get reviveOnce;

  /// No description provided for @reviveDecline.
  ///
  /// In es, this message translates to:
  /// **'No, terminar'**
  String get reviveDecline;

  /// No description provided for @reviveAccept.
  ///
  /// In es, this message translates to:
  /// **'Ver vídeo'**
  String get reviveAccept;

  /// No description provided for @recordsTitle.
  ///
  /// In es, this message translates to:
  /// **'Récords'**
  String get recordsTitle;

  /// No description provided for @recordsLocalTab.
  ///
  /// In es, this message translates to:
  /// **'Tus récords'**
  String get recordsLocalTab;

  /// No description provided for @recordsGlobalTab.
  ///
  /// In es, this message translates to:
  /// **'Global'**
  String get recordsGlobalTab;

  /// No description provided for @recordsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no has jugado a este modo'**
  String get recordsEmpty;

  /// No description provided for @recordsLinesDate.
  ///
  /// In es, this message translates to:
  /// **'{lines} líneas · {date}'**
  String recordsLinesDate(int lines, String date);

  /// No description provided for @recordsLinesLevelDate.
  ///
  /// In es, this message translates to:
  /// **'{lines} líneas · nivel {level} · {date}'**
  String recordsLinesLevelDate(int lines, int level, String date);

  /// No description provided for @rangeToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get rangeToday;

  /// No description provided for @rangeWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get rangeWeek;

  /// No description provided for @rangeAllTime.
  ///
  /// In es, this message translates to:
  /// **'Histórico'**
  String get rangeAllTime;

  /// No description provided for @leaderboardOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Ranking global no disponible'**
  String get leaderboardOfflineTitle;

  /// No description provided for @leaderboardOfflineBody.
  ///
  /// In es, this message translates to:
  /// **'Todavía no se ha conectado el servidor. Tus récords locales sí se están guardando.'**
  String get leaderboardOfflineBody;

  /// No description provided for @leaderboardErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar'**
  String get leaderboardErrorTitle;

  /// No description provided for @leaderboardErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Comprueba tu conexión y desliza hacia abajo para reintentar.'**
  String get leaderboardErrorBody;

  /// No description provided for @leaderboardEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Ranking vacío'**
  String get leaderboardEmptyTitle;

  /// No description provided for @leaderboardEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Nadie ha puntuado todavía en este periodo. Podrías ser el primero.'**
  String get leaderboardEmptyBody;

  /// No description provided for @leaderboardYou.
  ///
  /// In es, this message translates to:
  /// **'{name}  (tú)'**
  String leaderboardYou(String name);

  /// No description provided for @leaderboardLines.
  ///
  /// In es, this message translates to:
  /// **'{lines} líneas'**
  String leaderboardLines(int lines);

  /// No description provided for @leaderboardLinesLevel.
  ///
  /// In es, this message translates to:
  /// **'{lines} líneas · nivel {level}'**
  String leaderboardLinesLevel(int lines, int level);

  /// No description provided for @anonymous.
  ///
  /// In es, this message translates to:
  /// **'Anónimo'**
  String get anonymous;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsSectionSound.
  ///
  /// In es, this message translates to:
  /// **'Sonido'**
  String get settingsSectionSound;

  /// No description provided for @settingsSfx.
  ///
  /// In es, this message translates to:
  /// **'Efectos de sonido'**
  String get settingsSfx;

  /// No description provided for @settingsMusic.
  ///
  /// In es, this message translates to:
  /// **'Música'**
  String get settingsMusic;

  /// No description provided for @settingsVibration.
  ///
  /// In es, this message translates to:
  /// **'Vibración'**
  String get settingsVibration;

  /// No description provided for @settingsSectionGame.
  ///
  /// In es, this message translates to:
  /// **'Juego'**
  String get settingsSectionGame;

  /// No description provided for @settingsGhost.
  ///
  /// In es, this message translates to:
  /// **'Pieza fantasma'**
  String get settingsGhost;

  /// No description provided for @settingsGhostHint.
  ///
  /// In es, this message translates to:
  /// **'Muestra dónde va a caer la pieza'**
  String get settingsGhostHint;

  /// No description provided for @settingsButtons.
  ///
  /// In es, this message translates to:
  /// **'Botones en pantalla'**
  String get settingsButtons;

  /// No description provided for @settingsButtonsHint.
  ///
  /// In es, this message translates to:
  /// **'Si los quitas, se juega solo con gestos'**
  String get settingsButtonsHint;

  /// No description provided for @settingsSectionOnline.
  ///
  /// In es, this message translates to:
  /// **'Ranking global'**
  String get settingsSectionOnline;

  /// No description provided for @settingsNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre en el ranking'**
  String get settingsNameLabel;

  /// No description provided for @settingsNameHint.
  ///
  /// In es, this message translates to:
  /// **'Si lo dejas vacío aparecerás como «Anónimo»'**
  String get settingsNameHint;

  /// No description provided for @settingsSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión con Google'**
  String get settingsSignIn;

  /// No description provided for @settingsSignInApple.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión con Apple'**
  String get settingsSignInApple;

  /// No description provided for @settingsSignInHint.
  ///
  /// In es, this message translates to:
  /// **'Conserva tus récords aunque cambies de móvil o reinstales'**
  String get settingsSignInHint;

  /// No description provided for @settingsSignedInAs.
  ///
  /// In es, this message translates to:
  /// **'Sesión iniciada como {name}'**
  String settingsSignedInAs(String name);

  /// No description provided for @settingsSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOut;

  /// No description provided for @signInFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión. Inténtalo de nuevo.'**
  String get signInFailed;

  /// No description provided for @signInNoServices.
  ///
  /// In es, this message translates to:
  /// **'Este dispositivo no tiene servicios de Google.'**
  String get signInNoServices;

  /// No description provided for @signInRestored.
  ///
  /// In es, this message translates to:
  /// **'Recuperamos el historial de esa cuenta.'**
  String get signInRestored;

  /// No description provided for @settingsSectionTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsSectionTheme;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsSectionLanguage;

  /// No description provided for @languageAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get languageAuto;

  /// No description provided for @languageAutoHint.
  ///
  /// In es, this message translates to:
  /// **'Sigue el idioma del teléfono'**
  String get languageAutoHint;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeNeon.
  ///
  /// In es, this message translates to:
  /// **'Neón'**
  String get themeNeon;

  /// No description provided for @themeRetro.
  ///
  /// In es, this message translates to:
  /// **'Retro'**
  String get themeRetro;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'es':
      return LEs();
  }

  throw FlutterError(
      'L.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
