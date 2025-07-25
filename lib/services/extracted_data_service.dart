import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/item_category.dart';
import '../models/item.dart';
import '../models/service.dart';
import '../models/subservice.dart';
import '../models/question.dart';

class ExtractedDataService {
  static ExtractedDataService? _instance;
  
  // Cache for loaded data
  List<ItemCategory>? _categories;
  List<Item>? _allItems;
  Map<String, List<Item>> _categoryItems = {};
  List<Service>? _allServices;
  Map<String, List<Service>> _repairServicesByItem = {};
  Map<String, dynamic>? _fittingGuides;

  ExtractedDataService._internal();

  factory ExtractedDataService() {
    _instance ??= ExtractedDataService._internal();
    return _instance!;
  }

  /// Load all categories from extracted data
  Future<List<ItemCategory>> getItemCategories() async {
    if (_categories != null) {
      return _categories!;
    }

    try {
      final String categoriesJson = await rootBundle.loadString('extracted_data/categories.json');
      final Map<String, dynamic> data = json.decode(categoriesJson);
      
      final List<dynamic> docs = data['docs'] ?? [];
      _categories = docs.map((doc) => ItemCategory.fromJson(doc)).toList();
      
      return _categories!;
    } catch (e) {
      throw Exception('Failed to load categories from extracted data: $e');
    }
  }

  /// Load all items from extracted data
  Future<List<Item>> getAllItems() async {
    if (_allItems != null) {
      return _allItems!;
    }

    try {
      final String itemsJson = await rootBundle.loadString('extracted_data/all_items.json');
      final Map<String, dynamic> data = json.decode(itemsJson);
      
      final List<dynamic> docs = data['docs'] ?? [];
      _allItems = docs.map((doc) => Item.fromJson(doc)).toList();
      
      return _allItems!;
    } catch (e) {
      throw Exception('Failed to load items from extracted data: $e');
    }
  }

  /// Get items by category ID
  Future<List<Item>> getItemsByCategory(String categoryId) async {
    if (_categoryItems.containsKey(categoryId)) {
      return _categoryItems[categoryId]!;
    }

    try {
      // First try to load from category-specific files
      final categories = await getItemCategories();
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => throw Exception('Category not found: $categoryId'),
      );

      // Map category names to file names
      String fileName = _getCategoryFileName(category.name);
      
      try {
        final String itemsJson = await rootBundle.loadString('extracted_data/$fileName');
        final Map<String, dynamic> data = json.decode(itemsJson);
        final List<dynamic> docs = data['docs'] ?? [];
        final items = docs.map((doc) => Item.fromJson(doc)).toList();
        
        _categoryItems[categoryId] = items;
        return items;
      } catch (e) {
        // If category-specific file doesn't exist, filter from all items
        final allItems = await getAllItems();
        final filteredItems = allItems.where((item) {
          return item.itemCategories.any((category) => category.id == categoryId);
        }).toList();
        
        _categoryItems[categoryId] = filteredItems;
        return filteredItems;
      }
    } catch (e) {
      throw Exception('Failed to load items for category $categoryId: $e');
    }
  }

  /// Get a specific item by ID
  Future<Item> getItemById(String itemId) async {
    final allItems = await getAllItems();
    try {
      return allItems.firstWhere((item) => item.id == itemId);
    } catch (e) {
      throw Exception('Item not found: $itemId');
    }
  }

  /// Get a specific category by ID
  Future<ItemCategory> getCategoryById(String categoryId) async {
    final categories = await getItemCategories();
    try {
      return categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      throw Exception('Category not found: $categoryId');
    }
  }

  /// Search items by name
  Future<List<Item>> searchItems(String searchTerm) async {
    final allItems = await getAllItems();
    final lowerSearchTerm = searchTerm.toLowerCase();
    
    return allItems.where((item) {
      return item.name.toLowerCase().contains(lowerSearchTerm);
    }).toList();
  }

  /// Get items with specific service type
  Future<List<Item>> getItemsByServiceType(String serviceType) async {
    final allItems = await getAllItems();
    
    return allItems.where((item) {
      return item.activeServices.any((service) => 
        service.serviceType.toLowerCase() == serviceType.toLowerCase());
    }).toList();
  }

  /// Load all services from extracted data
  Future<List<Service>> getAllServices() async {
    if (_allServices != null) {
      return _allServices!;
    }

    try {
      final String servicesJson = await rootBundle.loadString('extracted_data/services.json');
      final Map<String, dynamic> data = json.decode(servicesJson);
      
      final List<dynamic> services = data['services'] ?? [];
      _allServices = services.map((service) => Service.fromJson(service)).toList();
      
      return _allServices!;
    } catch (e) {
      throw Exception('Failed to load services from extracted data: $e');
    }
  }

  /// Get all repair services
  Future<List<Service>> getRepairServices() async {
    final allServices = await getAllServices();
    return allServices.where((service) => 
      service.serviceType.toLowerCase() == 'repair' && service.active
    ).toList();
  }

  /// Get repair services for a specific item
  Future<List<Service>> getRepairServicesForItem(String itemId) async {
    if (_repairServicesByItem.containsKey(itemId)) {
      return _repairServicesByItem[itemId]!;
    }

    // For now, return all repair services as the extracted data doesn't seem to have
    // item-specific service filtering. In the future, this could be enhanced
    // to filter services based on item type or category.
    final repairServices = await getRepairServices();
    _repairServicesByItem[itemId] = repairServices;
    return repairServices;
  }

  /// Get first category (Hoodie/Sweatshirt)
  Future<ItemCategory> getFirstCategory() async {
    final categories = await getItemCategories();
    return categories.first;
  }

  /// Get first item from first category
  Future<Item> getFirstItemFromFirstCategory() async {
    final firstCategory = await getFirstCategory();
    final items = await getItemsByCategory(firstCategory.id);
    if (items.isEmpty) {
      throw Exception('No items found in first category');
    }
    return items.first;
  }

  /// Get repair services for first item (for demo)
  Future<List<Service>> getFirstItemRepairServices() async {
    final firstItem = await getFirstItemFromFirstCategory();
    return getRepairServicesForItem(firstItem.id);
  }

  /// Get a specific service by ID
  Future<Service> getServiceById(String serviceId) async {
    final allServices = await getAllServices();
    try {
      return allServices.firstWhere((service) => service.id == serviceId);
    } catch (e) {
      throw Exception('Service not found: $serviceId');
    }
  }

  /// Get subservices for a specific service
  Future<List<Subservice>> getSubservicesForService(String serviceId) async {
    final service = await getServiceById(serviceId);
    return service.activeSubservices;
  }

  /// Get questions for a specific service
  Future<List<Question>> getQuestionsForService(String serviceId) async {
    final service = await getServiceById(serviceId);
    return service.questions;
  }

  /// Calculate service price with modifiers
  Future<double> calculateServicePrice(Service service, Map<String, dynamic> selections) async {
    double basePrice = service.priceInDollars;
    
    // Add subservice price modifier if selected
    if (selections['selectedSubservice'] != null) {
      final Subservice subservice = selections['selectedSubservice'];
      basePrice += subservice.priceModifierInDollars;
    }
    
    // Add any question-based price modifiers
    if (selections['answers'] != null) {
      final Map<String, dynamic> answers = selections['answers'];
      // Implementation depends on question structure - for now return base price
      // This can be enhanced based on specific question price modifiers
    }
    
    return basePrice;
  }

  /// Map category names to file names
  String _getCategoryFileName(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'hoodie/ sweatshirt':
        return 'items_hoodie_sweatshirt.json';
      case 'dresses/ jumpsuits':
        return 'items_dresses_jumpsuits.json';
      case 'coats/ jackets':
        return 'items_coats_jackets.json';
      case 'trousers/ jeans':
        return 'items_trousers_jeans.json';
      case 'skirts/ shorts':
        return 'items_skirts_shorts.json';
      case 'jumpers':
        return 'items_jumpers.json';
      case 'knitwear':
        return 'items_knitwear.json';
      case 'suiting':
        return 'items_suiting.json';
      case 'tops':
        return 'items_tops.json';
      default:
        return 'all_items.json';
    }
  }

  /// Load fitting guides from extracted data
  Future<Map<String, dynamic>> getFittingGuides() async {
    if (_fittingGuides != null) {
      return _fittingGuides!;
    }

    try {
      final String guidesJson = await rootBundle.loadString('extracted_data/fitting_guides.json');
      _fittingGuides = json.decode(guidesJson);
      return _fittingGuides!;
    } catch (e) {
      print('Failed to load fitting guides: $e');
      return {};
    }
  }

  /// Get fitting guide for a specific service
  Future<Map<String, dynamic>?> getFittingGuideForService(String serviceId) async {
    final guides = await getFittingGuides();
    final guidesData = guides['guides'] as Map<String, dynamic>?;
    
    if (guidesData != null && guidesData.containsKey(serviceId)) {
      return guidesData[serviceId] as Map<String, dynamic>;
    }
    
    return null;
  }

  /// Check if service has fitting guide for specific method
  Future<bool> hasFittingGuideForMethod(String serviceId, String method) async {
    final guide = await getFittingGuideForService(serviceId);
    if (guide == null) return false;
    
    return guide.containsKey(method.toLowerCase());
  }

  /// Get fitting guide content for specific service and method
  Future<Map<String, dynamic>?> getFittingGuideContent(String serviceId, String method) async {
    final guide = await getFittingGuideForService(serviceId);
    if (guide == null) return null;
    
    final methodKey = method.toLowerCase();
    if (guide.containsKey(methodKey)) {
      return guide[methodKey] as Map<String, dynamic>?;
    }
    
    return null;
  }

  /// Extract text content from fitting guide
  String extractGuideText(Map<String, dynamic>? guideContent) {
    if (guideContent == null) return '';
    
    try {
      final guide = guideContent['guide'] as Map<String, dynamic>?;
      if (guide == null) return '';
      
      final root = guide['root'] as Map<String, dynamic>?;
      if (root == null) return '';
      
      final children = root['children'] as List<dynamic>?;
      if (children == null) return '';
      
      List<String> textParts = [];
      _extractTextFromChildren(children, textParts, isRoot: true);
      
      // Join with newlines for better formatting and remove empty lines
      return textParts.where((text) => text.trim().isNotEmpty).join('\n').trim();
    } catch (e) {
      print('Error extracting guide text: $e');
      return '';
    }
  }

  void _extractTextFromChildren(List<dynamic> children, List<String> textParts, {bool isRoot = false}) {
    for (var child in children) {
      if (child is Map<String, dynamic>) {
        final type = child['type'] as String?;
        
        if (type == 'text') {
          final text = child['text'] as String?;
          if (text != null && text.isNotEmpty) {
            textParts.add(text.trim());
          }
        } else if (type == 'listitem') {
          final childChildren = child['children'] as List<dynamic>?;
          if (childChildren != null) {
            final value = child['value'] as int?;
            List<String> itemTextParts = [];
            _extractTextFromChildren(childChildren, itemTextParts);
            
            if (itemTextParts.isNotEmpty) {
              final itemText = itemTextParts.join(' ').trim();
              if (value != null) {
                textParts.add('$value. $itemText');
              } else {
                textParts.add('• $itemText');
              }
            }
          }
        } else if (type == 'paragraph') {
          final childChildren = child['children'] as List<dynamic>?;
          if (childChildren != null) {
            List<String> paragraphTextParts = [];
            _extractTextFromChildren(childChildren, paragraphTextParts);
            if (paragraphTextParts.isNotEmpty) {
              final paragraphText = paragraphTextParts.join(' ').trim();
              if (paragraphText.isNotEmpty) {
                textParts.add(paragraphText);
              }
            }
          }
        } else if (type == 'list') {
          final childChildren = child['children'] as List<dynamic>?;
          if (childChildren != null) {
            // For lists, extract each item separately
            _extractTextFromChildren(childChildren, textParts);
          }
        } else {
          // Handle other types by recursively extracting from children
          final childChildren = child['children'] as List<dynamic>?;
          if (childChildren != null) {
            _extractTextFromChildren(childChildren, textParts);
          }
        }
      }
    }
  }

  /// Clear cache
  void clearCache() {
    _categories = null;
    _allItems = null;
    _categoryItems.clear();
    _allServices = null;
    _repairServicesByItem.clear();
    _fittingGuides = null;
  }

  void dispose() {
    clearCache();
  }
}