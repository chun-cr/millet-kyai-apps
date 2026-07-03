// 报告模块应用层对象：`ReportUnlockService`。承接跨页面流程和业务判断，避免页面直接堆叠复杂状态。

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const reportUnlockProductId = String.fromEnvironment(
  'REPORT_UNLOCK_PRODUCT_ID',
  defaultValue: 'report_unlock_full',
);

const _reportUnlockPreferenceKey = 'report_unlock_entitlement';

enum ReportUnlockStatus {
  unknown,
  locked,
  unavailable,
  purchasing,
  restoring,
  unlocked,
  error,
}

@immutable
class ReportUnlockState {
  final ReportUnlockStatus status;
  final bool isStoreAvailable;
  final ProductDetails? productDetails;
  final String? message;
  final DateTime? lastVerifiedAt;

  const ReportUnlockState({
    required this.status,
    required this.isStoreAvailable,
    this.productDetails,
    this.message,
    this.lastVerifiedAt,
  });

  const ReportUnlockState.unknown()
      : this(status: ReportUnlockStatus.unknown, isStoreAvailable: false);

  bool get isUnlocked => status == ReportUnlockStatus.unlocked;
  bool get isBusy =>
      status == ReportUnlockStatus.purchasing ||
      status == ReportUnlockStatus.restoring;

  String? get displayPrice => productDetails?.price;

  ReportUnlockState copyWith({
    ReportUnlockStatus? status,
    bool? isStoreAvailable,
    ProductDetails? productDetails,
    bool clearProductDetails = false,
    String? message,
    bool clearMessage = false,
    DateTime? lastVerifiedAt,
    bool clearLastVerifiedAt = false,
  }) {
    return ReportUnlockState(
      status: status ?? this.status,
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      productDetails: clearProductDetails
          ? null
          : (productDetails ?? this.productDetails),
      message: clearMessage ? null : (message ?? this.message),
      lastVerifiedAt: clearLastVerifiedAt
          ? null
          : (lastVerifiedAt ?? this.lastVerifiedAt),
    );
  }
}

class ReportUnlockService {
  ReportUnlockService({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase;

  InAppPurchase? _inAppPurchase;
  final ValueNotifier<ReportUnlockState> state =
      ValueNotifier(const ReportUnlockState.unknown());

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Timer? _restoreTimeoutTimer;
  ProductDetails? _productDetails;
  bool _initialized = false;
  bool _restoreTriggered = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final preferences = await SharedPreferences.getInstance();
    final cachedUnlocked =
        preferences.getBool(_reportUnlockPreferenceKey) ?? false;
    final cachedVerifiedMillis =
        preferences.getInt('${_reportUnlockPreferenceKey}_verified_at');
    final cachedVerifiedAt = cachedVerifiedMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(cachedVerifiedMillis);

    final inAppPurchase = _resolveInAppPurchase();

    if (inAppPurchase == null) {
      _setState(
        ReportUnlockState(
          status: cachedUnlocked
              ? ReportUnlockStatus.unlocked
              : ReportUnlockStatus.unavailable,
          isStoreAvailable: false,
          productDetails: null,
          message: cachedUnlocked ? null : 'store-unavailable',
          lastVerifiedAt: cachedVerifiedAt,
        ),
      );
      return;
    }

    _purchaseSubscription = inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        _setState(
          state.value.copyWith(
            status: _resolveLockedOrUnlockedStatus(),
            message: 'purchase-stream-error',
            clearLastVerifiedAt: !state.value.isUnlocked,
          ),
        );
      },
    );

    final isStoreAvailable = await inAppPurchase.isAvailable();

    if (!isStoreAvailable) {
      _setState(
        ReportUnlockState(
          status: cachedUnlocked
              ? ReportUnlockStatus.unlocked
              : ReportUnlockStatus.unavailable,
          isStoreAvailable: false,
          productDetails: null,
          message: cachedUnlocked ? null : 'store-unavailable',
          lastVerifiedAt: cachedVerifiedAt,
        ),
      );
      return;
    }

    final response = await inAppPurchase.queryProductDetails({
      reportUnlockProductId,
    });

    if (response.productDetails.isNotEmpty) {
      _productDetails = response.productDetails.first;
    }

    final hasProduct = _productDetails != null;
    _setState(
      ReportUnlockState(
        status: cachedUnlocked
            ? ReportUnlockStatus.unlocked
            : (hasProduct
                ? ReportUnlockStatus.locked
                : ReportUnlockStatus.unavailable),
        isStoreAvailable: true,
        productDetails: _productDetails,
        message: hasProduct ? null : 'product-not-found',
        lastVerifiedAt: cachedVerifiedAt,
      ),
    );
  }

  Future<void> purchase() async {
    if (state.value.isBusy || state.value.isUnlocked) {
      return;
    }

    final inAppPurchase = _inAppPurchase;

    if (!state.value.isStoreAvailable || inAppPurchase == null) {
      _setState(
        state.value.copyWith(
          status: ReportUnlockStatus.error,
          message: 'store-unavailable',
        ),
      );
      return;
    }

    if (_productDetails == null) {
      _setState(
        state.value.copyWith(
          status: ReportUnlockStatus.error,
          message: 'product-not-found',
        ),
      );
      return;
    }

    _setState(
      state.value.copyWith(
        status: ReportUnlockStatus.purchasing,
        clearMessage: true,
      ),
    );

    final launched = await inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: _productDetails!),
    );

    if (!launched) {
      _setState(
        state.value.copyWith(
          status: _resolveLockedOrUnlockedStatus(),
          message: 'purchase-launch-failed',
        ),
      );
    }
  }

  Future<void> restore() async {
    if (state.value.isBusy) {
      return;
    }

    final inAppPurchase = _inAppPurchase;

    if (!state.value.isStoreAvailable || inAppPurchase == null) {
      _setState(
        state.value.copyWith(
          status: ReportUnlockStatus.error,
          message: 'store-unavailable',
        ),
      );
      return;
    }

    _restoreTriggered = true;
    _restoreTimeoutTimer?.cancel();
    _setState(
      state.value.copyWith(
        status: ReportUnlockStatus.restoring,
        clearMessage: true,
      ),
    );

    await inAppPurchase.restorePurchases();

    _restoreTimeoutTimer = Timer(const Duration(seconds: 12), () {
      if (state.value.status == ReportUnlockStatus.restoring) {
        _restoreTriggered = false;
        _setState(
          state.value.copyWith(
            status: _resolveLockedOrUnlockedStatus(),
            message: 'restore-not-found',
          ),
        );
      }
    });
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    final inAppPurchase = _inAppPurchase;

    if (inAppPurchase == null) {
      return;
    }

    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.productID != reportUnlockProductId) {
        if (purchaseDetails.pendingCompletePurchase) {
          await inAppPurchase.completePurchase(purchaseDetails);
        }
        continue;
      }

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _setState(
            state.value.copyWith(
              status: _restoreTriggered
                  ? ReportUnlockStatus.restoring
                  : ReportUnlockStatus.purchasing,
              clearMessage: true,
            ),
          );
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _persistUnlocked();
          _restoreTriggered = false;
          _restoreTimeoutTimer?.cancel();
          _setState(
            state.value.copyWith(
              status: ReportUnlockStatus.unlocked,
              productDetails: _productDetails,
              clearMessage: true,
              lastVerifiedAt: DateTime.now(),
            ),
          );
          break;
        case PurchaseStatus.error:
          _restoreTriggered = false;
          _restoreTimeoutTimer?.cancel();
          _setState(
            state.value.copyWith(
              status: _resolveLockedOrUnlockedStatus(),
              message: _normalizeErrorCode(purchaseDetails.error?.code),
            ),
          );
          break;
        case PurchaseStatus.canceled:
          _restoreTriggered = false;
          _restoreTimeoutTimer?.cancel();
          _setState(
            state.value.copyWith(
              status: _resolveLockedOrUnlockedStatus(),
              message: 'purchase-cancelled',
            ),
          );
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  InAppPurchase? _resolveInAppPurchase() {
    final current = _inAppPurchase;

    if (current != null) {
      return current;
    }

    if (!_supportsStorePlatform) {
      return null;
    }

    final inAppPurchase = InAppPurchase.instance;
    _inAppPurchase = inAppPurchase;
    return inAppPurchase;
  }

  bool get _supportsStorePlatform {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => false,
    };
  }

  Future<void> _persistUnlocked() async {
    final preferences = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await preferences.setBool(_reportUnlockPreferenceKey, true);
    await preferences.setInt(
      '${_reportUnlockPreferenceKey}_verified_at',
      now.millisecondsSinceEpoch,
    );
  }

  ReportUnlockStatus _resolveLockedOrUnlockedStatus() {
    return state.value.isUnlocked
        ? ReportUnlockStatus.unlocked
        : ReportUnlockStatus.locked;
  }

  String _normalizeErrorCode(String? code) {
    if (code == null || code.isEmpty) {
      return 'purchase-failed';
    }
    return code;
  }

  void _setState(ReportUnlockState next) {
    state.value = next;
  }

  Future<void> dispose() async {
    _restoreTimeoutTimer?.cancel();
    await _purchaseSubscription?.cancel();
    state.dispose();
  }
}
