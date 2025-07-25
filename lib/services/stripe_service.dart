import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/stripe_config.dart';

class StripeService {
  static const String _baseUrl = 'https://api.stripe.com/v1';
  
  // Create payment intent or checkout session based on amount
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
    String? customerEmail,
    Map<String, dynamic>? shippingAddress,
  }) async {
    try {
      // For zero amount, create a checkout session instead
      if (amount == 0) {
        return await createZeroAmountCheckoutSession(
          currency: currency,
          customerEmail: customerEmail,
          shippingAddress: shippingAddress,
        );
      }
      
      final url = Uri.parse('$_baseUrl/payment_intents');
      
      final headers = {
        'Authorization': 'Bearer ${_getSecretKey()}',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      
      final body = {
        'amount': amount.toString(),
        'currency': currency,
        'automatic_payment_methods[enabled]': 'true',
        if (customerEmail != null) 'receipt_email': customerEmail,
        if (shippingAddress != null) ..._formatShippingAddress(shippingAddress),
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating payment intent: $e');
      }
      throw Exception('Payment initialization failed');
    }
  }

  // Create checkout session for zero amount payments
  static Future<Map<String, dynamic>> createZeroAmountCheckoutSession({
    required String currency,
    String? customerEmail,
    Map<String, dynamic>? shippingAddress,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/checkout/sessions');
      
      final headers = {
        'Authorization': 'Bearer ${_getSecretKey()}',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version': '2023-08-16', // Required for zero amount support
      };
      
      final body = {
        'mode': 'payment',
        'line_items[0][price_data][unit_amount]': '0',
        'line_items[0][price_data][currency]': currency,
        'line_items[0][price_data][product_data][name]': 'Loyalty Discount Order',
        'line_items[0][quantity]': '1',
        'success_url': 'https://houseoftailors.app/success',
        'cancel_url': 'https://houseoftailors.app/cancel',
        if (customerEmail != null) 'customer_email': customerEmail,
        'billing_address_collection': 'required',
        'phone_number_collection[enabled]': 'true',
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final sessionData = jsonDecode(response.body);
        // Return in PaymentIntent-like format for compatibility
        return {
          'id': sessionData['id'],
          'client_secret': sessionData['id'], // Use session ID as client secret for zero payments
          'amount': 0,
          'currency': currency,
          'status': 'requires_payment_method',
          'is_zero_amount': true, // Flag to identify zero amount payments
          'session_data': sessionData,
        };
      } else {
        throw Exception('Failed to create checkout session: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating checkout session: $e');
      }
      throw Exception('Zero payment initialization failed');
    }
  }

  // Retrieve checkout session
  static Future<Map<String, dynamic>> retrieveCheckoutSession(String sessionId) async {
    try {
      final url = Uri.parse('$_baseUrl/checkout/sessions/$sessionId');
      
      final headers = {
        'Authorization': 'Bearer ${_getSecretKey()}',
      };
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to retrieve checkout session: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving checkout session: $e');
      }
      throw Exception('Checkout session retrieval failed');
    }
  }
  
  // Retrieve payment intent
  static Future<Map<String, dynamic>> retrievePaymentIntent(String paymentIntentId) async {
    try {
      final url = Uri.parse('$_baseUrl/payment_intents/$paymentIntentId');
      
      final headers = {
        'Authorization': 'Bearer ${_getSecretKey()}',
      };
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to retrieve payment intent: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving payment intent: $e');
      }
      throw Exception('Payment retrieval failed');
    }
  }
  
  // Retrieve payment method
  static Future<Map<String, dynamic>> retrievePaymentMethod(String paymentMethodId) async {
    try {
      final url = Uri.parse('$_baseUrl/payment_methods/$paymentMethodId');
      
      final headers = {
        'Authorization': 'Bearer ${_getSecretKey()}',
      };
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to retrieve payment method: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving payment method: $e');
      }
      throw Exception('Payment method retrieval failed');
    }
  }
  
  // Create customer
  static Future<Map<String, dynamic>> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/customers');
      
      final headers = {
        'Authorization': 'Bearer ${_getSecretKey()}',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      
      final body = {
        'email': email,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (address != null) ..._formatAddress(address, 'address'),
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create customer: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating customer: $e');
      }
      throw Exception('Customer creation failed');
    }
  }
  
  // Create ephemeral key for customer
  static Future<Map<String, dynamic>> createEphemeralKey(String customerId) async {
    try {
      final url = Uri.parse('$_baseUrl/ephemeral_keys');
      
      final headers = {
        'Authorization': 'Bearer ${_getSecretKey()}',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version': '2023-10-16',
      };
      
      final body = {
        'customer': customerId,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create ephemeral key: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating ephemeral key: $e');
      }
      throw Exception('Ephemeral key creation failed');
    }
  }
  
  // Validate payment method
  static Future<bool> validatePaymentMethod(String paymentMethodId) async {
    try {
      final url = Uri.parse('$_baseUrl/payment_methods/$paymentMethodId');
      
      final headers = {
        'Authorization': 'Bearer ${_getSecretKey()}',
      };
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final paymentMethod = jsonDecode(response.body);
        return paymentMethod['id'] != null;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error validating payment method: $e');
      }
      return false;
    }
  }
  
  // Format shipping address for Stripe API
  static Map<String, String> _formatShippingAddress(Map<String, dynamic> shippingAddress) {
    final formatted = <String, String>{};
    
    if (shippingAddress['name'] != null) {
      formatted['shipping[name]'] = shippingAddress['name'];
    }
    
    if (shippingAddress['phone'] != null) {
      formatted['shipping[phone]'] = shippingAddress['phone'];
    }
    
    if (shippingAddress['address'] != null) {
      final address = shippingAddress['address'] as Map<String, dynamic>;
      if (address['line1'] != null) {
        formatted['shipping[address][line1]'] = address['line1'];
      }
      if (address['line2'] != null && address['line2'].toString().isNotEmpty) {
        formatted['shipping[address][line2]'] = address['line2'];
      }
      if (address['city'] != null) {
        formatted['shipping[address][city]'] = address['city'];
      }
      if (address['postal_code'] != null) {
        formatted['shipping[address][postal_code]'] = address['postal_code'];
      }
      if (address['country'] != null) {
        formatted['shipping[address][country]'] = address['country'];
      }
    }
    
    return formatted;
  }
  
  // Format address for Stripe API
  static Map<String, String> _formatAddress(Map<String, dynamic> address, String prefix) {
    final formatted = <String, String>{};
    
    if (address['line1'] != null) {
      formatted['$prefix[line1]'] = address['line1'];
    }
    if (address['line2'] != null && address['line2'].toString().isNotEmpty) {
      formatted['$prefix[line2]'] = address['line2'];
    }
    if (address['city'] != null) {
      formatted['$prefix[city]'] = address['city'];
    }
    if (address['postal_code'] != null) {
      formatted['$prefix[postal_code]'] = address['postal_code'];
    }
    if (address['country'] != null) {
      formatted['$prefix[country]'] = address['country'];
    }
    
    return formatted;
  }
  
  // Get secret key based on environment
  static String _getSecretKey() {

    if (StripeConfig.isTestMode) {
      return 'sk_test_51RlZSLDMdyUbOMl3CZ36H7lsPxWF5TT1tuupcKf6pwVkHy5XrfurNMVaRHY5M6gmnLAvhDOFwbsjgwcvmA2YIBF100ZC1t0vFb';
    } else {
      return 'sk_live_YOUR_LIVE_SECRET_KEY_HERE';
    }
  }
  
  // Helper method to format amount for Stripe (multiply by 100 for cents)
  static int formatAmountForStripe(double amount) {
    return (amount * 100).round();
  }
  
  // Helper method to format amount from Stripe (divide by 100 from cents)
  static double formatAmountFromStripe(int amount) {
    return amount / 100.0;
  }
  
  // Validate card details
  static bool validateCardDetails(Map<String, dynamic> cardDetails) {
    return cardDetails['complete'] == true &&
           cardDetails['validNumber'] == true &&
           cardDetails['validExpiryDate'] == true &&
           cardDetails['validCVC'] == true;
  }
  
  // Handle payment success
  static void handlePaymentSuccess(Map<String, dynamic> paymentIntent) {
    if (kDebugMode) {
      print('Payment successful: ${paymentIntent['id']}');
      print('Amount: ${paymentIntent['amount']}');
      print('Status: ${paymentIntent['status']}');
    }
  }
  
  // Handle payment error
  static void handlePaymentError(dynamic error) {
    if (kDebugMode) {
      print('Payment error: $error');
    }
  }
}