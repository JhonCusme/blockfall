/// Ajustes: sonido, vibración, ayudas visuales, controles y tema.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote_repository.dart';
import '../../state/app_state.dart';
import '../../state/online_state.dart';
import '../widgets/ad_banner.dart';
import '../../l10n/app_localizations.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = ref.watch(themeProvider);
    final t = L.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      bottomNavigationBar: const SafeArea(child: AdBanner()),
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.text,
        title: Text(t.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _section(t.settingsSectionSound, theme),
          _switch(
            theme: theme,
            title: t.settingsSfx,
            value: settings.soundEnabled,
            onChanged: (_) => notifier.toggleSound(),
          ),
          _switch(
            theme: theme,
            title: t.settingsMusic,
            value: settings.musicEnabled,
            onChanged: (_) => notifier.toggleMusic(),
          ),
          _switch(
            theme: theme,
            title: t.settingsVibration,
            value: settings.vibrationEnabled,
            onChanged: (_) => notifier.toggleVibration(),
          ),
          _section(t.settingsSectionGame, theme),
          _switch(
            theme: theme,
            title: t.settingsGhost,
            subtitle: t.settingsGhostHint,
            value: settings.showGhost,
            onChanged: (_) => notifier.toggleGhost(),
          ),
          _switch(
            theme: theme,
            title: t.settingsButtons,
            subtitle: t.settingsButtonsHint,
            value: settings.showButtons,
            onChanged: (_) => notifier.toggleButtons(),
          ),
          if (ref.watch(onlineAvailableProvider)) ...[
            _section(t.settingsSectionOnline, theme),
            _NameField(theme: theme),
            _GoogleAccountTile(theme: theme),
          ],
          _section(t.settingsSectionLanguage, theme),
          // Cadena vacía = automático. Es el valor por defecto: quien no toque
          // nada verá el juego en el idioma de su teléfono.
          _option(
            theme: theme,
            title: t.languageAuto,
            subtitle: t.languageAutoHint,
            selected: settings.languageCode.isEmpty,
            onTap: () => notifier.setLanguage(''),
          ),
          _option(
            theme: theme,
            title: t.languageSpanish,
            selected: settings.languageCode == 'es',
            onTap: () => notifier.setLanguage('es'),
          ),
          _option(
            theme: theme,
            title: t.languageEnglish,
            selected: settings.languageCode == 'en',
            onTap: () => notifier.setLanguage('en'),
          ),
          _section(t.settingsSectionTheme, theme),
          for (final option in allThemes)
            _option(
              theme: theme,
              title: _themeName(t, option.id),
              selected: settings.themeId == option.id,
              onTap: () => notifier.setTheme(option.id),
              leading: _themePreview(option),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _themeName(L t, String id) => switch (id) {
        'light' => t.themeLight,
        'neon' => t.themeNeon,
        'retro' => t.themeRetro,
        _ => t.themeDark,
      };

  /// Fila seleccionable con marca de verificación, para idioma y tema.
  Widget _option({
    required BlockTheme theme,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
    Widget? leading,
  }) =>
      ListTile(
        onTap: onTap,
        leading: leading,
        title: Text(title, style: TextStyle(color: theme.text)),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(
                  color: theme.text.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: theme.accent)
            : Icon(
                Icons.circle_outlined,
                color: theme.text.withValues(alpha: 0.3),
              ),
      );

  /// Muestra los colores del tema en miniatura: se elige mejor viéndolo que
  /// leyendo el nombre.
  Widget _themePreview(BlockTheme t) {
    return Container(
      width: 56,
      height: 28,
      decoration: BoxDecoration(
        color: t.boardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: t.gridLine),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final c in t.pieces.values.take(4))
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(String title, BlockTheme theme) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: theme.accent,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _switch({
    required BlockTheme theme,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: theme.accent,
        title: Text(title, style: TextStyle(color: theme.text)),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(
                  color: theme.text.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
      );
}

/// Nombre con el que el jugador aparece en el ranking global.
///
/// Es un widget con estado propio porque un `TextField` necesita su
/// controlador, y guardar en cada pulsación de tecla sería una escritura a
/// disco por letra.
class _NameField extends ConsumerStatefulWidget {
  final BlockTheme theme;

  const _NameField({required this.theme});

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(playerNameProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() =>
      ref.read(playerNameProvider.notifier).setName(_controller.text);

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _controller,
        maxLength: 16,
        style: TextStyle(color: theme.text),
        // Se guarda al terminar de escribir, no en cada tecla.
        onEditingComplete: _save,
        onTapOutside: (_) {
          FocusScope.of(context).unfocus();
          _save();
        },
        decoration: InputDecoration(
          labelText: L.of(context).settingsNameLabel,
          helperText: L.of(context).settingsNameHint,
          labelStyle: TextStyle(color: theme.text.withValues(alpha: 0.7)),
          helperStyle: TextStyle(
            color: theme.text.withValues(alpha: 0.5),
            fontSize: 11,
          ),
          counterStyle: TextStyle(color: theme.text.withValues(alpha: 0.4)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.gridLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.accent),
          ),
        ),
      ),
    );
  }
}

/// Iniciar o cerrar sesión con Google.
///
/// Entrar con cuenta resuelve dos cosas que el modo anónimo no puede: el
/// historial sobrevive a cambiar de teléfono o reinstalar, y no caduca a los
/// 30 días de inactividad como sí hacen las cuentas anónimas.
/// Iniciar o cerrar sesión. Muestra Google siempre, y Apple solo en
/// iOS/macOS: ahí es obligatorio ofrecerlo en cuanto existe un botón de
/// Google (directriz 4.8 de Apple), y en Android no tendría sentido.
class _GoogleAccountTile extends ConsumerStatefulWidget {
  final BlockTheme theme;

  const _GoogleAccountTile({required this.theme});

  @override
  ConsumerState<_GoogleAccountTile> createState() => _GoogleAccountTileState();
}

class _GoogleAccountTileState extends ConsumerState<_GoogleAccountTile> {
  bool _busy = false;

  Future<void> _signIn(Future<SignInOutcome> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final outcome = await action();
    if (!mounted) return;
    setState(() => _busy = false);

    final t = L.of(context);
    final message = switch (outcome) {
      // Cancelar es una decisión del jugador, no un error: no se le avisa.
      SignInOutcome.cancelled || SignInOutcome.success => null,
      SignInOutcome.alreadyExisted => t.signInRestored,
      SignInOutcome.unsupported => t.signInNoServices,
      SignInOutcome.error => t.signInFailed,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signOut() async {
    final repo = ref.read(remoteRepositoryProvider);
    if (repo == null || _busy) return;
    setState(() => _busy = true);
    await repo.signOut();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final t = L.of(context);
    final repo = ref.read(remoteRepositoryProvider);
    final signedIn = ref.watch(isSignedInProvider);
    final name = ref.watch(accountNameProvider);

    if (_busy) {
      return const ListTile(
        title: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (signedIn) {
      return ListTile(
        leading: Icon(Icons.verified_user_outlined, color: theme.accent),
        title: Text(
          t.settingsSignedInAs(name ?? ''),
          style: TextStyle(color: theme.text),
        ),
        trailing: TextButton(
          onPressed: _signOut,
          child: Text(t.settingsSignOut),
        ),
      );
    }

    return Column(
      children: [
        ListTile(
          onTap: () => _signIn(() => repo!.signInWithGoogle()),
          leading: Icon(Icons.login_rounded, color: theme.accent),
          title: Text(t.settingsSignIn, style: TextStyle(color: theme.text)),
          subtitle: Text(
            t.settingsSignInHint,
            style: TextStyle(
              color: theme.text.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ),
        if (repo?.isAppleSignInAvailable ?? false)
          ListTile(
            onTap: () => _signIn(() => repo!.signInWithApple()),
            leading: Icon(Icons.apple, color: theme.text),
            title: Text(
              t.settingsSignInApple,
              style: TextStyle(color: theme.text),
            ),
          ),
      ],
    );
  }
}
