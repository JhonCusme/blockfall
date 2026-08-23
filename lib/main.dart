import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/local_repository.dart';
import 'data/remote_repository.dart';
import 'firebase_options.dart';
import 'services/ads_service.dart';
import 'services/audio_service.dart';
import 'state/app_state.dart';
import 'state/online_state.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/records_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/widgets/ad_banner.dart';
import 'game/game_engine.dart';
import 'ui/theme.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // El juego es vertical: en horizontal el tablero quedaría minúsculo.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Se abren antes de arrancar la app para que ninguna pantalla tenga que
  // enseñar un "cargando" por dos datos guardados.
  final repository = await LocalRepository.open();
  final audio = AudioService();
  await audio.init();

  // Los anuncios se inicializan en paralelo y sin esperar: si AdMob tarda o
  // no hay red, el juego debe abrir igual de rápido.
  final ads = AdsService()..premium = repository.isPremium;
  // Un anuncio a pantalla completa trae su propio audio: la música se calla
  // mientras dure y vuelve al terminar.
  ads.onFullScreenStart = audio.suspendMusic;
  ads.onFullScreenEnd = audio.resumeMusic;
  unawaited(ads.init());

  // La música arranca según lo que el jugador dejó guardado.
  unawaited(audio.setMusicEnabled(repository.loadSettings().musicEnabled));

  final remote = await _openFirebase();

  runApp(
    ProviderScope(
      overrides: [
        localRepositoryProvider.overrideWithValue(repository),
        audioServiceProvider.overrideWithValue(audio),
        adsServiceProvider.overrideWithValue(ads),
        remoteRepositoryProvider.overrideWithValue(remote),
      ],
      child: const BlockfallApp(),
    ),
  );
}

/// Arranca Firebase si hay configuración. Devuelve `null` si no la hay o si
/// falla, y en ese caso el juego funciona igual pero sin ranking global.
///
/// Nunca lanza: un problema de red o una configuración a medias no puede
/// impedir que la app abra.
Future<RemoteRepository?> _openFirebase() async {
  if (!DefaultFirebaseOptions.isConfigured) {
    debugPrint('Firebase sin configurar: el juego va en modo solo local.');
    return null;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final repo = RemoteRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
      await SharedPreferences.getInstance(),
    );
    // Se entra en segundo plano y se vacía la cola de puntuaciones que
    // quedaron sin subir; ninguna de las dos cosas debe frenar el arranque.
    unawaited(repo.ensureSignedIn().then((_) => repo.flushQueue()));
    return repo;
  } catch (e) {
    debugPrint('Firebase no arrancó, se sigue sin ranking: $e');
    return null;
  }
}

class BlockfallApp extends ConsumerStatefulWidget {
  const BlockfallApp({super.key});

  @override
  ConsumerState<BlockfallApp> createState() => _BlockfallAppState();
}

class _BlockfallAppState extends ConsumerState<BlockfallApp> {
  AppLifecycleListener? _lifecycle;

  /// Evita desbalancear el contador de suspensiones si el sistema manda dos
  /// avisos seguidos del mismo tipo.
  bool _suspendedByLifecycle = false;

  @override
  void initState() {
    super.initState();
    // Sin esto, la música seguiría sonando con el móvil bloqueado o al
    // cambiar de aplicación. Es el fallo más molesto que puede tener un juego
    // con música.
    _lifecycle = AppLifecycleListener(
      onPause: _suspend,
      onHide: _suspend,
      onRestart: _resume,
      onShow: _resume,
    );
  }

  void _suspend() {
    if (_suspendedByLifecycle) return;
    _suspendedByLifecycle = true;
    ref.read(audioServiceProvider).suspendMusic();
  }

  void _resume() {
    if (!_suspendedByLifecycle) return;
    _suspendedByLifecycle = false;
    ref.read(audioServiceProvider).resumeMusic();
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Blockfall',
      debugShowCheckedModeBanner: false,
      // `null` = seguir el idioma del teléfono. Si el jugador elige uno a mano
      // en Ajustes, ese manda.
      locale: ref.watch(localeProvider),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.accent,
          brightness: theme.id == 'light' ? Brightness.light : Brightness.dark,
        ),
        scaffoldBackgroundColor: theme.background,
        useMaterial3: true,
      ),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final repo = ref.watch(localRepositoryProvider);
    final best = repo.best(GameMode.marathon);
    final t = L.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      // El banner vive fuera del scroll, anclado abajo: así no se cuela
      // encima de ningún botón.
      bottomNavigationBar: const SafeArea(child: AdBanner()),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'BLOCKFALL',
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
                if (best != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      t.menuBest('${best.score}'),
                      style: TextStyle(
                        color: theme.text.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 36),
                _modeButton(context, theme, t.modeMarathon, GameMode.marathon),
                _modeButton(context, theme, t.modeSprint, GameMode.sprint),
                _modeButton(context, theme, t.modeUltra, GameMode.ultra),
                _modeButton(context, theme, t.modeZen, GameMode.zen),
                const SizedBox(height: 20),
                _linkButton(
                  context,
                  theme,
                  Icons.emoji_events_outlined,
                  t.menuRecords,
                  const RecordsScreen(),
                ),
                _linkButton(
                  context,
                  theme,
                  Icons.settings_outlined,
                  t.menuSettings,
                  const SettingsScreen(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(
      BuildContext context, BlockTheme theme, String label, GameMode mode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: theme.accent),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GameScreen(mode: mode)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _linkButton(BuildContext context, BlockTheme theme, IconData icon,
      String label, Widget screen) {
    return TextButton.icon(
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
      icon: Icon(icon, color: theme.text.withValues(alpha: 0.8), size: 20),
      label: Text(
        label,
        style: TextStyle(color: theme.text.withValues(alpha: 0.8)),
      ),
    );
  }
}
