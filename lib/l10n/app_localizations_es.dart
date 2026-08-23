// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class LEs extends L {
  LEs([String locale = 'es']) : super(locale);

  @override
  String get modeMarathon => 'Maratón';

  @override
  String get modeSprint => 'Sprint · 40 líneas';

  @override
  String get modeUltra => 'Ultra · 2 minutos';

  @override
  String get modeZen => 'Zen · sin fin';

  @override
  String get modeMarathonShort => 'Maratón';

  @override
  String get modeSprintShort => 'Sprint';

  @override
  String get modeUltraShort => 'Ultra';

  @override
  String get menuRecords => 'Récords';

  @override
  String get menuSettings => 'Ajustes';

  @override
  String menuBest(String score) {
    return 'Tu récord: $score';
  }

  @override
  String get hudHold => 'Hold';

  @override
  String get hudNext => 'Next';

  @override
  String get hudScore => 'Puntos';

  @override
  String get hudLevel => 'Nivel';

  @override
  String get hudLines => 'Líneas';

  @override
  String get hudRemaining => 'Faltan';

  @override
  String get hudTime => 'Tiempo';

  @override
  String get hudCombo => 'Combo';

  @override
  String get hudPause => 'PAUSA';

  @override
  String get clearTetris => '¡TETRIS!';

  @override
  String get clearTriple => 'TRIPLE';

  @override
  String get clearTSpin => 'T-SPIN';

  @override
  String get clearTSpinDouble => 'T-SPIN DOBLE';

  @override
  String get clearTSpinTriple => 'T-SPIN TRIPLE';

  @override
  String get clearTSpinMini => 'T-SPIN MINI';

  @override
  String get gameOverTitle => 'Fin de la partida';

  @override
  String get gameCompletedTitle => '¡Completado!';

  @override
  String gameOverScore(int score) {
    return 'Puntos: $score';
  }

  @override
  String gameOverLines(int lines) {
    return 'Líneas: $lines';
  }

  @override
  String gameOverLevel(int level) {
    return 'Nivel: $level';
  }

  @override
  String get actionExit => 'Salir';

  @override
  String get actionRetry => 'Otra vez';

  @override
  String get reviveTitle => '¿Continuar?';

  @override
  String reviveBody(int score) {
    return 'Ve un vídeo y sigue jugando con la parte de arriba despejada, conservando tus $score puntos.';
  }

  @override
  String get reviveOnce => 'Solo una vez por partida.';

  @override
  String get reviveDecline => 'No, terminar';

  @override
  String get reviveAccept => 'Ver vídeo';

  @override
  String get recordsTitle => 'Récords';

  @override
  String get recordsLocalTab => 'Tus récords';

  @override
  String get recordsGlobalTab => 'Global';

  @override
  String get recordsEmpty => 'Todavía no has jugado a este modo';

  @override
  String recordsLinesDate(int lines, String date) {
    return '$lines líneas · $date';
  }

  @override
  String recordsLinesLevelDate(int lines, int level, String date) {
    return '$lines líneas · nivel $level · $date';
  }

  @override
  String get rangeToday => 'Hoy';

  @override
  String get rangeWeek => 'Semana';

  @override
  String get rangeAllTime => 'Histórico';

  @override
  String get leaderboardOfflineTitle => 'Ranking global no disponible';

  @override
  String get leaderboardOfflineBody =>
      'Todavía no se ha conectado el servidor. Tus récords locales sí se están guardando.';

  @override
  String get leaderboardErrorTitle => 'No se pudo cargar';

  @override
  String get leaderboardErrorBody =>
      'Comprueba tu conexión y desliza hacia abajo para reintentar.';

  @override
  String get leaderboardEmptyTitle => 'Ranking vacío';

  @override
  String get leaderboardEmptyBody =>
      'Nadie ha puntuado todavía en este periodo. Podrías ser el primero.';

  @override
  String leaderboardYou(String name) {
    return '$name  (tú)';
  }

  @override
  String leaderboardLines(int lines) {
    return '$lines líneas';
  }

  @override
  String leaderboardLinesLevel(int lines, int level) {
    return '$lines líneas · nivel $level';
  }

  @override
  String get anonymous => 'Anónimo';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionSound => 'Sonido';

  @override
  String get settingsSfx => 'Efectos de sonido';

  @override
  String get settingsMusic => 'Música';

  @override
  String get settingsVibration => 'Vibración';

  @override
  String get settingsSectionGame => 'Juego';

  @override
  String get settingsGhost => 'Pieza fantasma';

  @override
  String get settingsGhostHint => 'Muestra dónde va a caer la pieza';

  @override
  String get settingsButtons => 'Botones en pantalla';

  @override
  String get settingsButtonsHint => 'Si los quitas, se juega solo con gestos';

  @override
  String get settingsSectionOnline => 'Ranking global';

  @override
  String get settingsNameLabel => 'Tu nombre en el ranking';

  @override
  String get settingsNameHint => 'Si lo dejas vacío aparecerás como «Anónimo»';

  @override
  String get settingsSignIn => 'Iniciar sesión con Google';

  @override
  String get settingsSignInHint =>
      'Conserva tus récords aunque cambies de móvil o reinstales';

  @override
  String settingsSignedInAs(String name) {
    return 'Sesión iniciada como $name';
  }

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get signInFailed => 'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get signInNoServices =>
      'Este dispositivo no tiene servicios de Google.';

  @override
  String get signInRestored => 'Recuperamos el historial de esa cuenta.';

  @override
  String get settingsSectionTheme => 'Tema';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get languageAuto => 'Automático';

  @override
  String get languageAutoHint => 'Sigue el idioma del teléfono';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeNeon => 'Neón';

  @override
  String get themeRetro => 'Retro';
}
