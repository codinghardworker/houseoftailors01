import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Item Category Model
class ItemCategory {
  final String id;
  final String name;
  final String? coverImageUrl;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const ItemCategory({
    required this.id,
    required this.name,
    this.coverImageUrl,
    this.updatedAt,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'coverImageUrl': coverImageUrl,
    'updatedAt': updatedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  factory ItemCategory.fromJson(Map<String, dynamic> json) => ItemCategory(
    id: json['id'],
    name: json['name'],
    coverImageUrl: json['coverImageUrl'],
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );
}

// Question Option Model
class QuestionOption {
  final String id;
  final String answer;
  final double priceModifier;
  final int tailorPointsModifier;

  const QuestionOption({
    required this.id,
    required this.answer,
    required this.priceModifier,
    required this.tailorPointsModifier,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'answer': answer,
    'priceModifier': priceModifier,
    'tailorPointsModifier': tailorPointsModifier,
  };

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
    id: json['id'],
    answer: json['answer'],
    priceModifier: json['priceModifier'].toDouble(),
    tailorPointsModifier: json['tailorPointsModifier'],
  );
}

// Question Model
class Question {
  final String id;
  final String question;
  final String? explainer;
  final String questionType;
  final List<QuestionOption> options;

  const Question({
    required this.id,
    required this.question,
    this.explainer,
    required this.questionType,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'explainer': explainer,
    'questionType': questionType,
    'options': options.map((option) => option.toJson()).toList(),
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'],
    question: json['question'],
    explainer: json['explainer'],
    questionType: json['questionType'],
    options: (json['options'] as List).map((option) => QuestionOption.fromJson(option)).toList(),
  );
}

// Subservice Model
class Subservice {
  final String id;
  final String name;
  final List<String>? fittingChoices;
  final double priceModifier;
  final int tailorPointsModifier;
  final List<Question> questions;
  final bool active;
  final String? description;
  final bool deadEnd;
  final String? coverImageUrl;

  const Subservice({
    required this.id,
    required this.name,
    this.fittingChoices,
    required this.priceModifier,
    required this.tailorPointsModifier,
    required this.questions,
    required this.active,
    this.description,
    required this.deadEnd,
    this.coverImageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fittingChoices': fittingChoices,
    'priceModifier': priceModifier,
    'tailorPointsModifier': tailorPointsModifier,
    'questions': questions.map((q) => q.toJson()).toList(),
    'active': active,
    'description': description,
    'deadEnd': deadEnd,
    'coverImageUrl': coverImageUrl,
  };

  factory Subservice.fromJson(Map<String, dynamic> json) => Subservice(
    id: json['id'],
    name: json['name'],
    fittingChoices: json['fittingChoices']?.cast<String>(),
    priceModifier: json['priceModifier'].toDouble(),
    tailorPointsModifier: json['tailorPointsModifier'],
    questions: (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
    active: json['active'],
    description: json['description'],
    deadEnd: json['deadEnd'],
    coverImageUrl: json['coverImageUrl'],
  );
}

// Service Model
class Service {
  final String id;
  final String name;
  final String serviceType;
  final List<String> fittingChoices;
  final double price;
  final int tailorPoints;
  final List<Question> questions;
  final List<Subservice> subservices;
  final bool active;
  final String? description;
  final String? productDescription; // User's description from case 2
  final bool deadEnd;
  final String? coverImageUrl;

  const Service({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.fittingChoices,
    required this.price,
    required this.tailorPoints,
    required this.questions,
    required this.subservices,
    required this.active,
    this.description,
    this.productDescription,
    required this.deadEnd,
    this.coverImageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'serviceType': serviceType,
    'fittingChoices': fittingChoices,
    'price': price,
    'tailorPoints': tailorPoints,
    'questions': questions.map((q) => q.toJson()).toList(),
    'subservices': subservices.map((s) => s.toJson()).toList(),
    'active': active,
    'description': description,
    'productDescription': productDescription,
    'deadEnd': deadEnd,
    'coverImageUrl': coverImageUrl,
  };

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'],
    name: json['name'],
    serviceType: json['serviceType'],
    fittingChoices: json['fittingChoices'].cast<String>(),
    price: json['price'].toDouble(),
    tailorPoints: json['tailorPoints'],
    questions: (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
    subservices: (json['subservices'] as List).map((s) => Subservice.fromJson(s)).toList(),
    active: json['active'],
    description: json['description'],
    productDescription: json['productDescription'],
    deadEnd: json['deadEnd'],
    coverImageUrl: json['coverImageUrl'],
  );
}

// Question Answer Model
class QuestionAnswer {
  final String question;
  final String answer;
  final String? answerId;
  final String? questionId;
  final double priceModifier;
  final int tailorPointsModifier;
  final String? textResponse; // For text input questions
  final bool isTextInput; // Flag to identify text input questions

  QuestionAnswer({
    required this.question,
    required this.answer,
    this.answerId,
    this.questionId,
    required this.priceModifier,
    required this.tailorPointsModifier,
    this.textResponse,
    this.isTextInput = false,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    'answerId': answerId,
    'questionId': questionId,
    'priceModifier': priceModifier,
    'tailorPointsModifier': tailorPointsModifier,
    'textResponse': textResponse,
    'isTextInput': isTextInput,
  };

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) => QuestionAnswer(
    question: json['question'],
    answer: json['answer'],
    answerId: json['answerId'],
    questionId: json['questionId'],
    priceModifier: json['priceModifier'].toDouble(),
    tailorPointsModifier: json['tailorPointsModifier'],
    textResponse: json['textResponse'],
    isTextInput: json['isTextInput'] ?? false,
  );

  // Create question answer from database order data
  factory QuestionAnswer.fromDatabase(Map<String, dynamic> data) {
    return QuestionAnswer(
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      priceModifier: ((data['priceModifier'] as num?)?.toDouble() ?? 0.0) / 100.0,
      tailorPointsModifier: 0,
      textResponse: data['textResponse'],
      isTextInput: data['isTextInput'] ?? false,
    );
  }
}

// Service Details Model
class ServiceDetails {
  final Service service;
  final double basePrice; // Original service base price before modifiers
  final String? fittingChoice;
  final String? fittingDetails;
  final String? repairLocation;
  final String tailorNotes;
  final List<QuestionAnswer> questionAnswerModifiers;
  final SubserviceDetails? subserviceDetails;
  final String? serviceDescription; // User's description from case 2 (color, material, etc.)
  final String serviceType; // Service type (repair, alteration, etc.)
  final String? serviceCoverImageUrl; // Service cover image for order reference
  // Delivery information
  final String? deliveryMethod; // 'pickup' or 'post'
  final DateTime? pickupDate; // Selected pickup date
  final String? pickupTime; // Selected pickup time slot
  final double? pickupCost; // Pickup service cost in pounds

  ServiceDetails({
    required this.service,
    required this.basePrice,
    this.fittingChoice,
    this.fittingDetails,
    this.repairLocation,
    this.tailorNotes = '',
    required this.questionAnswerModifiers,
    this.subserviceDetails,
    this.serviceDescription,
    required this.serviceType,
    this.serviceCoverImageUrl,
    this.deliveryMethod,
    this.pickupDate,
    this.pickupTime,
    this.pickupCost,
  });

  Map<String, dynamic> toJson() {
    // Debug: Check notes during serialization
    print('SERVICE DETAILS toJson DEBUG: tailorNotes being serialized: "$tailorNotes"');
    print('SERVICE DETAILS toJson DEBUG: tailorNotes length: ${tailorNotes.length}');
    
    return {
      'service': service.toJson(),
      'basePrice': basePrice,
      'fittingChoice': fittingChoice,
      'fittingDetails': fittingDetails,
      'repairLocation': repairLocation,
      'tailorNotes': tailorNotes,
      'questionAnswerModifiers': questionAnswerModifiers.map((qa) => qa.toJson()).toList(),
      'subserviceDetails': subserviceDetails?.toJson(),
      'serviceDescription': serviceDescription,
      'serviceType': serviceType,
      'serviceCoverImageUrl': serviceCoverImageUrl,
      'deliveryMethod': deliveryMethod,
      'pickupDate': pickupDate?.toIso8601String(),
      'pickupTime': pickupTime,
      'pickupCost': pickupCost,
    };
  }

  factory ServiceDetails.fromJson(Map<String, dynamic> json) => ServiceDetails(
    service: Service.fromJson(json['service']),
    basePrice: json['basePrice'].toDouble(),
    fittingChoice: json['fittingChoice'],
    fittingDetails: json['fittingDetails'],
    repairLocation: json['repairLocation'],
    tailorNotes: json['tailorNotes'] ?? '',
    questionAnswerModifiers: (json['questionAnswerModifiers'] as List).map((qa) => QuestionAnswer.fromJson(qa)).toList(),
    subserviceDetails: json['subserviceDetails'] != null ? SubserviceDetails.fromJson(json['subserviceDetails']) : null,
    serviceDescription: json['serviceDescription'],
    serviceType: json['serviceType'] ?? 'repair',
    serviceCoverImageUrl: json['serviceCoverImageUrl'],
    deliveryMethod: json['deliveryMethod'],
    pickupDate: json['pickupDate'] != null ? DateTime.parse(json['pickupDate']) : null,
    pickupTime: json['pickupTime'],
    pickupCost: json['pickupCost']?.toDouble(),
  );

  // Create service details from database order data
  factory ServiceDetails.fromDatabase(Map<String, dynamic> data) {
    final questionAnswers = data['questionAnswers'] as List<dynamic>? ?? [];
    final subserviceData = data['subserviceDetails'] as Map<String, dynamic>?;
    
    return ServiceDetails(
      service: Service(
        id: data['serviceId'] ?? '',
        name: data['serviceName'] ?? '',
        serviceType: 'service',
        fittingChoices: [],
        price: ((data['totalPrice'] as num?)?.toDouble() ?? 0.0) / 100.0,
        tailorPoints: 0,
        questions: [],
        subservices: [],
        active: true,
        deadEnd: false,
      ),
      basePrice: ((data['basePrice'] as num?)?.toDouble() ?? 0.0) / 100.0,
      tailorNotes: data['tailorNotes'] ?? '',
      questionAnswerModifiers: questionAnswers.map((qa) => QuestionAnswer.fromDatabase(qa)).toList(),
      subserviceDetails: subserviceData != null ? SubserviceDetails.fromDatabase(subserviceData) : null,
      serviceType: 'service',
      fittingChoice: data['fittingChoice'],
      fittingDetails: data['fittingDetails'],
      repairLocation: data['repairLocation'],
      serviceDescription: data['serviceDescription'],
      deliveryMethod: data['deliveryMethod'],
      pickupDate: data['pickupDate'] != null ? DateTime.parse(data['pickupDate']) : null,
      pickupTime: data['pickupTime'],
      pickupCost: data['pickupCost']?.toDouble(),
    );
  }

  double get totalPrice {
    // Simply return the service price as it already contains the complete calculated total
    return service.price;
  }

  int get totalTailorPoints {
    int total = service.tailorPoints;
    
    // Add question modifiers
    for (var modifier in questionAnswerModifiers) {
      total += modifier.tailorPointsModifier;
    }
    
    // Add subservice modifiers if present
    if (subserviceDetails != null) {
      total += subserviceDetails!.subservice.tailorPointsModifier;
      for (var modifier in subserviceDetails!.questionAnswerModifiers) {
        total += modifier.tailorPointsModifier;
      }
    }
    
    return total;
  }
}

// Subservice Details Model
class SubserviceDetails {
  final Subservice subservice;
  final List<QuestionAnswer> questionAnswerModifiers;

  const SubserviceDetails({
    required this.subservice,
    required this.questionAnswerModifiers,
  });

  Map<String, dynamic> toJson() => {
    'subservice': subservice.toJson(),
    'questionAnswerModifiers': questionAnswerModifiers.map((qa) => qa.toJson()).toList(),
  };

  factory SubserviceDetails.fromJson(Map<String, dynamic> json) => SubserviceDetails(
    subservice: Subservice.fromJson(json['subservice']),
    questionAnswerModifiers: (json['questionAnswerModifiers'] as List).map((qa) => QuestionAnswer.fromJson(qa)).toList(),
  );

  // Create subservice details from database order data
  factory SubserviceDetails.fromDatabase(Map<String, dynamic> data) {
    final questionAnswers = data['questionAnswers'] as List<dynamic>? ?? [];
    
    return SubserviceDetails(
      subservice: Subservice(
        id: data['subserviceId'] ?? '',
        name: data['subserviceName'] ?? '',
        priceModifier: ((data['priceModifier'] as num?)?.toDouble() ?? 0.0) / 100.0,
        tailorPointsModifier: 0,
        description: '',
        questions: [],
        active: true,
        deadEnd: false,
      ),
      questionAnswerModifiers: questionAnswers.map((qa) => QuestionAnswer.fromDatabase(qa)).toList(),
    );
  }
}

// Cart Item Model
class CartItem {
  final ItemCategory itemCategory;
  final String itemDescription;
  final Service item;
  final List<ServiceDetails> serviceDetails;
  final String? discountCode;
  final DateTime createdAt; // When the item was added to cart
  final Map<String, dynamic> orderMetadata; // Additional order information

  CartItem({
    required this.itemCategory,
    required this.itemDescription,
    required this.item,
    required this.serviceDetails,
    this.discountCode,
    DateTime? createdAt,
    Map<String, dynamic>? orderMetadata,
  }) : createdAt = createdAt ?? DateTime.now(),
       orderMetadata = orderMetadata ?? const {};

  Map<String, dynamic> toJson() => {
    'itemCategory': itemCategory.toJson(),
    'itemDescription': itemDescription,
    'item': item.toJson(),
    'serviceDetails': serviceDetails.map((sd) => sd.toJson()).toList(),
    'discountCode': discountCode,
    'createdAt': createdAt.toIso8601String(),
    'orderMetadata': orderMetadata,
    'priceBreakdown': _getPriceBreakdown(),
    'totalPrice': totalPrice,
    'totalTailorPoints': totalTailorPoints,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    itemCategory: ItemCategory.fromJson(json['itemCategory']),
    itemDescription: json['itemDescription'],
    item: Service.fromJson(json['item']),
    serviceDetails: (json['serviceDetails'] as List).map((sd) => ServiceDetails.fromJson(sd)).toList(),
    discountCode: json['discountCode'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    orderMetadata: json['orderMetadata'] ?? {},
  );

  // Create cart item from database order data
  factory CartItem.fromDatabase(Map<String, dynamic> data) {
    final categoryData = data['itemCategory'] as Map<String, dynamic>? ?? {};
    final servicesData = data['services'] as List<dynamic>? ?? [];
    
    return CartItem(
      itemCategory: ItemCategory(
        id: categoryData['id'] ?? '',
        name: categoryData['name'] ?? '',
      ),
      itemDescription: data['itemDescription'] ?? '',
      item: Service(
        id: data['itemId'] ?? '',
        name: data['itemName'] ?? '',
        serviceType: 'item',
        fittingChoices: [],
        price: ((data['itemTotal'] as num?)?.toDouble() ?? 0.0) / 100.0,
        tailorPoints: 0,
        questions: [],
        subservices: [],
        active: true,
        deadEnd: false,
      ),
      serviceDetails: servicesData.map((serviceData) => ServiceDetails.fromDatabase(serviceData)).toList(),
    );
  }

  double get totalPrice {
    return serviceDetails.fold(0.0, (sum, service) => sum + service.totalPrice);
  }

  int get totalTailorPoints {
    return serviceDetails.fold(0, (sum, service) => sum + service.totalTailorPoints);
  }

  // Generate detailed price breakdown for order processing
  Map<String, dynamic> _getPriceBreakdown() {
    return {
      'basePrice': serviceDetails.fold(0.0, (sum, service) => sum + service.basePrice),
      'questionModifiers': serviceDetails.fold(0.0, (sum, service) => 
        sum + service.questionAnswerModifiers.fold(0.0, (qSum, qa) => qSum + qa.priceModifier)
      ),
      'subserviceModifiers': serviceDetails.fold(0.0, (sum, service) => 
        sum + (service.subserviceDetails?.subservice.priceModifier ?? 0.0)
      ),
      'totalModifiers': serviceDetails.fold(0.0, (sum, service) => 
        sum + service.questionAnswerModifiers.fold(0.0, (qSum, qa) => qSum + qa.priceModifier) +
        (service.subserviceDetails?.subservice.priceModifier ?? 0.0)
      ),
      'finalTotal': totalPrice,
      'serviceCount': serviceDetails.length,
    };
  }
}

// Cart Provider for State Management
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  static const String _cartKey = 'cart_items';
  double _loyaltyDiscount = 0.0;
  bool _loyaltyDiscountApplied = false;

  // Constructor
  CartProvider() {
    loadCartFromStorage();
  }

  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (count, item) => count + item.serviceDetails.length);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get loyaltyDiscount => _loyaltyDiscount;
  bool get loyaltyDiscountApplied => _loyaltyDiscountApplied;
  double get total => (subtotal - _loyaltyDiscount).clamp(0.0, double.infinity);
  int get totalTailorPoints => _items.fold(0, (sum, item) => sum + item.totalTailorPoints);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  // Public method to manually reload cart from storage
  Future<void> reloadCartFromStorage() async {
    await loadCartFromStorage();
  }

  // Initialize cart from localStorage
  Future<void> loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);
      if (cartData != null && cartData.isNotEmpty) {
        final List<dynamic> cartJson = jsonDecode(cartData);
        _items = cartJson.map((item) => CartItem.fromJson(item)).toList();
    notifyListeners();
      } else {
      }
    } catch (e) {
      print('Error loading cart from storage: $e');
    }
  }

  // Save cart to localStorage
  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = _items.map((item) => item.toJson()).toList();
      final cartJsonString = jsonEncode(cartJson);
      await prefs.setString(_cartKey, cartJsonString);
    } catch (e) {
      print('Error saving cart to storage: $e');
    }
  }

  // Filter out text-based dynamic questions that should not be stored in cart
  List<QuestionAnswer> _filterQuestionAnswers(List<QuestionAnswer> questionAnswers) {
    return questionAnswers.where((qa) {
      // Keep all questions including text-based ones
      return true;
    }).toList();
  }

  // Add item to cart with smart grouping
  void addItem(CartItem item) {
    // Debug: Check notes in cart item being added
    for (var service in item.serviceDetails) {
      print('CART PROVIDER DEBUG: Adding service "${service.service.name}" with notes: "${service.tailorNotes}"');
      print('CART PROVIDER DEBUG: Notes length: ${service.tailorNotes.length}');
    }
    
    // Look for existing item with same itemDescription (same item)
    int existingItemIndex = -1;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].itemDescription == item.itemDescription) {
        existingItemIndex = i;
        break;
      }
    }
    
    if (existingItemIndex != -1) {
      // Found existing item, check if service already exists
      final existingItem = _items[existingItemIndex];
      final newService = item.serviceDetails.first;
      
      // Check if this exact service already exists
      bool serviceExists = existingItem.serviceDetails.any(
        (service) => service.service.name == newService.service.name
      );
      
      if (serviceExists) {
        // Same item + same service = create separate entry
        _items.add(item);
      } else {
        // Same item + different service = group together
        final updatedServices = List<ServiceDetails>.from(existingItem.serviceDetails);
        updatedServices.addAll(item.serviceDetails);
        
        final updatedItem = CartItem(
          itemCategory: existingItem.itemCategory,
          itemDescription: existingItem.itemDescription,
          item: existingItem.item,
          serviceDetails: updatedServices,
          discountCode: existingItem.discountCode,
          createdAt: existingItem.createdAt,
          orderMetadata: existingItem.orderMetadata,
        );
        
        _items[existingItemIndex] = updatedItem;
      }
    } else {
      // Different item = always separate
      _items.add(item);
    }
    
    _saveCartToStorage();
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _saveCartToStorage();
    notifyListeners();
    }
  }

  // Remove individual service from an item
  void removeService(int itemIndex, int serviceIndex) {
    if (itemIndex >= 0 && itemIndex < _items.length) {
      final item = _items[itemIndex];
      if (serviceIndex >= 0 && serviceIndex < item.serviceDetails.length) {
        final updatedServiceDetails = List<ServiceDetails>.from(item.serviceDetails);
        updatedServiceDetails.removeAt(serviceIndex);
        
        // If no services left, remove the entire item
        if (updatedServiceDetails.isEmpty) {
          _items.removeAt(itemIndex);
        } else {
          // Update the item with remaining services
          final updatedItem = CartItem(
            itemCategory: item.itemCategory,
            itemDescription: item.itemDescription,
            item: item.item,
            serviceDetails: updatedServiceDetails,
            discountCode: item.discountCode,
          );
          _items[itemIndex] = updatedItem;
        }
        
        _saveCartToStorage();
        notifyListeners();
      }
    }
  }

  // Update item in cart
  void updateItem(int index, CartItem updatedItem) {
    if (index >= 0 && index < _items.length) {
      _items[index] = updatedItem;
      _saveCartToStorage();
      notifyListeners();
    }
  }

  // Clear all items from cart
  void clearCart() {
    _items.clear();
    _saveCartToStorage();
    notifyListeners();
  }

  // Format price for display
  String formatPrice(double price) {
    return '£${(price / 100).toStringAsFixed(2)}';
  }

  // Force save cart to storage (public method)
  Future<void> saveCart() async {
    await _saveCartToStorage();
  }

  // Test method to check if localStorage is working
  Future<void> testLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Test write
      await prefs.setString('test_key', 'test_value');
      print('Test write successful');
      
      // Test read
      final testValue = prefs.getString('test_key');
      print('Test read: $testValue');
      
      // Check current cart data
      final cartData = prefs.getString(_cartKey);
      
    } catch (e) {
      print('localStorage test failed: $e');
    }
  }

  // Apply loyalty discount
  void applyLoyaltyDiscount(double discount) {
    _loyaltyDiscount = discount;
    _loyaltyDiscountApplied = discount > 0;
    notifyListeners();
  }

  // Clear loyalty discount
  void clearLoyaltyDiscount() {
    _loyaltyDiscount = 0.0;
    _loyaltyDiscountApplied = false;
    notifyListeners();
  }

  // Debug print current cart state
  void debugPrintCart() {
    print('\nCart Contents:');
    for (var item in _items) {
      print('\nItem Category: ${item.itemCategory.name}');
      print('Item Description: ${item.itemDescription}');
      print('Item: ${item.item.name}');
      print('Services:');
      for (var service in item.serviceDetails) {
        print('  - ${service.service.name}');
        print('    Price: ${formatPrice(service.totalPrice)}');
        print('    Tailor Points: ${service.totalTailorPoints}');
        if (service.questionAnswerModifiers.isNotEmpty) {
          print('    Question Answers:');
          for (var qa in service.questionAnswerModifiers) {
            print('      Q: ${qa.question}');
            print('      A: ${qa.answer}');
          }
        }
        if (service.subserviceDetails != null) {
          print('    Subservice: ${service.subserviceDetails!.subservice.name}');
          if (service.subserviceDetails!.questionAnswerModifiers.isNotEmpty) {
            print('    Subservice Question Answers:');
            for (var qa in service.subserviceDetails!.questionAnswerModifiers) {
              print('      Q: ${qa.question}');
              print('      A: ${qa.answer}');
            }
          }
        }
      }
      print('Total Price: ${formatPrice(item.totalPrice)}');
      print('Total Tailor Points: ${item.totalTailorPoints}');
    }
  }
} 