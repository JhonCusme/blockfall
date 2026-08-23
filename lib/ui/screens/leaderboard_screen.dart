/// Ranking global.
///
/// Se llega desde la pestaña "Global" de la pantalla de récords.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote_repository.dart';
import '../../game/game_engine.dart';
import '../../state/app_state.dart';
import '../../state/online_state.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';

class GlobalLeaderboard extends ConsumerWidget {
  final GameMode mode;

  const GlobalLeaderboard({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final t = L.of(context);

    if (!ref.watch(onlineAvailableProvider)) {
      return _message(
        theme,
        Icons.cloud_off_rounded,
        t.leaderboardOfflineTitle,
        t.leaderboardOfflineBody,
      );
    }

    // La pestaña fija el modo; el rango lo elige el jugador.
    final range = ref.watch(leaderboardRangeProvider);

    return Column(
      children: [
        _rangeSelector(ref, theme, t, range),
        Expanded(child: _list(context, ref, theme, t)),
      ],
    );
  }

  Widget _rangeSelector(
      WidgetRef ref, BlockTheme theme, L t, LeaderboardRange r) {
    final labels = {
      LeaderboardRange.today: t.rangeToday,
      LeaderboardRange.week: t.rangeWeek,
      LeaderboardRange.allTime: t.rangeAllTime,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final option in LeaderboardRange.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labels[option]!),
                selected: r == option,
                selectedColor: theme.accent,
                backgroundColor: theme.boardBackground,
                labelStyle: TextStyle(
                  color: r == option ? theme.background : theme.text,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) =>
                    ref.read(leaderboardRangeProvider.notifier).state = option,
              ),
            ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, BlockTheme theme, L t) {
    // La pestaña activa manda: se sincroniza el modo antes de leer.
    if (ref.read(leaderboardModeProvider) != mode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(leaderboardModeProvider.notifier).state = mode;
      });
    }

    final async = ref.watch(leaderboardProvider);
    final repo = ref.watch(remoteRepositoryProvider);
    final myUid = repo?.currentUser?.uid;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _message(
        theme,
        Icons.wifi_off_rounded,
        t.leaderboardErrorTitle,
        t.leaderboardErrorBody,
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return _message(
            theme,
            Icons.emoji_events_outlined,
            t.leaderboardEmptyTitle,
            t.leaderboardEmptyBody,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(leaderboardProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                Divider(color: theme.gridLine, height: 1),
            itemBuilder: (context, i) =>
                _row(theme, t, entries[i], i, entries[i].uid == myUid),
          ),
        );
      },
    );
  }

  Widget _row(
    BlockTheme theme,
    L t,
    LeaderboardEntry e,
    int index,
    bool isMe,
  ) {
    // El nombre viaja vacío cuando el jugador no puso ninguno: así cada quien
    // ve «Anónimo» o «Anonymous» en su idioma, en vez de la palabra del idioma
    // que tuviera puesto quien jugó.
    final nombre = e.name.isEmpty ? t.anonymous : e.name;
    // Las tres primeras posiciones se destacan; la del propio jugador
    // también, para encontrarse de un vistazo.
    final medal = switch (index) {
      0 => const Color(0xFFFFD34D),
      1 => const Color(0xFFC8CDD6),
      2 => const Color(0xFFCD8A54),
      _ => null,
    };

    return Container(
      color: isMe ? theme.accent.withValues(alpha: 0.12) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medal ?? theme.gridLine,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: medal != null ? Colors.black : theme.text,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          isMe ? t.leaderboardYou(nombre) : nombre,
          style: TextStyle(
            color: theme.text,
            fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          mode == GameMode.sprint
              ? t.leaderboardLines(e.lines)
              : t.leaderboardLinesLevel(e.lines, e.level),
          style: TextStyle(
            color: theme.text.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
        trailing: Text(
          mode == GameMode.sprint
              ? _formatTime(e.durationMs)
              : _formatScore(e.score),
          style: TextStyle(
            color: theme.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _message(
    BlockTheme theme,
    IconData icon,
    String title,
    String detail,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.text.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.text.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatScore(int score) {
    final s = score.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  static String _formatTime(int ms) {
    final totalSeconds = ms ~/ 1000;
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    final cs = (ms % 1000) ~/ 10;
    return '$m:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }
}
