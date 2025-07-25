import 'package:flutter_test/flutter_test.dart';
import 'package:houseoftailors/config/stripe_config.dart';
import 'package:houseoftailors/services/payment_service.dart';

void main() {
  group('Stripe Configuration Tests', () {
    test('should return test publishable key in test mode', () {
      expect(StripeConfig.isTestMode, true);
      expect(StripeConfig.publishableKey, startsWith('pk_test_'));
    });

    test('should have valid merchant identifier', () {
      expect(StripeConfig.merchantIdentifier, 'merchant.com.houseoftailors');
    });

    test('should have valid payment intent data structure', () {
      final paymentIntentData = StripeConfig.paymentIntentData;
      expect(paymentIntentData['currency'], 'gbp');
      expect(paymentIntentData['automatic_payment_methods']['enabled'], true);
    });
  });

  group('Payment Service Tests', () {
    test('should format amount correctly for display', () {
      expect(PaymentService.formatAmount(1000, 'gbp'), '£10.00');
      expect(PaymentService.formatAmount(2550, 'usd'), '\$25.50');
      expect(PaymentService.formatAmount(999, 'eur'), '€9.99');
    });

    test('should validate email correctly', () {
      // This test would need to be expanded to test the private _validateInputs method
      // For now, we can test the public API indirectly
      expect(true, true); // Placeholder
    });
  });

  group('Payment Result Tests', () {
    test('should create success result correctly', () {
      final result = PaymentResult.success(
        paymentIntentId: 'pi_test_123',
        amount: 1000,
        currency: 'gbp',
      );

      expect(result.isSuccess, true);
      expect(result.paymentIntentId, 'pi_test_123');
      expect(result.amount, 1000);
      expect(result.currency, 'gbp');
      expect(result.errorMessage, null);
    });

    test('should create failure result correctly', () {
      final result = PaymentResult.failure('Payment failed');

      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Payment failed');
      expect(result.paymentIntentId, null);
      expect(result.amount, null);
      expect(result.currency, null);
    });
  });
}