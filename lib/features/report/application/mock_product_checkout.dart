// 报告模块应用层对象：`MockProductCheckout`。承接跨页面流程和业务判断，避免页面直接堆叠复杂状态。

import 'package:flutter/foundation.dart';
import 'package:millet_kyai_apps/features/report/application/checkout_session.dart';
import 'package:millet_kyai_apps/features/report/application/payment_method.dart';

@immutable
class OrderPreview {
  final int unitPriceCents;
  final int quantity;
  final int subtotalCents;
  final int shippingFeeCents;
  final int serviceFeeCents;
  final int totalCents;

  const OrderPreview({
    required this.unitPriceCents,
    required this.quantity,
    required this.subtotalCents,
    required this.shippingFeeCents,
    required this.serviceFeeCents,
    required this.totalCents,
  });
}

OrderPreview buildMockOrderPreview({
  required int unitPriceCents,
  required int quantity,
  int shippingFeeCents = 1200,
  int serviceFeeCents = 0,
}) {
  final subtotalCents = unitPriceCents * quantity;
  return OrderPreview(
    unitPriceCents: unitPriceCents,
    quantity: quantity,
    subtotalCents: subtotalCents,
    shippingFeeCents: shippingFeeCents,
    serviceFeeCents: serviceFeeCents,
    totalCents: subtotalCents + shippingFeeCents + serviceFeeCents,
  );
}

CheckoutSession buildMockCheckoutSession({
  required int unitPriceCents,
  required int quantity,
  int shippingFeeCents = 1200,
  int serviceFeeCents = 0,
  String sessionId = 'mock-checkout-session',
  String itemId = 'mock-product',
  String itemTitle = 'mock-product',
}) {
  final preview = buildMockOrderPreview(
    unitPriceCents: unitPriceCents,
    quantity: quantity,
    shippingFeeCents: shippingFeeCents,
    serviceFeeCents: serviceFeeCents,
  );

  return CheckoutSession(
    sessionId: sessionId,
    items: [
      CheckoutItem(
        itemId: itemId,
        title: itemTitle,
        quantity: quantity,
        unitPriceCents: unitPriceCents,
      ),
    ],
    subtotalCents: preview.subtotalCents,
    shippingFeeCents: preview.shippingFeeCents,
    serviceFeeCents: preview.serviceFeeCents,
    totalCents: preview.totalCents,
    currencyCode: 'CNY',
    countryCode: 'CN',
    supportedPaymentMethods: const {
      PaymentMethod.mock,
      PaymentMethod.applePay,
      PaymentMethod.googlePay,
    },
    status: CheckoutSessionStatus.pending,
  );
}

String formatPriceFromCents(int cents) {
  final yuan = cents ~/ 100;
  final fen = cents % 100;
  if (fen == 0) {
    return '¥$yuan';
  }
  return '¥$yuan.${fen.toString().padLeft(2, '0')}';
}
