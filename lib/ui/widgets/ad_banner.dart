/// Banner de AdMob para menús y pausa.
///
/// Nunca se pone en la pantalla de juego activa: en un juego de precisión, un
/// anuncio al alcance del pulgar provoca clics accidentales, y Google penaliza
/// esos clics como tráfico inválido.
///
/// Mientras el anuncio no ha cargado —o si nunca carga— el widget ocupa cero:
/// nada de huecos grises ni de "publicidad" escrita a mano.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../state/app_state.dart';

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Se crea tras el primer frame: durante initState todavía no se puede
    // leer con seguridad el estado de premium.
    WidgetsBinding.instance.addPostFrameCallback((_) => _create());
  }

  Future<void> _create() async {
    if (!mounted || ref.read(premiumProvider)) return;

    // Hay que esperar a que el SDK arranque: si se pide el banner antes, la
    // petición se descarta y el hueco se queda vacío para siempre.
    final ads = ref.read(adsServiceProvider);
    await ads.ready;
    if (!mounted || ref.read(premiumProvider)) return;

    final ad = ads.createBanner(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
    );
    if (ad != null) _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si se hace premium mientras el banner está en pantalla, desaparece.
    final premium = ref.watch(premiumProvider);
    if (premium) {
      _ad?.dispose();
      _ad = null;
      return const SizedBox.shrink();
    }

    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
