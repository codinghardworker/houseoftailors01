import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Private user variable
  User? _user;

  // Getter for current user
  User? get currentUser => _user;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  // Initialize auth service
  Future<void> initialize() async {
    _setLoading(true);
    try {
      print('Initializing Firebase AuthService...');
      
      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        print('Auth state changed: ${user?.uid}');
        _user = user;
        notifyListeners();
      });

      // Check if user is already logged in
      _user = _auth.currentUser;
      if (_user != null) {
        print('Existing session found: ${_user?.uid}');
      } else {
        print('No existing session found');
      }
    } catch (e) {
      print('Firebase AuthService initialization error: $e');
      _setError('Failed to initialize auth service: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check network connectivity - platform compatible
  Future<bool> _checkConnectivity() async {
    try {
      // Skip connectivity check on web platforms where InternetAddress.lookup is not supported
      if (kIsWeb) {
        return true; // Assume connectivity on web, let the actual request handle failures
      }
      
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on UnsupportedError catch (_) {
      // InternetAddress.lookup not supported on this platform
      return true; // Assume connectivity, let the actual request handle failures
    } catch (_) {
      return true; // Assume connectivity on unknown errors
    }
  }

  // Test Firebase connection
  Future<bool> testFirebaseConnection() async {
    try {
      print('Testing Firebase connection...');
      
      // Simple health check by trying to get current user
      final user = _auth.currentUser;
      print('Current user: ${user?.uid}');
      
      print('Firebase connection test passed');
      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }

  // Email validation
  bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Password validation
  bool isValidPassword(String password) {
    // At least 8 characters, one number, one uppercase, one lowercase, and special character
    final RegExp passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.])[A-Za-z\d@$!%*?&.]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  // Phone number validation
  bool isValidPhoneNumber(String phone) {
    // Basic phone number validation (can be customized based on your requirements)
    final RegExp phoneRegex = RegExp(
      r'^\+?[1-9]\d{1,14}$',
    );
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  // Register user
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? locationCity,
    String? locationTown,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      // Validate inputs
      if (!isValidEmail(email)) {
        throw 'Please enter a valid email address';
      }
      if (!isValidPassword(password)) {
        throw 'Password must be at least 8 characters with uppercase, lowercase, and number';
      }
      if (!isValidPhoneNumber(phone)) {
        throw 'Please enter a valid phone number';
      }
      if (fullName.trim().isEmpty) {
        throw 'Full name is required';
      }

      // Trim all inputs
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();
      final trimmedFullName = fullName.trim();
      final trimmedPhone = phone.trim();

      // Check if user already exists in Firestore (legacy user)
      final userExists = await checkUserExistence(trimmedEmail);
      bool isLegacyUser = !userExists['auth']! && userExists['firestore']!;

      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      if (userCredential.user != null) {
        
        // Update display name
        await userCredential.user!.updateDisplayName(trimmedFullName);
        
        // Store additional user data in Firestore
        final userData = {
          'fullName': trimmedFullName,
          'phone': trimmedPhone,
          'email': trimmedEmail,
          'phoneVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add location data if provided
        if (locationCity != null && locationTown != null) {
          userData.addAll({
            'locationCity': locationCity,
            'locationTown': locationTown,
            'locationFull': '$locationTown, $locationCity',
            'locationUpdatedAt': FieldValue.serverTimestamp(),
          });
        }

        if (isLegacyUser) {
          // Update existing legacy user document
          print('Updating legacy user data for: ${trimmedEmail}');
          userData['migratedAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('users').doc(userCredential.user!.uid).update(userData);
        } else {
          // Create new user document
          userData['createdAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
        }

        _user = userCredential.user;
        print('New user created successfully: ${userCredential.user!.uid}');
        return true;
      }

      _setError('Registration failed - please try again');
      return false;

    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          // Check if this is a legacy user scenario
          final userExists = await checkUserExistence(email.trim());
          if (!userExists['auth']! && userExists['firestore']!) {
            _setError('This email is associated with an older account. Please contact support for account migration assistance.');
          } else {
            _setError('An account with this email already exists');
          }
          break;
        case 'weak-password':
          _setError('Password is too weak');
          break;
        case 'invalid-email':
          _setError('Invalid email address');
          break;
        default:
          _setError(e.message ?? 'Registration failed');
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      // Validate inputs
      if (!isValidEmail(email)) {
        throw 'Please enter a valid email address';
      }
      if (password.trim().isEmpty) {
        throw 'Password is required';
      }

      // Trim email and password
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      print('Attempting login for: $trimmedEmail');

      // Check network connectivity first
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      print('Login response received: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        _user = userCredential.user;
        print('Login successful for user: ${userCredential.user!.email}');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('Auth exception: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          _setError('Invalid email or password');
          break;
        case 'user-disabled':
          _setError('This account has been disabled');
          break;
        case 'too-many-requests':
          _setError('Too many failed attempts. Please try again later');
          break;
        default:
          _setError(e.message ?? 'Login failed');
      }
      return false;
    } on Exception catch (e) {
      print('General exception during login: $e');
      if (e.toString().toLowerCase().contains('clientexception') || 
          e.toString().toLowerCase().contains('failed to fetch')) {
        _setError('Network connection error. Please check your internet connection and try again.');
      } else {
        _setError('Login failed: ${e.toString()}');
      }
      return false;
    } catch (e) {
      print('Unexpected error during login: $e');
      print('Error type: ${e.runtimeType}');
      _setError('Network connection error. Please check your internet connection and try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }


  // Test Firebase Auth connectivity
  Future<bool> testFirebaseAuth() async {
    try {
      print('=== FIREBASE AUTH TEST ===');
      print('Firebase app: ${_auth.app.name}');
      print('Project ID: ${_auth.app.options.projectId}');
      print('API Key exists: ${_auth.app.options.apiKey.isNotEmpty}');
      
      // Test basic Firebase connection
      await _auth.authStateChanges().first;
      print('Auth state stream is working');
      
      // Test if we can call a simple Firebase method
      final methods = await _auth.fetchSignInMethodsForEmail('test@example.com');
      print('fetchSignInMethodsForEmail works, returned: $methods');
      
      print('✅ Firebase Auth test passed');
      return true;
    } catch (e) {
      print('❌ Firebase Auth test failed: $e');
      return false;
    }
  }

  // Check if user exists in Firebase Auth vs Firestore
  Future<Map<String, bool>> checkUserExistence(String email) async {
    try {
      // Check Firebase Auth
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email.trim());
      final existsInAuth = signInMethods.isNotEmpty;
      
      // Check Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      final existsInFirestore = querySnapshot.docs.isNotEmpty;
      
      print('User existence check for $email:');
      print('- Firebase Auth: $existsInAuth');
      print('- Firestore: $existsInFirestore');
      
      return {
        'auth': existsInAuth,
        'firestore': existsInFirestore,
      };
    } catch (e) {
      print('Error checking user existence: $e');
      return {'auth': false, 'firestore': false};
    }
  }


  // Update profile
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_user == null) {
        throw 'User not authenticated';
      }

      if (phone != null && !isValidPhoneNumber(phone)) {
        throw 'Please enter a valid phone number';
      }

      final Map<String, dynamic> updates = {};
      if (fullName != null && fullName.trim().isNotEmpty) {
        updates['fullName'] = fullName.trim();
        // Also update display name in Firebase Auth
        await _user!.updateDisplayName(fullName.trim());
      }
      if (phone != null && phone.trim().isNotEmpty) {
        updates['phone'] = phone.trim();
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        
        // Update user document in Firestore
        await _firestore.collection('users').doc(_user!.uid).update(updates);
        
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (fullName != null) {
          await prefs.setString('user_full_name', fullName);
        }
        if (phone != null) {
          await prefs.setString('user_phone', phone);
        }
        
        return true;
      }
      return false;
    } on FirebaseException catch (e) {
      _setError(e.message ?? 'Failed to update profile');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile picture using Base64
  Future<bool> updateProfilePicture(String base64Image) async {
    _setLoading(true);
    _setError(null);
    
    try {
      // Validate base64 image
      if (base64Image.isEmpty) {
        throw 'Invalid image data';
      }
      
      // Ensure the base64 string is properly formatted
      if (!base64Image.startsWith('data:image/')) {
        throw 'Invalid image format';
      }
      
      if (_user == null) {
        throw 'User not authenticated';
      }

      print('Updating profile picture...');
      
      // Store the base64 image in Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'avatarUrl': base64Image,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Profile picture updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating profile picture: $e');
      
      // Handle specific errors
      if (e.toString().contains('Request Header Or Cookie Too Large') || 
          e.toString().contains('400') && e.toString().contains('large')) {
        _setError('Image too large. Please select a smaller image.');
      } else if (e.toString().contains('Failed to decode error response')) {
        _setError('Image too large or network error. Please try a smaller image.');
      } else if (e.toString().contains('Connection timed out') || 
                 e.toString().contains('TimeoutException')) {
        _setError('Connection timeout. Please check your internet and try again.');
      } else if (e.toString().contains('SocketException')) {
        _setError('Network error. Please check your connection and try again.');
      } else {
        _setError('Failed to update profile picture. Please try again.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove profile picture
  Future<bool> removeProfilePicture() async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_user == null) {
        throw 'User not authenticated';
      }

      print('Removing profile picture...');
      
      await _firestore.collection('users').doc(_user!.uid).update({
        'avatarUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Profile picture removed successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error removing profile picture: $e');
      
      // Handle specific errors
      if (e.toString().contains('Connection timed out') || 
          e.toString().contains('TimeoutException')) {
        _setError('Connection timeout. Please check your internet and try again.');
      } else if (e.toString().contains('SocketException')) {
        _setError('Network error. Please check your connection and try again.');
      } else {
        _setError('Failed to remove profile picture. Please try again.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _auth.signOut();
      _user = null;
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_full_name');
      await prefs.remove('user_phone');
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Logout failed');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get user full name
  String get userFullName {
    return _user?.displayName ?? '';
  }

  // Get user phone - need to fetch from Firestore
  Future<String> getUserPhone() async {
    if (_user == null) return '';
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      return doc.data()?['phone'] ?? '';
    } catch (e) {
      return '';
    }
  }

  // Get user phone synchronously (cached value)
  String get userPhone {
    // This will be empty initially, you should call getUserPhone() to fetch the actual value
    return '';
  }

  // Get user avatar URL from Firestore
  Future<String?> getUserAvatarUrl() async {
    if (_user == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      return doc.data()?['avatarUrl'] as String?;
    } catch (e) {
      print('Error getting user avatar: $e');
      return null;
    }
  }

  // Get user email
  String get userEmail {
    return _user?.email ?? '';
  }



  // Update phone number
  Future<bool> updatePhoneNumber(String newPhone) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (!isValidPhoneNumber(newPhone)) {
        throw 'Please enter a valid phone number';
      }

      final trimmedPhone = newPhone.trim();
      
      if (_user == null) {
        throw 'User not authenticated';
      }

      // Update phone in Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'phone': trimmedPhone,
        'phoneVerified': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error updating phone number: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
} 