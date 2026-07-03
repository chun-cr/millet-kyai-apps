// 报告模块应用层对象：`PaymentResult`。承接跨页面流程和业务判断，避免页面直接堆叠复杂状态。

import 'package:flutter/foundation.dart';

enum PaymentResultStatus {
  unavailable,
  authorizedPendingServer,
  confirmed,
  failed,
  cancelled,
  mockSuccess,
}

@immutable
class PaymentResult {
  final PaymentResultStatus status;
  final String? sessionId;
  final String? paymentId;
  final String? orderId;
  final String? message;
  final bool isMock;

  const PaymentResult({
    required this.status,
    this.sessionId,
    this.paymentId,
    this.orderId,
    this.message,
    this.isMock = false,
  });

  bool get isSuccessful =>
      status == PaymentResultStatus.confirmed ||
      status == PaymentResultStatus.mockSuccess;
}
