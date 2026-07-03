// 报告模块应用层对象：`GooglePayService`。承接跨页面流程和业务判断，避免页面直接堆叠复杂状态。

import 'package:millet_kyai_apps/features/report/application/checkout_session.dart';
import 'package:millet_kyai_apps/features/report/application/payment_result.dart';

abstract class GooglePayService {
  Future<bool> isGooglePayAvailable();

  Future<PaymentResult> presentGooglePaySheet(CheckoutSession session);

  Future<void> prepareGooglePay();
}

class GooglePayServiceStub implements GooglePayService {
  final bool available;
  final String unavailableMessage;
  final String placeholderMessage;

  const GooglePayServiceStub({
    this.available = false,
    this.unavailableMessage = 'google-pay-not-configured',
    this.placeholderMessage = 'google-pay-placeholder-only',
  });

  @override
  Future<bool> isGooglePayAvailable() async => available;

  @override
  Future<void> prepareGooglePay() async {}

  @override
  Future<PaymentResult> presentGooglePaySheet(CheckoutSession session) async {
    return PaymentResult(
      status: PaymentResultStatus.unavailable,
      sessionId: session.sessionId,
      message: available ? placeholderMessage : unavailableMessage,
    );
  }
}
