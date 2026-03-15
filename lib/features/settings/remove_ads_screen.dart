import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/purchase_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_providers.dart';
import '../../shared/design_system.dart';

class RemoveAdsScreen extends ConsumerWidget {
  const RemoveAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final purchaseService = ref.watch(purchaseServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Remove Ads')),
      body: SafeArea(
        child: Padding(
          padding: IronRepSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(Icons.block, size: 80, color: c.accent),
              const SizedBox(height: IronRepSpacing.xl),
              Text('Remove Ads',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: IronRepSpacing.md),
              Text(
                'Enjoy an ad-free experience with a one-time purchase.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary),
              ),
              const SizedBox(height: IronRepSpacing.xxl),
              _FeatureRow(icon: Icons.block, text: 'No banner ads anywhere'),
              const SizedBox(height: IronRepSpacing.md),
              _FeatureRow(
                  icon: Icons.flash_on, text: 'Cleaner, faster experience'),
              const SizedBox(height: IronRepSpacing.md),
              _FeatureRow(
                  icon: Icons.favorite, text: 'Support indie development'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    purchaseService.onPurchased = () async {
                      final db = ref.read(databaseProvider);
                      await db.settingsDao
                          .setValue('ads_removed', 'true');
                      ref.invalidate(settingsProvider);
                      ref.invalidate(isAdsRemovedProvider);
                    };
                    await purchaseService.buyRemoveAds();
                  },
                  child: const Text('Buy for €2.99'),
                ),
              ),
              const SizedBox(height: IronRepSpacing.md),
              TextButton(
                onPressed: () async {
                  purchaseService.onPurchased = () async {
                    final db = ref.read(databaseProvider);
                    await db.settingsDao
                        .setValue('ads_removed', 'true');
                    ref.invalidate(settingsProvider);
                    ref.invalidate(isAdsRemovedProvider);
                  };
                  await purchaseService.restorePurchases();
                },
                child: Text('Restore Purchase',
                    style: TextStyle(color: c.textSecondary)),
              ),
              const SizedBox(height: IronRepSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Icon(icon, color: c.accent, size: 22),
        const SizedBox(width: 12),
        Text(text,
            style: TextStyle(color: c.textPrimary, fontSize: 16)),
      ],
    );
  }
}
