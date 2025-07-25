import 'package:flutter/foundation.dart';
import 'cart_provider.dart';

class ServiceSelectionProvider extends ChangeNotifier {
  // Current selection state
  ItemCategory? _selectedCategory;
  String _itemDescription = '';
  Service? _selectedItem;
  Service? _selectedService;
  String? _selectedFittingChoice;
  String? _fittingDetails;
  String? _repairLocation;
  String _tailorNotes = '';
  List<QuestionAnswer> _questionAnswers = [];
  Subservice? _selectedSubservice;
  List<QuestionAnswer> _subserviceQuestionAnswers = [];

  // Getters
  ItemCategory? get selectedCategory => _selectedCategory;
  String get itemDescription => _itemDescription;
  Service? get selectedItem => _selectedItem;
  Service? get selectedService => _selectedService;
  String? get selectedFittingChoice => _selectedFittingChoice;
  String? get fittingDetails => _fittingDetails;
  String? get repairLocation => _repairLocation;
  String get tailorNotes => _tailorNotes;
  List<QuestionAnswer> get questionAnswers => List.unmodifiable(_questionAnswers);
  Subservice? get selectedSubservice => _selectedSubservice;
  List<QuestionAnswer> get subserviceQuestionAnswers => List.unmodifiable(_subserviceQuestionAnswers);

  // Selection methods
  void selectCategory(ItemCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setItemDescription(String description) {
    _itemDescription = description;
    notifyListeners();
  }

  void selectItem(Service item) {
    _selectedItem = item;
    notifyListeners();
  }

  void selectService(Service service) {
    _selectedService = service;
    // Reset dependent selections
    _selectedFittingChoice = null;
    _fittingDetails = null;
    _repairLocation = null;
    _questionAnswers.clear();
    _selectedSubservice = null;
    _subserviceQuestionAnswers.clear();
    notifyListeners();
  }

  void selectFittingChoice(String choice) {
    _selectedFittingChoice = choice;
    notifyListeners();
  }

  void setFittingDetails(String details) {
    _fittingDetails = details;
    notifyListeners();
  }

  void setRepairLocation(String location) {
    _repairLocation = location;
    notifyListeners();
  }

  void setTailorNotes(String notes) {
    _tailorNotes = notes;
    notifyListeners();
  }

  void addQuestionAnswer(QuestionAnswer answer) {
    // Remove any existing answer for the same question
    _questionAnswers.removeWhere((qa) => qa.question == answer.question);
    _questionAnswers.add(answer);
    notifyListeners();
  }

  void selectSubservice(Subservice subservice) {
    _selectedSubservice = subservice;
    _subserviceQuestionAnswers.clear();
    notifyListeners();
  }

  void addSubserviceQuestionAnswer(QuestionAnswer answer) {
    // Remove any existing answer for the same question
    _subserviceQuestionAnswers.removeWhere((qa) => qa.question == answer.question);
    _subserviceQuestionAnswers.add(answer);
    notifyListeners();
  }

  // Calculate current total price including all modifiers
  double get currentTotalPrice {
    if (_selectedService == null) return 0;
    
    double total = _selectedService!.price;
    
    // Add question modifiers
    for (var answer in _questionAnswers) {
      total += answer.priceModifier;
    }
    
    // Add subservice modifiers if present
    if (_selectedSubservice != null) {
      total += _selectedSubservice!.priceModifier;
      for (var answer in _subserviceQuestionAnswers) {
        total += answer.priceModifier;
      }
    }
    
    return total;
  }

  // Calculate current total tailor points including all modifiers
  int get currentTotalTailorPoints {
    if (_selectedService == null) return 0;
    
    int total = _selectedService!.tailorPoints;
    
    // Add question modifiers
    for (var answer in _questionAnswers) {
      total += answer.tailorPointsModifier;
    }
    
    // Add subservice modifiers if present
    if (_selectedSubservice != null) {
      total += _selectedSubservice!.tailorPointsModifier;
      for (var answer in _subserviceQuestionAnswers) {
        total += answer.tailorPointsModifier;
      }
    }
    
    return total;
  }

  // Create a CartItem from the current selection
  CartItem? createCartItem() {
    if (_selectedCategory == null || 
        _selectedItem == null || 
        _selectedService == null) {
      return null;
    }

    final serviceDetails = ServiceDetails(
      service: _selectedService!,
      basePrice: _selectedService!.price,
      fittingChoice: _selectedFittingChoice,
      fittingDetails: _fittingDetails,
      repairLocation: _repairLocation,
      tailorNotes: _tailorNotes,
      questionAnswerModifiers: _questionAnswers,
      subserviceDetails: _selectedSubservice != null 
        ? SubserviceDetails(
            subservice: _selectedSubservice!,
            questionAnswerModifiers: _subserviceQuestionAnswers,
          )
        : null,
      serviceType: _selectedService!.serviceType,
    );

    return CartItem(
      itemCategory: _selectedCategory!,
      itemDescription: _itemDescription,
      item: _selectedItem!,
      serviceDetails: [serviceDetails],
      discountCode: null,
    );
  }

  // Reset all selections
  void reset() {
    _selectedCategory = null;
    _itemDescription = '';
    _selectedItem = null;
    _selectedService = null;
    _selectedFittingChoice = null;
    _fittingDetails = null;
    _repairLocation = null;
    _tailorNotes = '';
    _questionAnswers.clear();
    _selectedSubservice = null;
    _subserviceQuestionAnswers.clear();
    notifyListeners();
  }

  // Debug print current selection state
  void debugPrintSelection() {
    print('\nCurrent Selection State:');
    print('Category: ${_selectedCategory?.name ?? 'Not selected'}');
    print('Item Description: $_itemDescription');
    print('Item: ${_selectedItem?.name ?? 'Not selected'}');
    print('Service: ${_selectedService?.name ?? 'Not selected'}');
    if (_selectedService != null) {
      print('Service Type: ${_selectedService!.serviceType}');
      print('Base Price: ${_selectedService!.price}');
      print('Base Tailor Points: ${_selectedService!.tailorPoints}');
    }
    print('Fitting Choice: $_selectedFittingChoice');
    print('Fitting Details: $_fittingDetails');
    print('Repair Location: $_repairLocation');
    print('Tailor Notes: $_tailorNotes');
    
    if (_questionAnswers.isNotEmpty) {
      print('\nQuestion Answers:');
      for (var qa in _questionAnswers) {
        print('Q: ${qa.question}');
        print('A: ${qa.answer}');
        print('Price Modifier: ${qa.priceModifier}');
        print('Points Modifier: ${qa.tailorPointsModifier}');
      }
    }
    
    if (_selectedSubservice != null) {
      print('\nSelected Subservice: ${_selectedSubservice!.name}');
      print('Subservice Price Modifier: ${_selectedSubservice!.priceModifier}');
      print('Subservice Points Modifier: ${_selectedSubservice!.tailorPointsModifier}');
      
      if (_subserviceQuestionAnswers.isNotEmpty) {
        print('\nSubservice Question Answers:');
        for (var qa in _subserviceQuestionAnswers) {
          print('Q: ${qa.question}');
          print('A: ${qa.answer}');
          print('Price Modifier: ${qa.priceModifier}');
          print('Points Modifier: ${qa.tailorPointsModifier}');
        }
      }
    }
    
    print('\nCurrent Totals:');
    print('Total Price: $currentTotalPrice');
    print('Total Tailor Points: $currentTotalTailorPoints');
  }
} 