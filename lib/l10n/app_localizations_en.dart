// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get modeMarathon => 'Marathon';

  @override
  String get modeSprint => 'Sprint · 40 lines';

  @override
  String get modeUltra => 'Ultra · 2 minutes';

  @override
  String get modeZen => 'Zen · endless';

  @override
  String get modeMarathonShort => 'Marathon';

  @override
  String get modeSprintShort => 'Sprint';

  @override
  String get modeUltraShort => 'Ultra';

  @override
  String get menuRecords => 'Records';

  @override
  String get menuSettings => 'Settings';

  @override
  String menuBest(String score) {
    return 'Your best: $score';
  }

  @override
  String get hudHold => 'Hold';

  @override
  String get hudNext => 'Next';

  @override
  String get hudScore => 'Score';

  @override
  String get hudLevel => 'Level';

  @override
  String get hudLines => 'Lines';

  @override
  String get hudRemaining => 'To go';

  @override
  String get hudTime => 'Time';

  @override
  String get hudCombo => 'Combo';

  @override
  String get hudPause => 'PAUSED';

  @override
  String get clearTetris => 'TETRIS!';

  @override
  String get clearTriple => 'TRIPLE';

  @override
  String get clearTSpin => 'T-SPIN';

  @override
  String get clearTSpinDouble => 'T-SPIN DOUBLE';

  @override
  String get clearTSpinTriple => 'T-SPIN TRIPLE';

  @override
  String get clearTSpinMini => 'T-SPIN MINI';

  @override
  String get gameOverTitle => 'Game over';

  @override
  String get gameCompletedTitle => 'Completed!';

  @override
  String gameOverScore(int score) {
    return 'Score: $score';
  }

  @override
  String gameOverLines(int lines) {
    return 'Lines: $lines';
  }

  @override
  String gameOverLevel(int level) {
    return 'Level: $level';
  }

  @override
  String get actionExit => 'Exit';

  @override
  String get actionRetry => 'Play again';

  @override
  String get reviveTitle => 'Keep playing?';

  @override
  String reviveBody(int score) {
    return 'Watch a video and carry on with the top cleared, keeping your $score points.';
  }

  @override
  String get reviveOnce => 'Once per game only.';

  @override
  String get reviveDecline => 'No, end it';

  @override
  String get reviveAccept => 'Watch video';

  @override
  String get recordsTitle => 'Records';

  @override
  String get recordsLocalTab => 'Your records';

  @override
  String get recordsGlobalTab => 'Global';

  @override
  String get recordsEmpty => 'You haven\'t played this mode yet';

  @override
  String recordsLinesDate(int lines, String date) {
    return '$lines lines · $date';
  }

  @override
  String recordsLinesLevelDate(int lines, int level, String date) {
    return '$lines lines · level $level · $date';
  }

  @override
  String get rangeToday => 'Today';

  @override
  String get rangeWeek => 'Week';

  @override
  String get rangeAllTime => 'All time';

  @override
  String get leaderboardOfflineTitle => 'Global ranking unavailable';

  @override
  String get leaderboardOfflineBody =>
      'The server isn\'t connected yet. Your local records are still being saved.';

  @override
  String get leaderboardErrorTitle => 'Couldn\'t load';

  @override
  String get leaderboardErrorBody =>
      'Check your connection and pull down to try again.';

  @override
  String get leaderboardEmptyTitle => 'Ranking empty';

  @override
  String get leaderboardEmptyBody =>
      'Nobody has scored in this period yet. You could be the first.';

  @override
  String leaderboardYou(String name) {
    return '$name  (you)';
  }

  @override
  String leaderboardLines(int lines) {
    return '$lines lines';
  }

  @override
  String leaderboardLinesLevel(int lines, int level) {
    return '$lines lines · level $level';
  }

  @override
  String get anonymous => 'Anonymous';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionSound => 'Sound';

  @override
  String get settingsSfx => 'Sound effects';

  @override
  String get settingsMusic => 'Music';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsSectionGame => 'Gameplay';

  @override
  String get settingsGhost => 'Ghost piece';

  @override
  String get settingsGhostHint => 'Shows where the piece will land';

  @override
  String get settingsButtons => 'On-screen buttons';

  @override
  String get settingsButtonsHint => 'Turn off to play with gestures only';

  @override
  String get settingsSectionOnline => 'Global ranking';

  @override
  String get settingsNameLabel => 'Your name on the ranking';

  @override
  String get settingsNameHint => 'Leave it empty to appear as \"Anonymous\"';

  @override
  String get settingsSignIn => 'Sign in with Google';

  @override
  String get settingsSignInApple => 'Sign in with Apple';

  @override
  String get settingsSignInHint =>
      'Keeps your records if you switch phones or reinstall';

  @override
  String settingsSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get signInFailed => 'Couldn\'t sign in. Please try again.';

  @override
  String get signInNoServices => 'This device doesn\'t have Google services.';

  @override
  String get signInRestored => 'We restored that account\'s history.';

  @override
  String get settingsSectionTheme => 'Theme';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get languageAuto => 'Automatic';

  @override
  String get languageAutoHint => 'Follows your phone\'s language';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeNeon => 'Neon';

  @override
  String get themeRetro => 'Retro';
}
