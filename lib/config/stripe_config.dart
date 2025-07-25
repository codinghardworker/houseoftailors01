import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/foundation.dart';

class StripeConfig {
  // Test mode keys - replace with your actual test keys
  static const String testPublishableKey = 'pk_test_51RlZSLDMdyUbOMl35rjO3ALQAWWd0YSDE8GD7ecOmbW0L26j2TJL3fdODGoIJLJFtLPj9sFxFhKabDJktlG5Ngix00WwO9rMRL';
  
  // Production keys - replace with your actual production keys  
  static const String prodPublishableKey = 'pk_test_51RlZSLDMdyUbOMl35rjO3ALQAWWd0YSDE8GD7ecOmbW0L26j2TJL3fdODGoIJLJFtLPj9sFxFhKabDJktlG5Ngix00WwO9rMRL';
  
  // Set to false for production
  static const bool isTestMode = true;
  
  static String get publishableKey => isTestMode ? testPublishableKey : prodPublishableKey;
  
  // Stripe merchant identifier for Apple Pay
  static const String merchantIdentifier = 'merchant.com.houseoftailors';
  
  static Future<void> initialize() async {
    try {
      Stripe.publishableKey = publishableKey;
      
      // Only set merchant identifier on supported platforms
      if (!kIsWeb) {
        Stripe.merchantIdentifier = merchantIdentifier;
      }
      
      await Stripe.instance.applySettings();
    } catch (e) {
      print('Stripe initialization error: $e');
      // Continue without Stripe if initialization fails
    }
  }
  
  static Map<String, dynamic> get paymentIntentData => {
    'amount': 0, // Will be set dynamically
    'currency': 'gbp',
    'automatic_payment_methods': {
      'enabled': true,
    },
  };
}