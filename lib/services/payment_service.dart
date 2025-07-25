import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'stripe_service.dart';
import '../config/stripe_config.dart';
import '../providers/cart_provider.dart';

class PaymentService {
  static const String _orderHistoryKey = 'order_history';
  
  // Process payment with comprehensive error handling
  static Future<PaymentResult> processPayment({
    required CartProvider cartProvider,
    required String email,
    required String firstName,
    required String lastName,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String postalCode,
    required String country,
    required String phone,
    required CardFieldInputDetails cardDetails,
  }) async {
    try {
      // Validate inputs
      final validationResult = _validateInputs(
        email: email,
        firstName: firstName,
        lastName: lastName,
        addressLine1: addressLine1,
        city: city,
        postalCode: postalCode,
        country: country,
        cardDetails: cardDetails,
      );
      
      if (!validationResult.isValid) {
        return PaymentResult.failure(validationResult.errorMessage!);
      }
      
      // Calculate total amount
      final totalAmount = cartProvider.subtotal.toInt();
      
      if (totalAmount <= 0) {
        return PaymentResult.failure('Invalid order amount');
      }
      
      // Create payment intent
      final paymentIntent = await StripeService.createPaymentIntent(
        amount: totalAmount,
        currency: 'gbp',
        customerEmail: email,
        shippingAddress: {
          'name': '$firstName $lastName',
          'address': {
            'line1': addressLine1,
            'line2': addressLine2,
            'city': city,
            'postal_code': postalCode,
            'country': country,
          },
          'phone': phone,
        },
      );
      
      // Confirm payment with Stripe
      final paymentResult = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              email: email,
              name: '$firstName $lastName',
              phone: phone,
              address: Address(
                line1: addressLine1,
                line2: addressLine2,
                city: city,
                postalCode: postalCode,
                country: country,
                state: null,
              ),
            ),
          ),
        ),
      );
      
      // Save order to local storage
      await _saveOrderToHistory(
        cartProvider: cartProvider,
        paymentIntentId: paymentIntent['id'],
        email: email,
        firstName: firstName,
        lastName: lastName,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        postalCode: postalCode,
        country: country,
        phone: phone,
        totalAmount: totalAmount,
      );
      
      return PaymentResult.success(
        paymentIntentId: paymentIntent['id'],
        amount: totalAmount,
        currency: 'gbp',
      );
      
    } on StripeException catch (e) {
      return PaymentResult.failure(_handleStripeError(e));
    } catch (e) {
      if (kDebugMode) {
        print('Payment processing error: $e');
      }
      return PaymentResult.failure('An unexpected error occurred. Please try again.');
    }
  }
  
  // Validate all inputs
  static ValidationResult _validateInputs({
    required String email,
    required String firstName,
    required String lastName,
    required String addressLine1,
    required String city,
    required String postalCode,
    required String country,
    required CardFieldInputDetails cardDetails,
  }) {
    // Email validation
    if (email.isEmpty || !email.contains('@')) {
      return ValidationResult.invalid('Please enter a valid email address');
    }
    
    // Name validation
    if (firstName.isEmpty) {
      return ValidationResult.invalid('First name is required');
    }
    
    if (lastName.isEmpty) {
      return ValidationResult.invalid('Last name is required');
    }
    
    // Address validation
    if (addressLine1.isEmpty) {
      return ValidationResult.invalid('Address line 1 is required');
    }
    
    if (city.isEmpty) {
      return ValidationResult.invalid('City is required');
    }
    
    if (postalCode.isEmpty) {
      return ValidationResult.invalid('Postal code is required');
    }
    
    if (country.isEmpty) {
      return ValidationResult.invalid('Country is required');
    }
    
    // Card validation
    if (!cardDetails.complete) {
      return ValidationResult.invalid('Please complete your card information');
    }
    
    return ValidationResult.valid();
  }
  
  // Handle Stripe-specific errors
  static String _handleStripeError(StripeException e) {
    final errorMessage = e.error.localizedMessage?.toLowerCase() ?? '';
    
    if (errorMessage.contains('declined')) {
      return 'Your card was declined. Please try another payment method.';
    } else if (errorMessage.contains('expired')) {
      return 'Your card has expired. Please use a different card.';
    } else if (errorMessage.contains('cvc') || errorMessage.contains('security')) {
      return 'The security code is incorrect. Please check and try again.';
    } else if (errorMessage.contains('processing')) {
      return 'An error occurred while processing your payment. Please try again.';
    } else if (errorMessage.contains('number')) {
      return 'The card number is incorrect. Please check and try again.';
    } else if (errorMessage.contains('expiry') || errorMessage.contains('month') || errorMessage.contains('year')) {
      return 'The expiry date is invalid. Please check and try again.';
    } else if (errorMessage.contains('postal') || errorMessage.contains('zip')) {
      return 'The postal code is incorrect. Please check and try again.';
    } else if (errorMessage.contains('insufficient')) {
      return 'Insufficient funds. Please use a different card.';
    } else {
      return e.error.localizedMessage ?? 'Payment failed. Please try again.';
    }
  }
  
  // Save order to local storage
  static Future<void> _saveOrderToHistory({
    required CartProvider cartProvider,
    required String paymentIntentId,
    required String email,
    required String firstName,
    required String lastName,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String postalCode,
    required String country,
    required String phone,
    required int totalAmount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderHistoryData = prefs.getString(_orderHistoryKey) ?? '[]';
      final List<dynamic> orderHistory = jsonDecode(orderHistoryData);
      
      final order = {
        'id': paymentIntentId,
        'date': DateTime.now().toIso8601String(),
        'email': email,
        'customer': {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
        },
        'shippingAddress': {
          'line1': addressLine1,
          'line2': addressLine2,
          'city': city,
          'postalCode': postalCode,
          'country': country,
        },
        'items': cartProvider.items.map((item) => item.toJson()).toList(),
        'totalAmount': totalAmount,
        'currency': 'gbp',
        'status': 'completed',
        'paymentMethod': 'card',
        'isTestMode': StripeConfig.isTestMode,
      };
      
      orderHistory.add(order);
      
      await prefs.setString(_orderHistoryKey, jsonEncode(orderHistory));
      
      if (kDebugMode) {
        print('Order saved to history: $paymentIntentId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving order to history: $e');
      }
    }
  }
  
  // Get order history
  static Future<List<Map<String, dynamic>>> getOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderHistoryData = prefs.getString(_orderHistoryKey) ?? '[]';
      final List<dynamic> orderHistory = jsonDecode(orderHistoryData);
      
      return orderHistory.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading order history: $e');
      }
      return [];
    }
  }
  
  // Clear order history
  static Future<void> clearOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_orderHistoryKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing order history: $e');
      }
    }
  }
  
  // Retry payment
  static Future<PaymentResult> retryPayment({
    required String paymentIntentId,
    required CardFieldInputDetails cardDetails,
  }) async {
    try {
      final paymentIntent = await StripeService.retrievePaymentIntent(paymentIntentId);
      
      if (paymentIntent['status'] == 'succeeded') {
        return PaymentResult.success(
          paymentIntentId: paymentIntentId,
          amount: paymentIntent['amount'],
          currency: paymentIntent['currency'],
        );
      }
      
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      
      return PaymentResult.success(
        paymentIntentId: paymentIntentId,
        amount: paymentIntent['amount'],
        currency: paymentIntent['currency'],
      );
      
    } on StripeException catch (e) {
      return PaymentResult.failure(_handleStripeError(e));
    } catch (e) {
      return PaymentResult.failure('Retry failed. Please try again.');
    }
  }
  
  // Check payment status
  static Future<String> checkPaymentStatus(String paymentIntentId) async {
    try {
      final paymentIntent = await StripeService.retrievePaymentIntent(paymentIntentId);
      return paymentIntent['status'] ?? 'unknown';
    } catch (e) {
      return 'error';
    }
  }
  
  // Format amount for display
  static String formatAmount(int amount, String currency) {
    final formattedAmount = (amount / 100).toStringAsFixed(2);
    switch (currency.toUpperCase()) {
      case 'GBP':
        return '£$formattedAmount';
      case 'USD':
        return '\$$formattedAmount';
      case 'EUR':
        return '€$formattedAmount';
      default:
        return '$formattedAmount $currency';
    }
  }
}

// Payment result class
class PaymentResult {
  final bool isSuccess;
  final String? paymentIntentId;
  final int? amount;
  final String? currency;
  final String? errorMessage;
  
  PaymentResult._({
    required this.isSuccess,
    this.paymentIntentId,
    this.amount,
    this.currency,
    this.errorMessage,
  });
  
  factory PaymentResult.success({
    required String paymentIntentId,
    required int amount,
    required String currency,
  }) {
    return PaymentResult._(
      isSuccess: true,
      paymentIntentId: paymentIntentId,
      amount: amount,
      currency: currency,
    );
  }
  
  factory PaymentResult.failure(String errorMessage) {
    return PaymentResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

// Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  ValidationResult._({
    required this.isValid,
    this.errorMessage,
  });
  
  factory ValidationResult.valid() {
    return ValidationResult._(isValid: true);
  }
  
  factory ValidationResult.invalid(String errorMessage) {
    return ValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}