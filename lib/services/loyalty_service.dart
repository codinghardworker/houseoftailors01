import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class LoyaltyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current loyalty progress for the authenticated user
  static Future<Map<String, dynamic>> getLoyaltyProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('Getting loyalty progress for user: ${user.uid}');
      }

      final docSnapshot = await _firestore
          .collection('loyaltyProgress')
          .doc(user.uid)
          .get();

      if (kDebugMode) {
        print('Loyalty progress doc exists: ${docSnapshot.exists}');
      }

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return {
          'completed_orders': data['completedOrders'] ?? 0,
          'lifetime_orders': data['lifetimeOrders'] ?? 0,
          'total_free_orders_claimed': data['totalFreeOrdersClaimed'] ?? 0,
          'eligible_for_free': (data['completedOrders'] ?? 0) >= 5,
        };
      }

      // Return default values if no data found (first time user)
      return {
        'completed_orders': 0,
        'lifetime_orders': 0,
        'total_free_orders_claimed': 0,
        'eligible_for_free': false,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting loyalty progress: $e');
      }
      throw Exception('Failed to get loyalty progress: $e');
    }
  }

  /// Increment loyalty progress after a successful order
  static Future<Map<String, dynamic>> incrementLoyaltyProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('Incrementing loyalty progress for user: ${user.uid}');
      }

      final docRef = _firestore.collection('loyaltyProgress').doc(user.uid);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        final currentCompleted = doc.exists ? (doc.data()?['completedOrders'] ?? 0) : 0;
        final currentLifetime = doc.exists ? (doc.data()?['lifetimeOrders'] ?? 0) : 0;
        final currentFreeClaimed = doc.exists ? (doc.data()?['totalFreeOrdersClaimed'] ?? 0) : 0;
        
        final newCompleted = (currentCompleted + 1).clamp(0, 5);
        final newLifetime = currentLifetime + 1;
        
        final updateData = {
          'completedOrders': newCompleted,
          'lifetimeOrders': newLifetime,
          'totalFreeOrdersClaimed': currentFreeClaimed,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        transaction.set(docRef, updateData, SetOptions(merge: true));

        return {
          'completed_orders': newCompleted,
          'lifetime_orders': newLifetime,
          'total_free_orders_claimed': currentFreeClaimed,
          'eligible_for_free': newCompleted >= 5,
        };
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing loyalty progress: $e');
      }
      throw Exception('Failed to increment loyalty progress: $e');
    }
  }

  /// Sync loyalty progress with existing orders (for first-time setup)
  static Future<Map<String, dynamic>> syncLoyaltyProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('Syncing loyalty progress with existing orders for user: ${user.uid}');
      }

      // Count existing orders for this user
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      final totalOrders = ordersSnapshot.docs.length;
      final completedOrders = (totalOrders % 5); // Reset every 5 orders
      final freeOrdersClaimed = (totalOrders / 5).floor();

      final docRef = _firestore.collection('loyaltyProgress').doc(user.uid);
      
      final updateData = {
        'completedOrders': completedOrders,
        'lifetimeOrders': totalOrders,
        'totalFreeOrdersClaimed': freeOrdersClaimed,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(updateData, SetOptions(merge: true));

      if (kDebugMode) {
        print('Synced loyalty progress: $updateData');
      }

      return {
        'completed_orders': completedOrders,
        'lifetime_orders': totalOrders,
        'orders_synced': totalOrders,
        'eligible_for_free': completedOrders >= 5,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing loyalty progress: $e');
      }
      throw Exception('Failed to sync loyalty progress: $e');
    }
  }

  /// Reset loyalty progress after using a free order
  static Future<Map<String, dynamic>> resetLoyaltyProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('Resetting loyalty progress for user: ${user.uid}');
      }

      final docRef = _firestore.collection('loyaltyProgress').doc(user.uid);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        final currentLifetime = doc.exists ? (doc.data()?['lifetimeOrders'] ?? 0) : 0;
        final currentFreeClaimed = doc.exists ? (doc.data()?['totalFreeOrdersClaimed'] ?? 0) : 0;
        
        final updateData = {
          'completedOrders': 0, // Reset completed orders to 0
          'lifetimeOrders': currentLifetime,
          'totalFreeOrdersClaimed': currentFreeClaimed + 1, // Increment free orders claimed
          'updatedAt': FieldValue.serverTimestamp(),
        };

        transaction.set(docRef, updateData, SetOptions(merge: true));

        return {
          'completed_orders': 0,
          'lifetime_orders': currentLifetime,
          'total_free_orders_claimed': currentFreeClaimed + 1,
          'eligible_for_free': false,
        };
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting loyalty progress: $e');
      }
      throw Exception('Failed to reset loyalty progress: $e');
    }
  }

  /// Check if user is eligible for a free order
  static Future<bool> isEligibleForFreeOrder() async {
    try {
      final progress = await getLoyaltyProgress();
      return progress['eligible_for_free'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking free order eligibility: $e');
      }
      return false;
    }
  }

  /// Get loyalty statistics for user
  static Future<Map<String, dynamic>> getLoyaltyStats() async {
    try {
      final progress = await getLoyaltyProgress();
      final completedOrders = progress['completed_orders'] ?? 0;
      const requiredOrders = 5;
      
      return {
        'completed_orders': completedOrders,
        'required_orders': requiredOrders,
        'orders_remaining': (requiredOrders - completedOrders).clamp(0, requiredOrders),
        'progress_percentage': (completedOrders / requiredOrders * 100).clamp(0.0, 100.0),
        'eligible_for_free': completedOrders >= requiredOrders,
        'lifetime_orders': progress['lifetime_orders'] ?? 0,
        'total_free_orders_claimed': progress['total_free_orders_claimed'] ?? 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting loyalty stats: $e');
      }
      // Return default stats on error
      return {
        'completed_orders': 0,
        'required_orders': 5,
        'orders_remaining': 5,
        'progress_percentage': 0.0,
        'eligible_for_free': false,
        'lifetime_orders': 0,
        'total_free_orders_claimed': 0,
      };
    }
  }

  /// Debug method to manually set loyalty progress (for testing only)
  static Future<void> debugSetLoyaltyProgress(int completedOrders, int lifetimeOrders) async {
    if (!kDebugMode) return; // Only allow in debug mode
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('loyaltyProgress').doc(user.uid).set({
        'completedOrders': completedOrders.clamp(0, 5),
        'lifetimeOrders': lifetimeOrders,
        'totalFreeOrdersClaimed': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Debug: Set loyalty progress to $completedOrders completed, $lifetimeOrders lifetime');
    } catch (e) {
      print('Error setting debug loyalty progress: $e');
    }
  }

  /// Debug method to clear all loyalty progress (for testing only)
  static Future<void> debugClearLoyaltyProgress() async {
    if (!kDebugMode) return; // Only allow in debug mode
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('loyaltyProgress')
          .doc(user.uid)
          .delete();

      print('Debug: Cleared loyalty progress');
    } catch (e) {
      print('Error clearing debug loyalty progress: $e');
    }
  }
}