import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../l10n/l10n_helper.dart';

import '../../providers/purchase_providers.dart';
import '../../services/ad_service.dart';
import '../../utils/screenshot_tour.dart';

class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final adSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
          Orientation.portrait,
          width,
        ) ??
        AdSize.banner;
    if (!mounted) return;
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsRemoved = ref.watch(isAdsRemovedProvider).valueOrNull ?? false;
    final screenshotMode = ref.watch(screenshotModeProvider);
    if (adsRemoved || screenshotMode) return const SizedBox.shrink();

    // Real ad loaded — show it
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Reserve space — real ads fill this on device, placeholder in debug
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: kDebugMode
          ? Container(
              color: Colors.grey.withValues(alpha: 0.15),
              alignment: Alignment.center,
              child: Text(
                context.l10n.adLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            )
          : null,
    );
  }
}
