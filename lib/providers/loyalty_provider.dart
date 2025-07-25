import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/loyalty_service.dart';
import '../services/auth_service.dart';

class LoyaltyProvider extends ChangeNotifier {
  int _completedOrders = 0;
  int _lifetimeOrders = 0;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService;
  
  static const int _requiredOrdersForFree = 5;
  static const double _freeOrderDiscount = 5000.0; // £50 in pence

  // Constructor
  LoyaltyProvider(this._authService) {
    _loadLoyaltyProgress();
    // Listen to auth state changes
    _authService.addListener(_onAuthStateChanged);
  }

  // Getters
  int get completedOrders => _completedOrders;
  int get lifetimeOrders => _lifetimeOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEligibleForFreeOrder => _completedOrders >= _requiredOrdersForFree;
  double get freeOrderDiscount => _freeOrderDiscount;
  int get requiredOrdersForFree => _requiredOrdersForFree;
  double get progressPercentage => (_completedOrders / _requiredOrdersForFree).clamp(0.0, 1.0);

  // Handle authentication state changes
  void _onAuthStateChanged() {
    if (!_authService.isLoggedIn) {
      // User logged out - reset to 0 and clear local storage
      _completedOrders = 0;
      _lifetimeOrders = 0;
      _clearLocalStorage();
      notifyListeners();
      if (kDebugMode) {
        print('User logged out - loyalty progress reset to 0');
      }
    } else {
      // User logged in - reload loyalty progress
      _loadLoyaltyProgress();
    }
  }

  // Load loyalty progress from database
  Future<void> _loadLoyaltyProgress() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Check if user is authenticated
      if (!_authService.isLoggedIn) {
        // Not authenticated - default to 0 progress, don't use local storage
        _completedOrders = 0;
        _lifetimeOrders = 0;
        if (kDebugMode) {
          print('User not authenticated - loyalty progress set to 0');
        }
        return;
      }
      
      final progress = await LoyaltyService.getLoyaltyProgress();
      
      _completedOrders = progress['completed_orders'] ?? 0;
      _lifetimeOrders = progress['lifetime_orders'] ?? 0;
      
      // Save to local storage as backup only when authenticated
      await _saveToLocalStorage();
      
      if (kDebugMode) {
        print('Loyalty progress loaded: $_completedOrders completed, $_lifetimeOrders lifetime');
      }
    } catch (e) {
      _setError('Failed to load loyalty progress: $e');
      // Only try to load from local storage as fallback if user is authenticated
      if (_authService.isLoggedIn) {
        await _loadFromLocalStorage();
      } else {
        // Not authenticated - keep at 0
        _completedOrders = 0;
        _lifetimeOrders = 0;
      }
      if (kDebugMode) {
        print('Error loading loyalty progress: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Refresh loyalty progress from database
  Future<void> refreshLoyaltyProgress() async {
    await _loadLoyaltyProgress();
  }

  // Increment loyalty progress (called after successful order)
  Future<void> incrementProgress() async {
    // Only increment if user is authenticated
    if (!_authService.isLoggedIn) {
      if (kDebugMode) {
        print('User not authenticated - skipping loyalty progress increment');
      }
      return;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      await LoyaltyService.incrementLoyaltyProgress();
      
      // Reload progress to get updated values
      await _loadLoyaltyProgress();
      
      if (kDebugMode) {
        print('Loyalty progress incremented successfully');
      }
    } catch (e) {
      _setError('Failed to increment loyalty progress: $e');
      if (kDebugMode) {
        print('Error incrementing loyalty progress: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Reset loyalty progress (called after free order is used)
  Future<void> resetProgress() async {
    // Only reset if user is authenticated
    if (!_authService.isLoggedIn) {
      if (kDebugMode) {
        print('User not authenticated - skipping loyalty progress reset');
      }
      return;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      await LoyaltyService.resetLoyaltyProgress();
      
      // Update local state
      _completedOrders = 0;
      _lifetimeOrders++; // Increment lifetime orders
      
      // Save to local storage only when authenticated
      await _saveToLocalStorage();
      
      if (kDebugMode) {
        print('Loyalty progress reset successfully');
      }
    } catch (e) {
      _setError('Failed to reset loyalty progress: $e');
      if (kDebugMode) {
        print('Error resetting loyalty progress: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Sync existing orders (called on first app load)
  Future<void> syncExistingOrders() async {
    try {
      _setLoading(true);
      _clearError();
      
      await LoyaltyService.syncLoyaltyProgress();
      
      // Reload progress to get updated values
      await _loadLoyaltyProgress();
      
      if (kDebugMode) {
        print('Existing orders synced successfully');
      }
    } catch (e) {
      _setError('Failed to sync existing orders: $e');
      if (kDebugMode) {
        print('Error syncing existing orders: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Local storage methods for backup
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('loyalty_completed_orders', _completedOrders);
      await prefs.setInt('loyalty_lifetime_orders', _lifetimeOrders);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving loyalty progress to local storage: $e');
      }
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _completedOrders = prefs.getInt('loyalty_completed_orders') ?? 0;
      _lifetimeOrders = prefs.getInt('loyalty_lifetime_orders') ?? 0;
      notifyListeners();
      
      if (kDebugMode) {
        print('Loyalty progress loaded from local storage: $_completedOrders completed, $_lifetimeOrders lifetime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading loyalty progress from local storage: $e');
      }
    }
  }

  // Manual update methods (for testing)
  void updateProgress(int completedOrders, int lifetimeOrders) {
    _completedOrders = completedOrders;
    _lifetimeOrders = lifetimeOrders;
    notifyListeners();
    _saveToLocalStorage();
  }

  // Clear local storage only
  Future<void> _clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('loyalty_completed_orders');
      await prefs.remove('loyalty_lifetime_orders');
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing loyalty progress from local storage: $e');
      }
    }
  }

  // Clear all data
  Future<void> clearProgress() async {
    _completedOrders = 0;
    _lifetimeOrders = 0;
    _error = null;
    notifyListeners();
    
    // Clear from local storage
    await _clearLocalStorage();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}