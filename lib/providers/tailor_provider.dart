import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Garment Category Model
class GarmentCategory {
  final String name;
  final IconData icon;
  final String imageUrl;
  final String id;

  const GarmentCategory({
    required this.name,
    required this.icon,
    required this.imageUrl,
    required this.id,
  });

  // Create a copy with updated properties
  GarmentCategory copyWith({
    String? name,
    IconData? icon,
    String? imageUrl,
    String? id,
  }) {
    return GarmentCategory(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      id: id ?? this.id,
    );
  }
}

// Tailor Provider for State Management
class TailorProvider extends ChangeNotifier {
  // Categories data
  final List<GarmentCategory> _categories = [
    const GarmentCategory(
      id: 'hoodie_sweatshirt',
      name: 'Hoodie/ sweatshirt',
      icon: Icons.checkroom,
      imageUrl: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400&h=400&fit=crop&crop=center',
    ),
    const GarmentCategory(
      id: 'skirts_shorts',
      name: 'Skirts / Shorts',
      icon: Icons.woman,
      imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=400&fit=crop&crop=center',
    ),
    const GarmentCategory(
      id: 'suiting',
      name: 'Suiting',
      icon: Icons.business_center,
      imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400&h=400&fit=crop&crop=center',
    ),
    const GarmentCategory(
      id: 'dresses_jumpsuits',
      name: 'Dresses / Jumpsuits',
      icon: Icons.woman_2,
      imageUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&h=400&fit=crop&crop=center',
    ),
    const GarmentCategory(
      id: 'coats_jackets',
      name: 'Coats / Jackets',
      icon: Icons.outdoor_grill,
      imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400&h=400&fit=crop&crop=center',
    ),
    const GarmentCategory(
      id: 'knitwear',
      name: 'Knitwear',
      icon: Icons.style,
      imageUrl: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400&h=400&fit=crop&crop=center',
    ),
    const GarmentCategory(
      id: 'trousers_jeans',
      name: 'Trousers / Jeans',
      icon: Icons.person,
      imageUrl: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400&h=400&fit=crop&crop=center',
    ),
    const GarmentCategory(
      id: 'tops',
      name: 'Tops',
      icon: Icons.checkroom_outlined,
      imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop&crop=center',
    ),
    const GarmentCategory(
      id: 'jumpers',
      name: 'Jumpers',
      icon: Icons.style_outlined,
      imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400&h=400&fit=crop&crop=center',
    ),
  ];

  // State variables
  String? _selectedCategoryId;
  String? _pressedCategoryId;
  bool _isLoading = false;
  bool _isNavigating = false;

  // Getters
  List<GarmentCategory> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get pressedCategoryId => _pressedCategoryId;
  bool get isLoading => _isLoading;
  bool get isNavigating => _isNavigating;

  // Get selected category object
  GarmentCategory? get selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((category) => category.id == _selectedCategoryId);
    } catch (e) {
      return null;
    }
  }

  // Get category by ID
  GarmentCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get category by name
  GarmentCategory? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }

  // Selection management
  void selectCategory(String categoryId) {
    if (_selectedCategoryId != categoryId) {
      _selectedCategoryId = categoryId;
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedCategoryId != null) {
      _selectedCategoryId = null;
      notifyListeners();
    }
  }

  // Press state management (for UI feedback)
  void setPressedCategory(String? categoryId) {
    if (_pressedCategoryId != categoryId) {
      _pressedCategoryId = categoryId;
      notifyListeners();
    }
  }

  // Loading state management
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Navigation state management
  void setNavigating(bool navigating) {
    if (_isNavigating != navigating) {
      _isNavigating = navigating;
      notifyListeners();
    }
  }

  // Category interaction methods
  void onCategoryTapDown(String categoryName) {
    final category = getCategoryByName(categoryName);
    if (category != null) {
      setPressedCategory(category.id);
    }
  }

  void onCategoryTapUp(String categoryName) {
    final category = getCategoryByName(categoryName);
    if (category != null) {
      setPressedCategory(null);
      selectCategory(category.id);
      proceedToNextStep(category.id);
    }
  }

  void onCategoryTapCancel() {
    setPressedCategory(null);
  }

  // Navigation flow
  Future<void> proceedToNextStep(String categoryId) async {
    setNavigating(true);
    
    // Simulate navigation delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Log the selected category
    final category = getCategoryById(categoryId);
    if (category != null) {
      debugPrint('Selected category: ${category.name} (ID: ${category.id})');
      // TODO: Navigate to service selection screen
      // Navigator.pushNamed(context, '/service_selection', arguments: category);
    }
    
    setNavigating(false);
  }

  // Utility methods
  bool isCategoryPressed(String categoryName) {
    final category = getCategoryByName(categoryName);
    return category != null && _pressedCategoryId == category.id;
  }

  bool isCategorySelected(String categoryName) {
    final category = getCategoryByName(categoryName);
    return category != null && _selectedCategoryId == category.id;
  }

  // Reset all states
  void reset() {
    _selectedCategoryId = null;
    _pressedCategoryId = null;
    _isLoading = false;
    _isNavigating = false;
    notifyListeners();
  }

  // Get categories count
  int get categoriesCount => _categories.length;

  // Search categories
  List<GarmentCategory> searchCategories(String query) {
    if (query.isEmpty) return _categories;
    
    return _categories.where((category) =>
      category.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
} 