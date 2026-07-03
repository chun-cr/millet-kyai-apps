// 报告模块应用层对象：`CheckoutSession`。承接跨页面流程和业务判断，避免页面直接堆叠复杂状态。

import 'package:flutter/foundation.dart';
import 'package:millet_kyai_apps/features/report/application/payment_method.dart';

enum CheckoutSessionStatus {
  pending,
  authorizedPendingServer,
  confirmed,
  failed,
}

@immutable
class CheckoutItem {
  final String itemId;
  final String title;
  final int quantity;
  final int unitPriceCents;

  const CheckoutItem({
    required this.itemId,
    required this.title,
    required this.quantity,
    required this.unitPriceCents,
  });

  int get subtotalCents => unitPriceCents * quantity;
}

@immutable
class CheckoutSession {
  final String sessionId;
  final List<CheckoutItem> items;
  final int subtotalCents;
  final int shippingFeeCents;
  final int serviceFeeCents;
  final int totalCents;
  final String currencyCode;
  final String countryCode;
  final Set<PaymentMethod> supportedPaymentMethods;
  final CheckoutSessionStatus status;

  const CheckoutSession({
    required this.sessionId,
    required this.items,
    required this.subtotalCents,
    required this.shippingFeeCents,
    required this.serviceFeeCents,
    required this.totalCents,
    required this.currencyCode,
    required this.countryCode,
    required this.supportedPaymentMethods,
    required this.status,
  });
}
