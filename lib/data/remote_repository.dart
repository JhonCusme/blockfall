/// Ranking global sobre Firebase.
///
/// Diseño en dos ideas:
///
///  1. **Nunca bloquea el juego.** Si no hay red, si Firebase no está
///     configurado o si la consulta falla, el juego sigue igual y las
///     puntuaciones se guardan en una cola local para subirlas después.
///
///  2. **El cliente no es de fiar.** Cualquiera puede modificar un APK y
///     mandar un millón de puntos. Aquí se filtra lo imposible antes de
///     enviarlo, y las reglas de Firestore repiten la comprobación en el
///     servidor. Ver `firestore.rules`.
library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../game/game_engine.dart';

/// Una entrada del ranking global.
class LeaderboardEntry {
  final String id;
  final String uid;
  final String name;
  final int score;
  final int lines;
  final int level;
  final int durationMs;
  final DateTime date;

  const LeaderboardEntry({
    required this.id,
    required this.uid,
    required this.name,
    required this.score,
    required this.lines,
    required this.level,
    required this.durationMs,
    required this.date,
  });

  static LeaderboardEntry? fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    if (d == null) return null;
    final ts = d['date'];
    return LeaderboardEntry(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      // Puede venir vacío. La interfaz lo sustituye por «Anónimo» en el
      // idioma de quien mira, no en el de quien jugó.
      name: d['name'] as String? ?? '',
      score: (d['score'] as num?)?.toInt() ?? 0,
      lines: (d['lines'] as num?)?.toInt() ?? 0,
      level: (d['level'] as num?)?.toInt() ?? 1,
      durationMs: (d['durationMs'] as num?)?.toInt() ?? 0,
      date: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

/// Cómo terminó un intento de iniciar sesión con Google.
enum SignInOutcome {
  /// Entró y conservó el historial anónimo.
  success,

  /// Entró, pero esa cuenta de Google ya tenía historial propio: se usa ese
  /// y se abandona el anónimo de este dispositivo.
  alreadyExisted,

  /// El jugador cerró el selector de cuentas.
  cancelled,

  /// El dispositivo no tiene servicios de Google.
  unsupported,

  error,
}

/// Ventana temporal del ranking.
enum LeaderboardRange { today, week, allTime }

/// Comprueba si una puntuación es físicamente alcanzable.
///
/// No pretende detectar a un tramposo hábil —eso exigiría revalidar la partida
/// entera en el servidor—, sino descartar los valores absurdos que manda
/// cualquiera que edite el APK sin esforzarse.
class ScoreValidator {
  const ScoreValidator._();

  /// Techo teórico por línea, generoso: un Tetris con back-to-back en nivel
  /// alto más combo no llega ni de lejos a esto.
  static const int _maxPointsPerLine = 5000;

  /// Nadie coloca una pieza en menos de 100 ms de forma sostenida, y cada
  /// línea necesita al menos dos piezas y media.
  static const int _minMsPerLine = 250;

  /// Motivo del rechazo, o `null` si la puntuación es plausible.
  static String? reject({
    required int score,
    required int lines,
    required int level,
    required int durationMs,
  }) {
    if (score < 0 || lines < 0 || level < 1) return 'valores negativos';
    if (score == 0) return 'sin puntuación';

    // Sin líneas solo se puede puntuar con caídas: muy poquito.
    if (lines == 0 && score > 2000) return 'puntos sin líneas';

    if (lines > 0 && score > lines * _maxPointsPerLine) {
      return 'demasiados puntos para $lines líneas';
    }

    // El nivel sube cada 10 líneas y arranca en 1.
    if (level > (lines ~/ 10) + 1) return 'nivel imposible para $lines líneas';

    if (durationMs < lines * _minMsPerLine) {
      return 'demasiado rápido para $lines líneas';
    }

    // Una partida de más de 12 horas es un reloj manipulado.
    if (durationMs > 12 * 60 * 60 * 1000) return 'duración imposible';

    return null;
  }
}

class RemoteRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final SharedPreferences _prefs;

  RemoteRepository(this._db, this._auth, this._prefs);

  static const _queueKey = 'pendingScores';
  static const _nameKey = 'playerName';

  /// Cuántas entradas trae cada consulta del ranking.
  static const int pageSize = 50;

  User? get currentUser => _auth.currentUser;

  /// Nombre con el que aparece el jugador. Se puede cambiar en Ajustes.
  String get playerName => _prefs.getString(_nameKey) ?? '';

  Future<void> setPlayerName(String name) =>
      _prefs.setString(_nameKey, _sanitizeName(name));

  /// Recorta y limpia el nombre antes de que llegue a la nube.
  ///
  /// Un nombre larguísimo rompería el diseño de la lista, y los saltos de
  /// línea permitirían falsificar varias filas visualmente.
  static String _sanitizeName(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return '';
    return clean.length <= 16 ? clean : clean.substring(0, 16);
  }

  /// Cambios de sesión, para que la interfaz se entere de inmediato.
  Stream<User?> get userChanges => _auth.userChanges();

  /// ¿La sesión actual está vinculada a una cuenta de Google?
  bool get isGoogleLinked =>
      _auth.currentUser?.providerData
          .any((p) => p.providerId == 'google.com') ??
      false;

  String? get accountName =>
      _auth.currentUser?.displayName ?? _auth.currentUser?.email;

  bool _googleReady = false;

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: googleServerClientId,
    );
    _googleReady = true;
  }

  /// Entra con Google y conserva las puntuaciones ya conseguidas.
  ///
  /// La gracia está en `linkWithCredential`: en vez de crear una cuenta nueva,
  /// **asciende la cuenta anónima actual** a cuenta de Google conservando el
  /// mismo uid. Así el historial no se pierde al iniciar sesión.
  Future<SignInOutcome> signInWithGoogle() async {
    try {
      await _initGoogle();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return SignInOutcome.unsupported;
      }

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        debugPrint('Google no devolvió idToken');
        return SignInOutcome.error;
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final current = _auth.currentUser;
      if (current != null && current.isAnonymous) {
        try {
          await current.linkWithCredential(credential);
          await _adoptGoogleName();
          return SignInOutcome.success;
        } on FirebaseAuthException catch (e) {
          // Esa cuenta de Google ya se usó antes en otro dispositivo. No se
          // pueden fusionar dos historiales, así que se entra con la cuenta
          // que ya existía: es la que el jugador considera suya.
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            await _auth.signInWithCredential(credential);
            await _adoptGoogleName();
            return SignInOutcome.alreadyExisted;
          }
          rethrow;
        }
      }

      await _auth.signInWithCredential(credential);
      await _adoptGoogleName();
      return SignInOutcome.success;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return SignInOutcome.cancelled;
      }
      debugPrint('Google Sign-In falló: ${e.code} ${e.description}');
      return SignInOutcome.error;
    } catch (e) {
      debugPrint('Google Sign-In falló: $e');
      return SignInOutcome.error;
    }
  }

  /// Si el jugador no había puesto nombre, se toma el de Google.
  ///
  /// Solo el primer nombre: el ranking es público y no procede exponer el
  /// apellido de nadie sin que lo haya decidido.
  Future<void> _adoptGoogleName() async {
    if (playerName.isNotEmpty) return;
    final full = _auth.currentUser?.displayName?.trim() ?? '';
    if (full.isEmpty) return;
    await setPlayerName(full.split(' ').first);
  }

  /// Cierra la sesión de Google y vuelve a una cuenta anónima nueva, para que
  /// el ranking siga funcionando.
  Future<void> signOutGoogle() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Que falle el cierre en el lado de Google no debe impedir salir.
    }
    await _auth.signOut();
    await ensureSignedIn();
  }

  /// Entra de forma anónima. Es suficiente para tener un identificador estable
  /// por instalación sin pedirle nada al jugador.
  Future<User?> ensureSignedIn() async {
    try {
      if (_auth.currentUser != null) return _auth.currentUser;
      final cred = await _auth.signInAnonymously();
      return cred.user;
    } catch (e) {
      debugPrint('No se pudo iniciar sesión anónima: $e');
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>> _scores(GameMode mode) =>
      _db.collection('leaderboards').doc(mode.name).collection('scores');

  /// Sube una puntuación. Si no hay red, la deja en la cola local.
  ///
  /// Devuelve `true` si llegó al servidor.
  Future<bool> submitScore({
    required GameMode mode,
    required int score,
    required int lines,
    required int level,
    required int durationMs,
  }) async {
    final reason = ScoreValidator.reject(
      score: score,
      lines: lines,
      level: level,
      durationMs: durationMs,
    );
    if (reason != null) {
      debugPrint('Puntuación no enviada ($reason)');
      return false;
    }

    final payload = {
      'mode': mode.name,
      'score': score,
      'lines': lines,
      'level': level,
      'durationMs': durationMs,
    };

    try {
      final user = await ensureSignedIn();
      if (user == null) {
        _enqueue(payload);
        return false;
      }
      await _scores(mode).add({
        ...payload,
        'uid': user.uid,
        // Vacío si no puso nombre: cada jugador verá «Anónimo» traducido a su
        // idioma en lugar del idioma de quien jugó.
        'name': playerName,
        // La fecha la pone el servidor: si la pusiera el móvil, bastaría con
        // cambiar la hora del sistema para colarse en el ranking de hoy.
        'date': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Envío fallido, se guarda en cola: $e');
      _enqueue(payload);
      return false;
    }
  }

  // --- cola de pendientes ---

  void _enqueue(Map<String, dynamic> payload) {
    final queue = _prefs.getStringList(_queueKey) ?? <String>[];
    // Un tope para que la cola no crezca sin límite jugando meses sin red.
    if (queue.length >= 50) queue.removeAt(0);
    queue.add(jsonEncode(payload));
    _prefs.setStringList(_queueKey, queue);
  }

  int get pendingCount => (_prefs.getStringList(_queueKey) ?? const []).length;

  /// Intenta subir lo que quedó pendiente. Se llama al arrancar y al volver
  /// la conexión.
  Future<int> flushQueue() async {
    final queue = _prefs.getStringList(_queueKey) ?? <String>[];
    if (queue.isEmpty) return 0;

    final user = await ensureSignedIn();
    if (user == null) return 0;

    final failed = <String>[];
    var sent = 0;

    for (final raw in queue) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final mode = GameMode.values.firstWhere(
          (m) => m.name == data['mode'],
          orElse: () => GameMode.marathon,
        );
        await _scores(mode).add({
          ...data,
          'uid': user.uid,
          // Vacío si no puso nombre: cada jugador verá «Anónimo» traducido a su
          // idioma en lugar del idioma de quien jugó.
          'name': playerName,
          'date': FieldValue.serverTimestamp(),
        });
        sent++;
      } catch (_) {
        failed.add(raw);
      }
    }

    await _prefs.setStringList(_queueKey, failed);
    return sent;
  }

  // --- consulta ---

  DateTime? _since(LeaderboardRange range) => switch (range) {
        LeaderboardRange.today =>
          DateTime.now().subtract(const Duration(days: 1)),
        LeaderboardRange.week =>
          DateTime.now().subtract(const Duration(days: 7)),
        LeaderboardRange.allTime => null,
      };

  /// Las mejores puntuaciones de un modo.
  ///
  /// En Sprint gana quien menos tarda, así que se ordena al revés y solo
  /// cuentan las partidas que llegaron a 40 líneas.
  Future<List<LeaderboardEntry>> topScores({
    required GameMode mode,
    required LeaderboardRange range,
  }) async {
    Query<Map<String, dynamic>> query = _scores(mode);

    final since = _since(range);
    if (since != null) {
      query = query.where('date', isGreaterThan: Timestamp.fromDate(since));
    }

    if (mode == GameMode.sprint) {
      query = query
          .where('lines', isGreaterThanOrEqualTo: 40)
          .orderBy('durationMs');
    } else {
      query = query.orderBy('score', descending: true);
    }

    final snap = await query.limit(pageSize).get();
    return snap.docs
        .map(LeaderboardEntry.fromDoc)
        .whereType<LeaderboardEntry>()
        .toList();
  }
}
