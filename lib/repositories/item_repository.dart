import '../models/item_category.dart';
import '../models/item.dart';
import '../models/service.dart';
import '../services/extracted_data_service.dart';

class ItemRepository {
  final ExtractedDataService _dataService;
  
  // In-memory cache
  final Map<String, ItemCategory> _categoryCache = {};
  final Map<String, Item> _itemCache = {};
  final Map<String, List<Item>> _categoryItemsCache = {};
  
  DateTime? _lastCategoryFetch;
  static const Duration cacheExpiry = Duration(minutes: 15);

  ItemRepository({ExtractedDataService? dataService}) 
      : _dataService = dataService ?? ExtractedDataService();

  /// Get all item categories with caching
  Future<List<ItemCategory>> getAllCategories({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    if (!forceRefresh && 
        _lastCategoryFetch != null && 
        now.difference(_lastCategoryFetch!) < cacheExpiry &&
        _categoryCache.isNotEmpty) {
      return _categoryCache.values.toList();
    }

    try {
      final categories = await _dataService.getItemCategories();
      
      // Update cache
      _categoryCache.clear();
      for (final category in categories) {
        _categoryCache[category.id] = category;
      }
      _lastCategoryFetch = now;
      
      return categories;
    } catch (e) {
      // Return cached data if available on error
      if (_categoryCache.isNotEmpty) {
        return _categoryCache.values.toList();
      }
      rethrow;
    }
  }

  /// Get items by category with caching
  Future<List<Item>> getItemsByCategory(String categoryId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _categoryItemsCache.containsKey(categoryId)) {
      return _categoryItemsCache[categoryId]!;
    }

    try {
      final items = await _dataService.getItemsByCategory(categoryId);
      
      // Update cache
      _categoryItemsCache[categoryId] = items;
      for (final item in items) {
        _itemCache[item.id] = item;
      }
      
      return items;
    } catch (e) {
      // Return cached data if available on error
      if (_categoryItemsCache.containsKey(categoryId)) {
        return _categoryItemsCache[categoryId]!;
      }
      rethrow;
    }
  }

  /// Get a specific item by ID
  Future<Item> getItemById(String itemId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _itemCache.containsKey(itemId)) {
      return _itemCache[itemId]!;
    }

    try {
      final item = await _dataService.getItemById(itemId);
      _itemCache[itemId] = item;
      return item;
    } catch (e) {
      // Return cached data if available on error
      if (_itemCache.containsKey(itemId)) {
        return _itemCache[itemId]!;
      }
      rethrow;
    }
  }

  /// Get a specific category by ID
  Future<ItemCategory> getCategoryById(String categoryId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _categoryCache.containsKey(categoryId)) {
      return _categoryCache[categoryId]!;
    }

    try {
      final category = await _dataService.getCategoryById(categoryId);
      _categoryCache[categoryId] = category;
      return category;
    } catch (e) {
      // Return cached data if available on error
      if (_categoryCache.containsKey(categoryId)) {
        return _categoryCache[categoryId]!;
      }
      rethrow;
    }
  }

  /// Search items by name
  Future<List<Item>> searchItems(String searchTerm) async {
    try {
      final items = await _dataService.searchItems(searchTerm);
      
      // Update item cache with search results
      for (final item in items) {
        _itemCache[item.id] = item;
      }
      
      return items;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all items (useful for offline scenarios)
  Future<List<Item>> getAllItems({bool forceRefresh = false}) async {
    try {
      final items = await _dataService.getAllItems();
      
      // Update cache
      for (final item in items) {
        _itemCache[item.id] = item;
      }
      
      return items;
    } catch (e) {
      // Return cached data if available on error
      if (_itemCache.isNotEmpty) {
        return _itemCache.values.toList();
      }
      rethrow;
    }
  }

  /// Get items by service type (alteration or repair)
  Future<List<Item>> getItemsByServiceType(String serviceType) async {
    try {
      final items = await _dataService.getItemsByServiceType(serviceType);
      
      // Update cache
      for (final item in items) {
        _itemCache[item.id] = item;
      }
      
      return items;
    } catch (e) {
      rethrow;
    }
  }

  /// Get alteration items
  Future<List<Item>> getAlterationItems() async {
    return getItemsByServiceType('alteration');
  }

  /// Get repair items
  Future<List<Item>> getRepairItems() async {
    return getItemsByServiceType('repair');
  }

  /// Get all services for an item
  Future<List<Service>> getServicesForItem(String itemId) async {
    final item = await getItemById(itemId);
    return item.activeServices;
  }

  /// Get alteration services for an item
  Future<List<Service>> getAlterationServicesForItem(String itemId) async {
    final item = await getItemById(itemId);
    return item.alterationServices;
  }

  /// Get repair services for an item
  Future<List<Service>> getRepairServicesForItem(String itemId) async {
    return await _dataService.getRepairServicesForItem(itemId);
  }

  /// Clear all cache
  void clearCache() {
    _categoryCache.clear();
    _itemCache.clear();
    _categoryItemsCache.clear();
    _lastCategoryFetch = null;
  }

  /// Clear specific category cache
  void clearCategoryCache(String categoryId) {
    _categoryItemsCache.remove(categoryId);
  }

  /// Clear specific item cache
  void clearItemCache(String itemId) {
    _itemCache.remove(itemId);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'categories': _categoryCache.length,
      'items': _itemCache.length,
      'categoryItems': _categoryItemsCache.length,
      'lastCategoryFetch': _lastCategoryFetch?.toIso8601String(),
    };
  }

  /// Check if cache is expired
  bool get isCacheExpired {
    if (_lastCategoryFetch == null) return true;
    return DateTime.now().difference(_lastCategoryFetch!) > cacheExpiry;
  }

  void dispose() {
    _dataService.dispose();
    clearCache();
  }
} 