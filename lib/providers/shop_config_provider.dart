import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/shop_config_service.dart';

class ShopConfigProvider extends ChangeNotifier {
  // Shop information
  String _shopName = '';
  String _shopAddress = '';
  String _mapLink = '';
  String _shopPhone = '';
  String _shopEmail = '';
  
  // Delivery charges
  double _pickupCharge = 10.0;
  double _postCharge 
  = 0.0;
  
  // Pickup configuration
  int _pickupStartHour = 9;
  int _pickupEndHour = 18;
  int _pickupSlotDuration = 2;
  List<int> _pickupAvailableDays = [1, 2, 3, 4, 5, 6]; // Monday to Saturday
  
  // State management
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _configSubscription;

  // Constructor
  ShopConfigProvider() {
    _loadShopConfig();
    _listenToConfigUpdates();
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }

  // Getters - Shop Information
  String get shopName => _shopName;
  String get shopAddress => _shopAddress;
  String get mapLink => _mapLink;
  String get shopPhone => _shopPhone;
  String get shopEmail => _shopEmail;

  // Getters - Delivery Charges
  double get pickupCharge => _pickupCharge;
  double get postCharge => _postCharge;
  Map<String, double> get deliveryCharges => {
    'pickup': _pickupCharge,
    'post': _postCharge,
  };

  // Getters - Pickup Configuration
  int get pickupStartHour => _pickupStartHour;
  int get pickupEndHour => _pickupEndHour;
  int get pickupSlotDuration => _pickupSlotDuration;
  List<int> get pickupAvailableDays => List.from(_pickupAvailableDays);

  // Getters - State
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load shop configuration from database
  Future<void> _loadShopConfig() async {
    try {
      _setLoading(true);
      _clearError();

      // Ensure ShopConfigService is initialized first
      await ShopConfigService.ensureInitialized();

      final config = ShopConfigService.getAllConfig();
      final location = ShopConfigService.getShopLocation();
      final charges = ShopConfigService.getDeliveryCharges();

      // Update shop information
      _shopName = location['name'] ?? '';
      _shopAddress = location['address'] ?? '';
      _mapLink = location['map_link'] ?? '';
      _shopPhone = location['phone'] ?? '';
      _shopEmail = location['email'] ?? '';

      // Update delivery charges - get actual pickup charge from ShopConfigService
      _pickupCharge = ShopConfigService.getPickupChargePence() / 100.0; // Convert pence to pounds
      _postCharge = ShopConfigService.getPostDeliveryChargePence() / 100.0; // Convert pence to pounds

      // Update pickup configuration - get from actual pickup slots config
      final pickupSlots = ShopConfigService.getPickupSlots();
      if (pickupSlots != null && pickupSlots.isNotEmpty) {
        // Use actual pickup slot configuration
        _pickupStartHour = 9; // Default - could be extracted from first slot
        _pickupEndHour = 18; // Default - could be extracted from last slot  
        _pickupSlotDuration = 2; // Default
        _pickupAvailableDays = _getAvailableDaysFromSlots(pickupSlots);
      } else {
        // No pickup configuration available
        _pickupStartHour = 0;
        _pickupEndHour = 0;
        _pickupSlotDuration = 0;
        _pickupAvailableDays = [];
      }

      if (kDebugMode) {
        print('Shop configuration loaded successfully');
        print('Pickup charge: £${_pickupCharge.toStringAsFixed(2)}');
        print('Pickup hours: ${_pickupStartHour}:00 - ${_pickupEndHour}:00');
        print('Available days: $_pickupAvailableDays');
      }
    } catch (e) {
      _setError('Failed to load shop configuration: $e');
      if (kDebugMode) {
        print('Error loading shop configuration: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Listen to configuration updates from service
  void _listenToConfigUpdates() {
    _configSubscription = ShopConfigService.configStream.listen(
      (config) {
        if (kDebugMode) {
          print('ShopConfigProvider: Received config update');
        }
        _updateFromConfig(config);
      },
      onError: (error) {
        if (kDebugMode) {
          print('ShopConfigProvider: Config stream error: $error');
        }
      },
    );
  }

  // Update provider state from configuration data
  void _updateFromConfig(Map<String, dynamic> config) {
    final location = ShopConfigService.getShopLocation();
    final charges = ShopConfigService.getDeliveryCharges();

    // Update shop information
    _shopName = location['name'] ?? '';
    _shopAddress = location['address'] ?? '';
    _mapLink = location['map_link'] ?? '';
    _shopPhone = location['phone'] ?? '';
    _shopEmail = location['email'] ?? '';

    // Update delivery charges
    _pickupCharge = ShopConfigService.getPickupChargePence() / 100.0;
    _postCharge = ShopConfigService.getPostDeliveryChargePence() / 100.0;

    // Update pickup configuration
    final pickupSlots = ShopConfigService.getPickupSlots();
    if (pickupSlots != null && pickupSlots.isNotEmpty) {
      _pickupAvailableDays = _getAvailableDaysFromSlots(pickupSlots);
    }

    notifyListeners();
  }

  // Refresh configuration from database
  Future<void> refreshConfig() async {
    await ShopConfigService.refresh();
    await _loadShopConfig();
  }

  // Get available pickup time slots for a specific date
  Future<List<String>> getPickupSlots({DateTime? selectedDate}) async {
    try {
      return await ShopConfigService.getAvailablePickupSlots(selectedDate: selectedDate);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pickup slots: $e');
      }
      // Return default slots on error
      return [
        '10:00 AM – 12:00 PM',
        '12:00 PM – 2:00 PM',
        '2:00 PM – 4:00 PM',
        '4:00 PM – 6:00 PM',
      ];
    }
  }

  // Check if pickup is available on a specific date
  Future<bool> isPickupAvailable(DateTime date) async {
    try {
      return await ShopConfigService.isPickupAvailable(date);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking pickup availability: $e');
      }
      // Default to available Monday-Saturday
      return date.weekday <= 6;
    }
  }

  // Get next available pickup dates using database function
  Future<List<DateTime>> getAvailablePickupDates() async {
    try {
      return await ShopConfigService.getAvailablePickupDates();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available pickup dates: $e');
      }
      // Fallback to manual checking
      final List<DateTime> availableDates = [];
      final DateTime now = DateTime.now();
      
      for (int i = 0; i < 7; i++) {
        final date = DateTime(now.year, now.month, now.day + i);
        if (await isPickupAvailable(date)) {
          availableDates.add(date);
        }
      }
      
      return availableDates;
    }
  }

  // Get pickup charge in pence for compatibility
  int get pickupChargeInPence => (_pickupCharge * 100).round();

  // Update shop configuration (admin function)
  Future<void> updateConfig(String configKey, Map<String, dynamic> configValue) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Note: Direct config updates not available in current ShopConfigService
      // This would require implementing an update method in ShopConfigService
      throw UnimplementedError('Shop config updates not implemented');
      // await _loadShopConfig(); // Reload after update
      
      if (kDebugMode) {
        print('Shop configuration updated successfully');
      }
    } catch (e) {
      _setError('Failed to update shop configuration: $e');
      if (kDebugMode) {
        print('Error updating shop configuration: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Get formatted shop address for display
  String get formattedShopAddress {
    return _shopAddress.replaceAll('\n', '\n');
  }

  // Get day name from day number
  static String getDayName(int dayNumber) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayNumber] ?? 'Unknown';
  }

  // Get available days as string list
  List<String> get availableDaysNames {
    return _pickupAvailableDays.map((day) => getDayName(day)).toList();
  }

  // Helper method to extract available days from pickup slots configuration
  List<int> _getAvailableDaysFromSlots(Map<String, dynamic> pickupSlots) {
    final List<int> availableDays = [];
    const dayMap = {
      'monday': 1,
      'tuesday': 2, 
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    
    // Check each day in the pickup slots configuration
    for (final entry in pickupSlots.entries) {
      final dayName = entry.key.toLowerCase();
      final dayConfig = entry.value;
      
      // If this day has available slots, add it to the list
      if (dayMap.containsKey(dayName) && 
          dayConfig is Map<String, dynamic> &&
          dayConfig['available_slots'] is List &&
          (dayConfig['available_slots'] as List).isNotEmpty) {
        availableDays.add(dayMap[dayName]!);
      }
    }
    
    return availableDays;
  }
}