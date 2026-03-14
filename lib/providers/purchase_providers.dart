import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchase_service.dart';
import 'settings_providers.dart';

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

final isAdsRemovedProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(settingsProvider);
  return settings.whenOrNull(data: (s) => s.adsRemoved) ?? false;
});
