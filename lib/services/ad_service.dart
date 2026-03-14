import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    }
    return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
  }
}
