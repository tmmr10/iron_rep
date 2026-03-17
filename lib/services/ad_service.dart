import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // iOS Ad Units
  static const _bannerIdIos = 'ca-app-pub-6061884014427414/7349285909';
  static const _interstitialIdIos = 'ca-app-pub-6061884014427414/3250258790';

  // Android Ad Units
  static const _bannerIdAndroid = 'ca-app-pub-6061884014427414/7996692161';
  static const _interstitialIdAndroid = 'ca-app-pub-6061884014427414/8300744223';

  // Test Ad Units
  static const _bannerIdTest = 'ca-app-pub-3940256099942544/2435281174';
  static const _interstitialIdTest = 'ca-app-pub-3940256099942544/4411468910';

  static String get bannerId => kDebugMode
      ? _bannerIdTest
      : Platform.isIOS ? _bannerIdIos : _bannerIdAndroid;
  static String get interstitialId => kDebugMode
      ? _interstitialIdTest
      : Platform.isIOS ? _interstitialIdIos : _interstitialIdAndroid;

  static InterstitialAd? _interstitialAd;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  static void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  static void showInterstitial() {
    final ad = _interstitialAd;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
    _interstitialAd = null;
  }
}
