import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/purchase_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_providers.dart';
import '../../shared/design_system.dart';
import '../../l10n/l10n_helper.dart';

class RemoveAdsScreen extends ConsumerStatefulWidget {
  const RemoveAdsScreen({super.key});

  @override
  ConsumerState<RemoveAdsScreen> createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends ConsumerState<RemoveAdsScreen> {
  bool _isPurchasing = false;

  Future<void> _onPurchased() async {
    final db = ref.read(databaseProvider);
    await db.settingsDao.setValue('ads_removed', 'true');
    ref.invalidate(settingsProvider);
    ref.invalidate(isAdsRemovedProvider);
  }

  Future<void> _buy() async {
    final purchaseService = ref.read(purchaseServiceProvider);
    setState(() => _isPurchasing = true);
    purchaseService.onPurchased = _onPurchased;
    final success = await purchaseService.buyRemoveAds();
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.purchaseFailed),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _restore() async {
    final purchaseService = ref.read(purchaseServiceProvider);
    setState(() => _isPurchasing = true);
    purchaseService.onPurchased = _onPurchased;
    await purchaseService.restorePurchases();
    if (mounted) {
      setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: Padding(
          padding: IronRepSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(Icons.block, size: 80, color: c.accent),
              const SizedBox(height: IronRepSpacing.xl),
              Text(context.l10n.removeAds,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: IronRepSpacing.md),
              Text(
                context.l10n.adFreeDescription,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary),
              ),
              const SizedBox(height: IronRepSpacing.xxl),
              _FeatureRow(icon: Icons.block, text: context.l10n.noAdBanners),
              const SizedBox(height: IronRepSpacing.md),
              _FeatureRow(
                  icon: Icons.flash_on, text: context.l10n.fasterCleanerExperience),
              const SizedBox(height: IronRepSpacing.md),
              _FeatureRow(
                  icon: Icons.favorite, text: context.l10n.supportIndieDev),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPurchasing ? null : _buy,
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.buyForPrice('2,99 €')),
                ),
              ),
              const SizedBox(height: IronRepSpacing.md),
              TextButton(
                onPressed: _isPurchasing ? null : _restore,
                child: Text(context.l10n.restorePurchase,
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
