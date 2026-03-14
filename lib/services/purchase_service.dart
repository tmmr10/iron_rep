import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

const _kRemoveAdsId = 'remove_ads';

class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  ProductDetails? _removeAdsProduct;

  bool get isAvailable => _isAvailable;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;

  void Function()? _onPurchased;
  set onPurchased(void Function()? callback) => _onPurchased = callback;

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate);

    final response = await _iap.queryProductDetails({_kRemoveAdsId});
    if (response.productDetails.isNotEmpty) {
      _removeAdsProduct = response.productDetails.first;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
      if (purchase.productID == _kRemoveAdsId &&
          purchase.status == PurchaseStatus.purchased) {
        _onPurchased?.call();
      }
    }
  }

  Future<bool> buyRemoveAds() async {
    if (_removeAdsProduct == null) return false;
    final param = PurchaseParam(productDetails: _removeAdsProduct!);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
