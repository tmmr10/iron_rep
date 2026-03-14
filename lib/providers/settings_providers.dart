import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import 'database_provider.dart';

class AppSettings {
  final WeightUnit weightUnit;
  final int defaultRestSeconds;
  final bool adsRemoved;

  const AppSettings({
    this.weightUnit = WeightUnit.kg,
    this.defaultRestSeconds = 90,
    this.adsRemoved = false,
  });
}

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  final db = ref.watch(databaseProvider);
  final dao = db.settingsDao;

  final unit = await dao.getValue('weight_unit');
  final rest = await dao.getValue('default_rest_seconds');
  final ads = await dao.getValue('ads_removed');

  return AppSettings(
    weightUnit: unit == 'lbs' ? WeightUnit.lbs : WeightUnit.kg,
    defaultRestSeconds: int.tryParse(rest ?? '') ?? 90,
    adsRemoved: ads == 'true',
  );
});

final weightUnitProvider = FutureProvider<WeightUnit>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return settings.weightUnit;
});
