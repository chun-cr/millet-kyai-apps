import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/report/application/mock_product_checkout.dart';
import 'package:millet_kyai_apps/features/report/application/payment_method.dart';

void main() {
  group('buildMockOrderPreview', () {
    test('calculates subtotal and total with default shipping', () {
      final preview = buildMockOrderPreview(
        unitPriceCents: 5800,
        quantity: 2,
      );

      expect(preview.subtotalCents, 11600);
      expect(preview.shippingFeeCents, 1200);
      expect(preview.serviceFeeCents, 0);
      expect(preview.totalCents, 12800);
    });

    test('formats cents to price label safely', () {
      expect(formatPriceFromCents(8900), '¥89');
      expect(formatPriceFromCents(2990), '¥29.90');
    });
  });

  group('buildMockCheckoutSession', () {
    test('builds a pending checkout session with supported payment methods', () {
      final session = buildMockCheckoutSession(
        unitPriceCents: 5800,
        quantity: 2,
      );

      expect(session.subtotalCents, 11600);
      expect(session.shippingFeeCents, 1200);
      expect(session.serviceFeeCents, 0);
      expect(session.totalCents, 12800);
      expect(session.currencyCode, 'CNY');
      expect(session.countryCode, 'CN');
      expect(session.supportedPaymentMethods, contains(PaymentMethod.mock));
      expect(session.supportedPaymentMethods, contains(PaymentMethod.applePay));
      expect(session.supportedPaymentMethods, contains(PaymentMethod.googlePay));
    });
  });
}
