import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/report/application/checkout_session.dart';
import 'package:millet_kyai_apps/features/report/application/google_pay_service.dart';
import 'package:millet_kyai_apps/features/report/application/payment_method.dart';
import 'package:millet_kyai_apps/features/report/application/payment_result.dart';

void main() {
  group('GooglePayServiceStub', () {
    test('reports unavailable by default', () async {
      final service = GooglePayServiceStub();

      expect(await service.isGooglePayAvailable(), isFalse);
    });

    test('returns placeholder result without real payment identifiers', () async {
      final service = GooglePayServiceStub();
      final session = CheckoutSession(
        sessionId: 'mock-session',
        items: const [
          CheckoutItem(
            itemId: 'demo-kit',
            title: 'Demo Kit',
            quantity: 1,
            unitPriceCents: 39900,
          ),
        ],
        subtotalCents: 39900,
        shippingFeeCents: 1200,
        serviceFeeCents: 0,
        totalCents: 41100,
        currencyCode: 'CNY',
        countryCode: 'CN',
        supportedPaymentMethods: const {
          PaymentMethod.googlePay,
        },
        status: CheckoutSessionStatus.pending,
      );

      final result = await service.presentGooglePaySheet(session);

      expect(result.status, PaymentResultStatus.unavailable);
      expect(result.sessionId, 'mock-session');
      expect(result.paymentId, isNull);
      expect(result.orderId, isNull);
      expect(result.isMock, isFalse);
      expect(result.message, 'google-pay-not-configured');
    });

    test('keeps placeholder semantics even if availability is toggled on', () async {
      final service = GooglePayServiceStub(available: true);
      final session = CheckoutSession(
        sessionId: 'mock-session',
        items: const [
          CheckoutItem(
            itemId: 'demo-kit',
            title: 'Demo Kit',
            quantity: 1,
            unitPriceCents: 39900,
          ),
        ],
        subtotalCents: 39900,
        shippingFeeCents: 1200,
        serviceFeeCents: 0,
        totalCents: 41100,
        currencyCode: 'CNY',
        countryCode: 'CN',
        supportedPaymentMethods: const {
          PaymentMethod.googlePay,
        },
        status: CheckoutSessionStatus.pending,
      );

      final result = await service.presentGooglePaySheet(session);

      expect(result.status, PaymentResultStatus.unavailable);
      expect(result.sessionId, 'mock-session');
      expect(result.paymentId, isNull);
      expect(result.orderId, isNull);
      expect(result.message, 'google-pay-placeholder-only');
    });
  });
}
