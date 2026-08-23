/// Estado del ranking online.
///
/// Todo aquí asume que Firebase puede no existir: mientras no esté
/// configurado, `remoteRepositoryProvider` vale `null` y la interfaz enseña un
/// aviso en vez de romperse.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote_repository.dart';
import '../game/game_engine.dart';

/// Se sobrescribe en `main()`. Vale `null` si Firebase no está configurado o
/// si su arranque falló.
final remoteRepositoryProvider = Provider<RemoteRepository?>((ref) => null);

bool _online(Ref ref) => ref.watch(remoteRepositoryProvider) != null;

/// ¿Se puede usar el ranking global?
final onlineAvailableProvider = Provider<bool>(_online);

/// Qué modo y qué ventana temporal está mirando el jugador.
final leaderboardModeProvider =
    StateProvider<GameMode>((ref) => GameMode.marathon);

final leaderboardRangeProvider =
    StateProvider<LeaderboardRange>((ref) => LeaderboardRange.allTime);

/// La consulta en sí. Riverpod la recalcula sola al cambiar modo o rango.
final leaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final repo = ref.watch(remoteRepositoryProvider);
  if (repo == null) return const [];
  return repo.topScores(
    mode: ref.watch(leaderboardModeProvider),
    range: ref.watch(leaderboardRangeProvider),
  );
});

/// Sesión actual. La interfaz se reconstruye sola al entrar o salir.
final authUserProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(remoteRepositoryProvider);
  if (repo == null) return const Stream<User?>.empty();
  return repo.userChanges;
});

/// ¿Hay sesión con cuenta de Google?
///
/// Se apoya en [authUserProvider] para recalcularse en cuanto cambia la
/// sesión, en vez de consultar el repositorio una sola vez.
final isSignedInProvider = Provider<bool>((ref) {
  ref.watch(authUserProvider);
  return ref.watch(remoteRepositoryProvider)?.isGoogleLinked ?? false;
});

final accountNameProvider = Provider<String?>((ref) {
  ref.watch(authUserProvider);
  return ref.watch(remoteRepositoryProvider)?.accountName;
});

/// Nombre público del jugador.
class PlayerNameNotifier extends StateNotifier<String> {
  final RemoteRepository? _repo;

  PlayerNameNotifier(this._repo) : super(_repo?.playerName ?? '');

  Future<void> setName(String name) async {
    if (_repo == null) return;
    await _repo.setPlayerName(name);
    state = _repo.playerName;
  }
}

final playerNameProvider =
    StateNotifierProvider<PlayerNameNotifier, String>((ref) {
  return PlayerNameNotifier(ref.watch(remoteRepositoryProvider));
});
