/// Guardado local: récords por modo y ajustes del jugador.
///
/// Usa `shared_preferences`, que basta de sobra: son unas pocas decenas de
/// valores. Una base de datos aquí sería complicarse sin motivo.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_engine.dart';

/// Una partida terminada, tal y como se guarda.
class ScoreRecord {
  final int score;
  final int lines;
  final int level;

  /// Duración en milisegundos. En Sprint es el dato que importa.
  final int durationMs;
  final DateTime date;

  const ScoreRecord({
    required this.score,
    required this.lines,
    required this.level,
    required this.durationMs,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'lines': lines,
        'level': level,
        'durationMs': durationMs,
        'date': date.toIso8601String(),
      };

  static ScoreRecord fromJson(Map<String, dynamic> json) => ScoreRecord(
        score: json['score'] as int? ?? 0,
        lines: json['lines'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        durationMs: json['durationMs'] as int? ?? 0,
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2000),
      );
}

/// Ajustes que el jugador puede cambiar.
class Settings {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final bool showGhost;
  final String themeId;

  /// `true` = botones en pantalla; `false` = solo gestos.
  final bool showButtons;

  /// Código de idioma elegido a mano: 'es' o 'en'.
  ///
  /// Cadena vacía = automático, es decir, seguir el idioma del teléfono. Es el
  /// valor por defecto: lo normal es que alguien quiera el juego en su idioma
  /// sin tener que configurar nada.
  final String languageCode;

  const Settings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.showGhost = true,
    this.themeId = 'dark',
    this.showButtons = true,
    this.languageCode = '',
  });

  Settings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    bool? showGhost,
    String? themeId,
    bool? showButtons,
    String? languageCode,
  }) =>
      Settings(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        showGhost: showGhost ?? this.showGhost,
        themeId: themeId ?? this.themeId,
        showButtons: showButtons ?? this.showButtons,
        languageCode: languageCode ?? this.languageCode,
      );
}

class LocalRepository {
  static const int _maxRecordsPerMode = 10;

  final SharedPreferences _prefs;

  LocalRepository(this._prefs);

  static Future<LocalRepository> open() async =>
      LocalRepository(await SharedPreferences.getInstance());

  // --- récords ---

  String _key(GameMode mode) => 'scores_${mode.name}';

  /// Las mejores partidas de un modo, ya ordenadas.
  List<ScoreRecord> records(GameMode mode) {
    final raw = _prefs.getStringList(_key(mode)) ?? const [];
    final list = raw
        .map((s) {
          try {
            return ScoreRecord.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            // Un registro corrupto no debe tirar la pantalla de récords.
            return null;
          }
        })
        .whereType<ScoreRecord>()
        .toList();
    _sort(mode, list);
    return list;
  }

  /// Guarda una partida y devuelve `true` si entró en el top.
  Future<bool> saveRecord(GameMode mode, ScoreRecord record) async {
    final list = records(mode)..add(record);
    _sort(mode, list);
    final top = list.take(_maxRecordsPerMode).toList();
    await _prefs.setStringList(
      _key(mode),
      top.map((r) => jsonEncode(r.toJson())).toList(),
    );
    return top.contains(record);
  }

  /// En Sprint gana quien tarda menos; en el resto, quien más puntúa.
  void _sort(GameMode mode, List<ScoreRecord> list) {
    if (mode == GameMode.sprint) {
      list.sort((a, b) {
        // Las partidas que no llegaron a 40 líneas van al final.
        final aDone = a.lines >= 40;
        final bDone = b.lines >= 40;
        if (aDone != bDone) return aDone ? -1 : 1;
        return a.durationMs.compareTo(b.durationMs);
      });
    } else {
      list.sort((a, b) => b.score.compareTo(a.score));
    }
  }

  ScoreRecord? best(GameMode mode) {
    final list = records(mode);
    return list.isEmpty ? null : list.first;
  }

  // --- premium ---

  /// ¿El jugador tiene la suscripción "sin anuncios"?
  ///
  /// Hoy es solo una marca local. Cuando exista la suscripción de verdad, la
  /// fuente de la verdad será Google Play Billing y este valor pasará a ser
  /// una caché de lo que diga la tienda: nunca al revés. Un archivo local se
  /// puede editar en un móvil rooteado, así que jamás debe ser la única
  /// comprobación una vez haya dinero de por medio.
  bool get isPremium => _prefs.getBool('isPremium') ?? false;

  Future<void> setPremium(bool value) => _prefs.setBool('isPremium', value);

  // --- ajustes ---

  Settings loadSettings() => Settings(
        soundEnabled: _prefs.getBool('soundEnabled') ?? true,
        musicEnabled: _prefs.getBool('musicEnabled') ?? true,
        vibrationEnabled: _prefs.getBool('vibrationEnabled') ?? true,
        showGhost: _prefs.getBool('showGhost') ?? true,
        themeId: _prefs.getString('themeId') ?? 'dark',
        showButtons: _prefs.getBool('showButtons') ?? true,
        languageCode: _prefs.getString('languageCode') ?? '',
      );

  Future<void> saveSettings(Settings s) async {
    await _prefs.setBool('soundEnabled', s.soundEnabled);
    await _prefs.setBool('musicEnabled', s.musicEnabled);
    await _prefs.setBool('vibrationEnabled', s.vibrationEnabled);
    await _prefs.setBool('showGhost', s.showGhost);
    await _prefs.setString('themeId', s.themeId);
    await _prefs.setBool('showButtons', s.showButtons);
    await _prefs.setString('languageCode', s.languageCode);
  }
}
