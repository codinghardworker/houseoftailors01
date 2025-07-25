import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopConfigService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cached configuration data
  static Map<String, dynamic>? _cachedConfig;
  
  // Stream controllers for updates
  static final StreamController<Map<String, dynamic>> _configStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Initialization state to prevent multiple inits
  static bool _isInitializing = false;
  static bool _isInitialized = false;
  

  
  // Getters for stream
  static Stream<Map<String, dynamic>> get configStream => _configStreamController.stream;
  
  /// Initialize the service
  static Future<void> initialize() async {
    print('ShopConfigService: Initializing...');
    
    try {
      // Try to load from database first
      await _loadConfigurationWithValidation();
      _isInitialized = true;
      
      print('ShopConfigService: Initialization complete');
    } catch (e) {
      print('ShopConfigService: Initialization error: $e');
      _cachedConfig = {};
      _isInitialized = true;
    }
  }



  /// Initialize the service asynchronously without awaiting
  static void initializeAsync() {
    if (_isInitializing || _isInitialized) return;
    _isInitializing = true;
    
    initialize().then((_) {
      _isInitializing = false;
    }).catchError((e) {
      _isInitializing = false;
      print('ShopConfigService: Async initialization error: $e');
    });
  }

  /// Ensure the service is initialized
  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for ongoing initialization
      while (_isInitializing) {
        await Future.delayed(Duration(milliseconds: 10));
      }
      return;
    }
    await initialize();
  }
  
  /// Load configuration from database with retry logic
  static Future<void> _loadConfigurationWithValidation() async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    
    while (retryCount < maxRetries) {
      try {
        print('ShopConfigService: Loading configuration... (attempt ${retryCount + 1}/$maxRetries)');
        
        final querySnapshot = await _firestore
            .collection('shopConfig')
            .where('is_active', isEqualTo: true)
            .orderBy('updated_at', descending: true)
            .get();
            
        final response = querySnapshot.docs.map((doc) => doc.data()).toList();
        
        if (response.isNotEmpty) {
          final Map<String, dynamic> config = {};
          
          // Convert list of records to key-value map
          for (final record in response) {
            final key = record['config_key'] as String;
            final value = record['config_value'];
            config[key] = value;
          }
          
          _cachedConfig = config;
          print('ShopConfigService: ✅ Configuration loaded successfully: ${_cachedConfig?.keys}');
          
          // Notify listeners
          if (!_configStreamController.isClosed) {
            _configStreamController.add(_cachedConfig!);
          }
          return; // Success - exit retry loop
        } else {
          print('ShopConfigService: ⚠️ No configuration data found in database');
          _cachedConfig = {};
          if (!_configStreamController.isClosed) {
            _configStreamController.add(_cachedConfig!);
          }
          return; // No data but no error - exit retry loop
        }
      } catch (e) {
        retryCount++;
        print('ShopConfigService: ❌ Error loading configuration (attempt $retryCount): $e');
        
        if (retryCount < maxRetries) {
          print('ShopConfigService: Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        } else {
          print('ShopConfigService: ❌ All retry attempts failed, using empty config');
          _cachedConfig = {};
          if (!_configStreamController.isClosed) {
            _configStreamController.add(_cachedConfig!);
          }
        }
      }
    }
  }

  /// Validate configuration data for correctness
  static void _validateConfigurationData(Map<String, dynamic> config) {
    print('ShopConfigService: Validating configuration data...');
    
    // Validate shop_info
    final shopInfo = config['shop_info'];
    if (shopInfo is Map<String, dynamic>) {
      print('✅ Shop info: ${shopInfo['name'] ?? 'No name'}');
    } else {
      print('⚠️ Shop info missing or invalid');
    }
    
    // Validate delivery_options
    final deliveryOptions = config['delivery_options'];
    if (deliveryOptions is Map<String, dynamic>) {
      final pickupCharge = deliveryOptions['pickup_charge_pence'];
      final postCharge = deliveryOptions['post_delivery_charge_pence'];
      final methods = deliveryOptions['available_methods'];
      
      print('✅ Delivery options: Pickup ${pickupCharge}p, Post ${postCharge}p, Methods: $methods');
    } else {
      print('⚠️ Delivery options missing or invalid');
    }
    
    // Validate pickup_slots
    final pickupSlots = config['pickup_slots'];
    if (pickupSlots is Map<String, dynamic>) {
      final days = pickupSlots.keys.length;
      print('✅ Pickup slots configured for $days days');
    } else {
      print('⚠️ Pickup slots missing or invalid');
    }
    
    // Validate available_locations
    final locations = config['available_locations'];
    if (locations is Map<String, dynamic>) {
      final cities = locations['cities'];
      if (cities is List) {
        print('✅ Available locations: ${cities.length} cities');
      }
    } else {
      print('⚠️ Available locations missing or invalid');
    }
  }
  
  /// Get all configuration data
  static Map<String, dynamic>? getAllConfig() {
    return _cachedConfig;
  }
  
  /// Get specific configuration by key
  static dynamic getConfig(String key) {
    return _cachedConfig?[key];
  }
  
  /// Get shop info
  static Map<String, dynamic>? getShopInfo() {
    final shopInfo = getConfig('shop_info');
    return shopInfo is Map<String, dynamic> ? shopInfo : null;
  }
  
  /// Get delivery options
  static Map<String, dynamic>? getDeliveryOptions() {
    final deliveryOptions = getConfig('delivery_options');
    return deliveryOptions is Map<String, dynamic> ? deliveryOptions : null;
  }
  
  /// Get pickup charge in pence
  static int getPickupChargePence() {
    final deliveryOptions = getDeliveryOptions();
    final charge = deliveryOptions?['pickup_charge_pence'] as int?;
    print('ShopConfigService: Getting pickup charge: ${charge}p');
    return charge ?? 0;
  }
  
  /// Get post delivery charge in pence
  static int getPostDeliveryChargePence() {
    final deliveryOptions = getDeliveryOptions();
    final charge = deliveryOptions?['post_delivery_charge_pence'] as int?;
    return charge ?? 0;
  }
  
  /// Get available delivery methods  
  static List<String> getAvailableDeliveryMethods() {
    final deliveryOptions = getDeliveryOptions();
    final methods = deliveryOptions?['available_methods'] as List?;
    return methods?.cast<String>() ?? [];
  }
  
  /// Get pickup slots configuration
  static Map<String, dynamic>? getPickupSlots() {
    final pickupSlots = getConfig('pickup_slots');
    return pickupSlots is Map<String, dynamic> ? pickupSlots : null;
  }
  
  /// Get available pickup slots for a specific day
  static List<String> getPickupSlotsForDay(String dayOfWeek) {
    final pickupSlots = getPickupSlots();
    final daySlots = pickupSlots?[dayOfWeek.toLowerCase()] as Map<String, dynamic>?;
    final slots = daySlots?['available_slots'] as List?;
    final result = slots?.cast<String>() ?? [];
    print('ShopConfigService: Slots for $dayOfWeek: $result');
    return result;
  }
  
  /// Get available locations
  static Map<String, dynamic>? getAvailableLocations() {
    final locations = getConfig('available_locations');
    return locations is Map<String, dynamic> ? locations : null;
  }
  
  /// Get cities list
  static List<Map<String, dynamic>> getCities() {
    final locations = getAvailableLocations();
    final cities = locations?['cities'] as List?;
    return cities?.cast<Map<String, dynamic>>() ?? [];
  }
  
  /// Get towns for a specific city
  static List<String> getTownsForCity(String cityId) {
    final cities = getCities();
    for (final city in cities) {
      if (city['id'] == cityId) {
        final towns = city['towns'] as List?;
        return towns?.cast<String>() ?? [];
      }
    }
    return [];
  }
  
  /// Check if a delivery method is available
  static bool isDeliveryMethodAvailable(String method) {
    return getAvailableDeliveryMethods().contains(method);
  }
  
  /// Get next available pickup dates (excludes Sundays and past dates)
  static List<DateTime> getAvailablePickupDates({int daysAhead = 14}) {
    final List<DateTime> availableDates = [];
    final DateTime now = DateTime.now();
    
    for (int i = 1; i <= daysAhead; i++) {
      final DateTime date = now.add(Duration(days: i));
      final String dayName = _getDayName(date.weekday);
      
      // Check if the day has available slots
      final slots = getPickupSlotsForDay(dayName);
      if (slots.isNotEmpty) {
        availableDates.add(date);
      }
    }
    
    return availableDates;
  }
  
  /// Get available pickup slots for a specific date
  static List<String> getAvailablePickupSlots({DateTime? selectedDate}) {
    if (selectedDate == null) return [];
    
    final String dayName = _getDayName(selectedDate.weekday);
    return getPickupSlotsForDay(dayName);
  }
  
  /// Check if pickup is available on a specific date
  static bool isPickupAvailable(DateTime date) {
    final String dayName = _getDayName(date.weekday);
    final slots = getPickupSlotsForDay(dayName);
    return slots.isNotEmpty;
  }
  
  /// Get delivery charges in pounds
  static Map<String, double> getDeliveryCharges() {
    return {
      'pickup': getPickupChargePence() / 100.0, // Convert pence to pounds
      'post': getPostDeliveryChargePence() / 100.0,
    };
  }
  
  /// Get shop location information  
  static Map<String, String> getShopLocation() {
    final shopInfo = getShopInfo();
    
    if (shopInfo == null) {
      return {
        'name': '',
        'address': '',
        'phone': '',
        'email': '',
      };
    }
    
    // Build formatted address from shop info
    final addressParts = <String>[];
    if (shopInfo['address_line1'] != null) addressParts.add(shopInfo['address_line1']);
    if (shopInfo['address_line2'] != null) addressParts.add(shopInfo['address_line2']);
    if (shopInfo['city'] != null) addressParts.add(shopInfo['city']);
    if (shopInfo['postal_code'] != null) addressParts.add(shopInfo['postal_code']);
    if (shopInfo['country'] != null) addressParts.add(shopInfo['country']);
    
    final formattedAddress = addressParts.join('\n');
    
    return {
      'name': shopInfo['name'] ?? '',
      'address': formattedAddress,
      'phone': shopInfo['phone'] ?? '',
      'email': shopInfo['email'] ?? '',
    };
  }
  
  /// Convert weekday number to day name
  static String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
  
  /// Dispose resources
  static void dispose() {
    _configStreamController.close();
    _cachedConfig = null;
    _isInitialized = false;
    _isInitializing = false;
    print('🛑 ShopConfigService: All resources disposed');
  }
  
  /// Force refresh configuration from database
  static Future<void> refresh() async {
    print('🔄 ShopConfigService: Force refreshing configuration...');
    try {
      await _loadConfigurationWithValidation();
      print('✅ ShopConfigService: Force refresh completed');
    } catch (e) {
      print('❌ ShopConfigService: Error during refresh: $e');
      _cachedConfig = {};
    }
  }
  
  /// Get connection status for debugging
  static Map<String, dynamic> getConnectionStatus() {
    return {
      'hasCache': _cachedConfig != null,
      'cacheKeys': _cachedConfig?.keys.toList() ?? [],
      'streamHasListeners': _configStreamController.hasListener,
      'isInitialized': _isInitialized,
      'isInitializing': _isInitializing,
    };
  }
}