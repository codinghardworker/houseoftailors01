
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import 'loyalty_service.dart';

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<String?> saveOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String paymentIntentId,
    required Map<String, dynamic> billingDetails,
    required String currency,
  }) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Extract delivery information from the first item's service details
      String deliveryMethod = 'pickup'; // Default
      Map<String, dynamic> deliveryInfo = {};
      
      if (items.isNotEmpty && items.first.serviceDetails.isNotEmpty) {
        final firstService = items.first.serviceDetails.first;
        if (firstService.deliveryMethod != null) {
          deliveryMethod = firstService.deliveryMethod!;
          
          // Add delivery-specific information
          if (deliveryMethod == 'pickup') {
            deliveryInfo['pickup_date'] = firstService.pickupDate?.toIso8601String();
            deliveryInfo['pickup_time'] = firstService.pickupTime;
            deliveryInfo['pickup_cost'] = firstService.pickupCost;
          }
        }
      }

      final orderData = {
        'userId': user.uid,
        'paymentIntentId': paymentIntentId,
        'totalAmount': totalAmount / 100,
        'currency': currency,
        'status': 'pickup',
        'deliveryMethod': deliveryMethod,
        'deliveryInfo': deliveryInfo,
        'billingAddress': billingDetails['address'] ?? {},
        'customerName': billingDetails['name'] ?? '',
        'customerEmail': billingDetails['email'] ?? user.email,
        'customerPhone': billingDetails['phone'] ?? '',
        'orderedAt': FieldValue.serverTimestamp(),
        'orderItems': items.map((item) => {
          'itemId': item.item.id,
          'itemName': item.item.name,
          'itemDescription': item.itemDescription,
          'itemCategory': {
            'id': item.itemCategory.id,
            'name': item.itemCategory.name,
          },
          'services': item.serviceDetails.map((service) => {
            'serviceId': service.service.id,
            'serviceName': service.service.name,
            'basePrice': service.basePrice,
            'totalPrice': service.totalPrice,
            'tailorNotes': service.tailorNotes,
            'fittingChoice': service.fittingChoice,
            'fittingDetails': service.fittingDetails,
            'serviceDescription': service.serviceDescription,
            'repairLocation': service.repairLocation,
            'deliveryMethod': service.deliveryMethod,
            'pickupDate': service.pickupDate?.toIso8601String(),
            'pickupTime': service.pickupTime,
            'pickupCost': service.pickupCost,
            'questionAnswers': service.questionAnswerModifiers.map((qa) => {
              'question': qa.question,
              'answer': qa.answer,
              'priceModifier': qa.priceModifier,
              'isTextInput': qa.isTextInput,
              'textResponse': qa.textResponse,
            }).toList(),
            'subserviceDetails': service.subserviceDetails != null ? {
              'subserviceId': service.subserviceDetails!.subservice.id,
              'subserviceName': service.subserviceDetails!.subservice.name,
              'priceModifier': service.subserviceDetails!.subservice.priceModifier,
              'questionAnswers': service.subserviceDetails!.questionAnswerModifiers.map((qa) => {
                'question': qa.question,
                'answer': qa.answer,
                'priceModifier': qa.priceModifier,
                'isTextInput': qa.isTextInput,
                'textResponse': qa.textResponse,
              }).toList(),
            } : null,
          }).toList(),
          'itemTotal': item.totalPrice,
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('orders').add(orderData);

      if (kDebugMode) {
        print('Order saved successfully with ID: ${docRef.id}');
      }

      // Update loyalty progress after successful order save
      try {
        await LoyaltyService.incrementLoyaltyProgress();
        if (kDebugMode) {
          print('Loyalty progress updated successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error updating loyalty progress: $e');
        }
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving order: $e');
      }
      throw Exception('Failed to save order: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('No authenticated user found');
        }
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('Fetching orders for user: ${user.uid}');
      }

      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      if (kDebugMode) {
        print('Orders query completed');
        print('Number of orders found: ${querySnapshot.docs.length}');
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching orders: $e');
        print('Error type: ${e.runtimeType}');
      }
      throw Exception('Failed to fetch orders: $e');
    }
  }

  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final docSnapshot = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (docSnapshot.exists && docSnapshot.data()?['userId'] == user.uid) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return data;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching order: $e');
      }
      return null;
    }
  }

  static Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Verify the order belongs to the user before updating
      final docSnapshot = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!docSnapshot.exists || docSnapshot.data()?['userId'] != user.uid) {
        throw Exception('Order not found or access denied');
      }

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      return false;
    }
  }

  // Debug method to check if orders table exists and what data is in it
  static Future<void> debugOrders() async {
    try {
      if (kDebugMode) {
        print('=== DEBUG: Checking orders table ===');
        
        final user = AuthService().currentUser;
        if (user == null) {
          print('No authenticated user');
          return;
        }
        
        print('User ID: ${user.uid}');
        print('User email: ${user.email}');
        
        // Try to get all orders for this user
        final querySnapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .get();
            
        print('Orders query completed');
        print('Number of orders: ${querySnapshot.docs.length}');
        
        // Print individual order details
        for (var doc in querySnapshot.docs) {
          final order = doc.data();
          print('Order: ${doc.id} - Status: ${order['status']} - Amount: ${order['totalAmount']}');
        }
        
        print('=== END DEBUG ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug error: $e');
      }
    }
  }
}