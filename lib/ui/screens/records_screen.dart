/// Récords locales, con una pestaña por modo.
///
/// El ranking global (Fase 4) se añadirá aquí como una pestaña más.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_repository.dart';
import '../../game/game_engine.dart';
import '../../state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/ad_banner.dart';
import 'leaderboard_screen.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  /// Zen no aparece: es un modo sin presión, puntuar ahí no significa nada.
  static const _modes = [GameMode.marathon, GameMode.sprint, GameMode.ultra];

  static String modeName(L t, GameMode mode) => switch (mode) {
        GameMode.sprint => t.modeSprintShort,
        GameMode.ultra => t.modeUltraShort,
        _ => t.modeMarathonShort,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final repo = ref.watch(localRepositoryProvider);
    final t = L.of(context);

    // Dos ejes: arriba local o global, debajo el modo. Se anidan dos
    // controladores de pestañas, uno por eje.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.background,
        bottomNavigationBar: const SafeArea(child: AdBanner()),
        appBar: AppBar(
          backgroundColor: theme.background,
          foregroundColor: theme.text,
          title: Text(t.recordsTitle),
          bottom: TabBar(
            labelColor: theme.accent,
            unselectedLabelColor: theme.text.withValues(alpha: 0.6),
            indicatorColor: theme.accent,
            tabs: [
              Tab(text: t.recordsLocalTab),
              Tab(text: t.recordsGlobalTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _byMode(theme, t,
                (mode) => _list(context, theme, repo.records(mode), mode)),
            _byMode(theme, t, (mode) => GlobalLeaderboard(mode: mode)),
          ],
        ),
      ),
    );
  }

  /// Sub-pestañas por modo, reutilizadas para local y global.
  Widget _byMode(BlockTheme theme, L t, Widget Function(GameMode) builder) {
    return DefaultTabController(
      length: _modes.length,
      child: Column(
        children: [
          TabBar(
            labelColor: theme.text,
            unselectedLabelColor: theme.text.withValues(alpha: 0.5),
            indicatorColor: theme.text.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontSize: 13),
            tabs: [for (final m in _modes) Tab(text: modeName(t, m))],
          ),
          Expanded(
            child: TabBarView(
              children: [for (final m in _modes) builder(m)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, BlockTheme theme,
      List<ScoreRecord> records, GameMode mode) {
    final t = L.of(context);
    if (records.isEmpty) {
      return Center(
        child: Text(
          t.recordsEmpty,
          style: TextStyle(color: theme.text.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      separatorBuilder: (_, __) => Divider(color: theme.gridLine, height: 1),
      itemBuilder: (context, i) {
        final r = records[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: i == 0 ? theme.accent : theme.gridLine,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: i == 0 ? theme.background : theme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // En Sprint lo que importa es el tiempo; en el resto, los puntos.
          title: Text(
            mode == GameMode.sprint ? _formatTime(r.durationMs) : '${r.score}',
            style: TextStyle(
              color: theme.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            mode == GameMode.sprint
                ? t.recordsLinesDate(r.lines, _formatDate(r.date))
                : t.recordsLinesLevelDate(
                    r.lines, r.level, _formatDate(r.date)),
            style: TextStyle(
              color: theme.text.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  static String _formatTime(int ms) {
    final totalSeconds = ms ~/ 1000;
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    final cs = (ms % 1000) ~/ 10;
    return '$m:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
