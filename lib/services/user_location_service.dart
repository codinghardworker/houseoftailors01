import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserLocationService {
  static const String _locationKey = 'user_location';
  static const String _cityKey = 'user_city';
  static const String _townKey = 'user_town';
  
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  
  // Cache for user data to reduce API calls
  static Map<String, String?>? _cachedLocation;
  static String? _cachedUserName;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  // Check if cache is still valid
  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }
  
  // Clear cache
  static void _clearCache() {
    _cachedLocation = null;
    _cachedUserName = null;
    _lastCacheUpdate = null;
  }
  
  // Public method to clear cache (for auth state changes)
  static void clearCache() {
    _clearCache();
  }
  
  
  /// Save location to Firebase Firestore (if authenticated)
  static Future<bool> saveLocationToDatabase(String city, String town) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Update user location in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'locationCity': city,
        'locationTown': town,
        'locationFull': '$town, $city',
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get location from Firebase Firestore (if authenticated)
  static Future<Map<String, String?>> getLocationFromDatabase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'city': null, 'town': null, 'location': null};
      
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        return {
          'city': userData['locationCity'] as String?,
          'town': userData['locationTown'] as String?,
          'location': userData['locationFull'] as String?,
        };
      }
      
      return {'city': null, 'town': null, 'location': null};
    } catch (e) {
      return {'city': null, 'town': null, 'location': null};
    }
  }
  
  /// Sync location: Save to Firebase Firestore if authenticated
  static Future<void> syncLocation(String city, String town) async {
    final user = _auth.currentUser;
    
    // Only allow location updates if user is authenticated
    if (user == null) {
      return; // Do not save location for unauthenticated users
    }
    
    // Save only to auth metadata (no local storage)
    await saveLocationToDatabase(city, town);
    
    // Update cache
    _cachedLocation = {
      'city': city,
      'town': town,
      'location': '$town, $city',
    };
    _lastCacheUpdate = DateTime.now();
  }
  
  /// Get location: Only from Firebase Firestore for authenticated users
  static Future<Map<String, String?>> getLocation() async {
    // Return cached location if valid
    if (_isCacheValid() && _cachedLocation != null) {
      return _cachedLocation!;
    }
    
    final user = _auth.currentUser;
    
    if (user != null) {
      // Get location only from auth metadata if authenticated
      final authLocation = await getLocationFromDatabase();
      
      // Update cache regardless of whether location exists
      _cachedLocation = authLocation;
      _lastCacheUpdate = DateTime.now();
      
      return authLocation;
    }
    
    // Return empty location for unauthenticated users
    return {'city': null, 'town': null, 'location': null};
  }
  
  /// Get user name from Firebase Firestore
  static Future<String?> getUserName() async {
    try {
      // Return cached name if valid
      if (_isCacheValid() && _cachedUserName != null) {
        return _cachedUserName;
      }
      
      final user = _auth.currentUser;
      if (user == null) return null;
      
      // Try Firebase Auth display name first
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _cachedUserName = user.displayName;
        _lastCacheUpdate = DateTime.now();
        return user.displayName;
      }
      
      // Get from Firestore user document
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        String? name = userData['fullName'] as String? ?? 
                      userData['customerName'] as String?;
        
        if (name != null && name.isNotEmpty) {
          _cachedUserName = name;
          _lastCacheUpdate = DateTime.now();
          return name;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Get user email from Firebase auth
  static Future<String?> getUserEmail() async {
    try {
      final user = _auth.currentUser;
      return user?.email;
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }
  
  /// Get user phone from Firebase Firestore
  static Future<String?> getUserPhone() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      // Get from Firestore user document
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        String? phone = userData['phone'] as String? ?? 
                       userData['customerPhone'] as String?;
        return phone;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Update user profile in auth metadata
  static Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? city,
    String? town,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Prepare updates for Firestore
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) {
        updates['fullName'] = name;
        updates['customerName'] = name;
        // Also update display name in Firebase Auth
        await user.updateDisplayName(name);
      }
      if (phone != null) {
        updates['phone'] = phone;
        updates['customerPhone'] = phone;
      }
      if (city != null) updates['locationCity'] = city;
      if (town != null) updates['locationTown'] = town;
      if (city != null && town != null) updates['locationFull'] = '$town, $city';
      
      // Update user data in Firestore
      await _firestore.collection('users').doc(user.uid).update(updates);
      
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
  
  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }
  
  /// Get complete user profile from Firestore
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        return {
          'id': user.uid,
          'email': user.email,
          'created_at': user.metadata.creationTime?.toIso8601String(),
          'updated_at': userData['updatedAt'],
          ...userData,
        };
      }
      
      return {
        'id': user.uid,
        'email': user.email,
        'created_at': user.metadata.creationTime?.toIso8601String(),
      };
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  /// Initialize user metadata after signup/login
  static Future<bool> initializeUserMetadata({
    String? name,
    String? phone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Check if user document exists in Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      final currentData = docSnapshot.exists ? docSnapshot.data()! : <String, dynamic>{};
      
      // Only update if values are provided and not already set
      final updates = <String, dynamic>{};
      bool needsUpdate = false;
      
      if (name != null && !currentData.containsKey('fullName')) {
        updates['fullName'] = name;
        updates['customerName'] = name;
        // Also update display name in Firebase Auth
        await user.updateDisplayName(name);
        needsUpdate = true;
      }
      
      if (phone != null && !currentData.containsKey('phone')) {
        updates['phone'] = phone;
        updates['customerPhone'] = phone;
        needsUpdate = true;
      }
      
      if (needsUpdate) {
        updates['initializedAt'] = FieldValue.serverTimestamp();
        updates['updatedAt'] = FieldValue.serverTimestamp();
        
        await _firestore.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
      }
      
      return true;
    } catch (e) {
      print('Error initializing user metadata: $e');
      return false;
    }
  }
}