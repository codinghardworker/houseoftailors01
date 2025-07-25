import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tailor_service.dart';
import '../models/service.dart';
import '../models/subservice.dart';
import '../models/question.dart';
import '../models/question_option.dart';
import '../models/item_category.dart';
import '../models/item.dart';
import './screens/option_screen_component.dart';
import './screens/question_screen_component.dart';
import './screens/service_card_screen_component.dart';
import './screens/notes_screen_component.dart';
import './screens/delivery_method_screen_component.dart';
import './screens/pickup_selection_screen_component.dart';
import './screens/post_delivery_screen_component.dart';
import './screens/add_another_screen_component.dart';
import './action_button_component.dart';
import './question_box_component.dart';
import './price_component.dart';
import './next_button_component.dart';
import './repair_option_button_component.dart';
import './section_header_component.dart';
import './subtotal_component.dart';
import './back_button_component.dart';
import './tab_indicator_component.dart';
import '../services/dimensions.dart';
import '../providers/shop_config_provider.dart';
import './screens/service_not_available_screen.dart';
import './custom_toast.dart';

class ServiceFlow extends StatefulWidget {
  final int currentScreenIndex;
  final String? selectedRepair;
  final String? repairPrice;
  final String? selectedService;
  final Function(String, String) onServiceComplete;
  final Function() onBack;
  final List<Service> services;
  final bool isLoadingServices;
  final String? serviceError;
  
  // Additional callback parameters that tailor_screen expects
  final Function(String, String)? onRepairOptionSelected;
  final Function(String, String)? onZipOptionSelected;
  final Function(String, String)? onMendRipsQuantitySelected;
  final Function(String, String)? onMendRipsSizeSelected;
  final Function(String, String)? onMendRipsMethodSelected;
  final Function()? onMendRipsColorNext;
  final Function(String, String)? onReplaceRibbingSelected;
  final Function()? onReplaceRibbingRequirementsNext;
  final TextEditingController? colorController;
  final TextEditingController? requirementsController;
  
  // Category and item information for debug reporting
  final ItemCategory? selectedCategory;
  final Item? selectedItem;
  final String? itemDescription;
  final String? locationInfo;

  const ServiceFlow({
    Key? key,
    required this.currentScreenIndex,
    required this.selectedRepair,
    required this.repairPrice,
    required this.selectedService,
    required this.onServiceComplete,
    required this.onBack,
    required this.services,
    required this.isLoadingServices,
    required this.serviceError,
    this.onRepairOptionSelected,
    this.onZipOptionSelected,
    this.onMendRipsQuantitySelected,
    this.onMendRipsSizeSelected,
    this.onMendRipsMethodSelected,
    this.onMendRipsColorNext,
    this.onReplaceRibbingSelected,
    this.onReplaceRibbingRequirementsNext,
    this.colorController,
    this.requirementsController,
    this.selectedCategory,
    this.selectedItem,
    this.itemDescription,
    this.locationInfo,
  }) : super(key: key);

  @override
  State<ServiceFlow> createState() => _ServiceFlowState();
}

class _ServiceFlowState extends State<ServiceFlow> {
  String? _pressedCard;
  
  // Dynamic flow state
  Service? _currentService;
  List<dynamic> _flowStack = []; // Tracks the current flow path
  Map<String, dynamic> _userSelections = {}; // Stores user selections
  List<TextEditingController> _textControllers = [];
  int _currentFlowStep = 0;
  
  // Add navigation history to track the actual path taken
  List<int> _navigationHistory = [];
  Map<String, dynamic> _stepSelections = {}; // Track selections per step
  
  // Delivery method state
  String? _selectedDeliveryMethod;
  DateTime? _selectedPickupDate;
  String? _selectedPickupTime;

  // Add controller for service request
  final TextEditingController _serviceRequestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  @override
  void didUpdateWidget(ServiceFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reinitialize if the service selection actually changed
    if (oldWidget.selectedRepair != widget.selectedRepair ||
        oldWidget.selectedService != widget.selectedService) {
      print('ServiceFlow: Service selection changed, reinitializing flow');
      _initializeFlow();
    }
    
    // Safety check: ensure _currentFlowStep is valid after widget update
    if (_flowStack.isNotEmpty && _currentFlowStep >= _flowStack.length) {
      print('ServiceFlow: Invalid _currentFlowStep after widget update, resetting to 0');
      _currentFlowStep = 0;
    }
  }

  void _initializeFlow() {
    print('ServiceFlow: Initializing flow with selectedService: ${widget.selectedService}, selectedRepair: ${widget.selectedRepair}');
    
    // Clear everything to prevent duplicates
    _currentService = null;
    _flowStack.clear();
    _userSelections.clear();
    _stepSelections.clear();
    _navigationHistory.clear();
    _currentFlowStep = 0;
    
    // Clear text controllers
    for (var controller in _textControllers) {
      controller.dispose();
    }
    _textControllers.clear();
    
    // Initialize based on service type
    if (widget.selectedService == 'Repaired') {
      _currentService = _findServiceByName(widget.selectedRepair);
      print('ServiceFlow: Found service: ${_currentService?.name}');
      
      if (_currentService != null) {
        _buildFlowFromService(_currentService!);
      } else {
        print('ServiceFlow: No service found, creating fallback flow');
        // If no service found, create a basic flow with just notes
        _flowStack = [{
          'type': 'notes',
          'service': Service(
            id: 'default',
            name: widget.selectedRepair ?? 'Unknown Service',
            description: '',
            serviceType: 'repair',
            fittingChoices: [],
            price: 0,
            tailorPoints: 0,
            coverImage: null,
            questions: [],
            subservices: [],
            deadEnd: false,
            active: true,
          ),
        }];
      }
    }
    
    // Reset current flow step to 0 and add initial screen to navigation history
    _currentFlowStep = 0;
    if (_flowStack.isNotEmpty) {
      _navigationHistory.add(0);
    }
    
    print('ServiceFlow: Flow initialized with ${_flowStack.length} steps, _currentFlowStep: $_currentFlowStep');
  }

  void _disposeControllers() {
    for (var controller in _textControllers) {
      try {
        controller.dispose();
      } catch (e) {
        print('ServiceFlow: Error disposing text controller: $e');
      }
    }
    _textControllers.clear();
  }

  Service? _findServiceByName(String? serviceName) {
    if (serviceName == null) return null;
    
    try {
      return widget.services.firstWhere(
        (service) => service.name == serviceName,
      );
    } catch (e) {
      return null;
    }
  }

  void _buildFlowFromService(Service service) {
    print('ServiceFlow: Building flow for service: ${service.name}');
    
    _flowStack.clear();
    _currentFlowStep = 0;
    
    // Build complete flow in order
    List<Map<String, dynamic>> flow = [];
    
    // 1. Add ALL service questions (no need to filter here as base services don't have color questions)
    for (var question in service.questions) {
      flow.add({
        'type': 'question',
        'question': question,
        'service': service,
      });
    }
    
    // 2. Add subservices selection after service questions if any
    if (service.hasSubservices) {
      flow.add({
        'type': 'subservice_selection',
        'service': service,
        'subservices': service.activeSubservices,
      });
    }
    
    // 3. Add delivery method selection first
    flow.add({
      'type': 'delivery_method',
      'service': service,
    });
    
    // 4. Add notes screen after delivery method
    flow.add({
      'type': 'notes',
      'service': service,
    });
    
    // 5. Add "add another" screen at the end (will be inserted after delivery flow)
    flow.add({
      'type': 'add_another',
      'service': service,
    });
    
    _flowStack = flow;
    print('ServiceFlow: Built flow with ${_flowStack.length} steps');
  }

  void _insertSubserviceQuestions(Service service, Subservice subservice) {
    // First, clean up any existing subservice questions to prevent cross-contamination
    _flowStack.removeWhere((step) => 
      step is Map<String, dynamic> && 
      step['type'] == 'question' && 
      step.containsKey('subservice')
    );
    
    // Find the current position and insert subservice questions after subservice selection
    int insertPosition = _currentFlowStep + 1;
    
    // Only check for duplicates AFTER the current position to avoid removing service questions
    Set<String> upcomingQuestionIds = {};
    Set<String> upcomingQuestionTexts = {};
    
    for (int i = insertPosition; i < _flowStack.length; i++) {
      var step = _flowStack[i];
      if (step is Map<String, dynamic> && 
          step['type'] == 'question' && 
          step['question'] is Question) {
        Question q = step['question'] as Question;
        upcomingQuestionIds.add(q.id);
        upcomingQuestionTexts.add(q.question.toLowerCase().trim());
      }
    }
    
    // For subservices with "Contrast Colour" in their name, handle color questions separately
    bool isContrastColorService = subservice.name.contains('Contrast Colour');
    List<Question> regularQuestions = [];
    List<Question> colorQuestions = [];
    
    if (isContrastColorService) {
      // Split questions into regular and color questions only for contrast color services
      for (var question in subservice.questions) {
        if (question.question.toLowerCase().contains('colour') || 
            question.question.toLowerCase().contains('color')) {
          colorQuestions.add(question);
        } else {
          regularQuestions.add(question);
        }
      }
    } else {
      // For all other services, treat all questions as regular
      regularQuestions = subservice.questions;
    }
    
    // Insert regular questions after current position
    for (var question in regularQuestions) {
      bool isDuplicateUpcoming = upcomingQuestionIds.contains(question.id) ||
                                upcomingQuestionTexts.contains(question.question.toLowerCase().trim());
      
      if (!isDuplicateUpcoming) {
        _flowStack.insert(insertPosition, {
          'type': 'question',
          'question': question,
          'service': service,
          'subservice': subservice,
        });
        insertPosition++; // Increment position for next insertion
      }
    }
    
    // For contrast color services, insert color questions right before notes screen
    if (isContrastColorService && colorQuestions.isNotEmpty) {
      int colorInsertPosition = _flowStack.length - 1; // Position before notes screen
      
      for (var question in colorQuestions) {
        bool isDuplicateUpcoming = upcomingQuestionIds.contains(question.id) ||
                                  upcomingQuestionTexts.contains(question.question.toLowerCase().trim());
        
        if (!isDuplicateUpcoming) {
          _flowStack.insert(colorInsertPosition, {
            'type': 'question',
            'question': question,
            'service': service,
            'subservice': subservice,
          });
        }
      }
    }
    
    print('ServiceFlow: Inserted questions for subservice ${subservice.name}, total flow steps: ${_flowStack.length}');
  }

  Widget _buildCurrentScreen() {
    print('ServiceFlow: _flowStack length: ${_flowStack.length}, _currentFlowStep: $_currentFlowStep');
    
    if (_flowStack.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: TailorService.luxuryGold,
        ),
      );
    }

    // Safety check: ensure _currentFlowStep is within bounds
    if (_currentFlowStep < 0) {
      _currentFlowStep = 0;
    }
    if (_currentFlowStep >= _flowStack.length) {
      _currentFlowStep = _flowStack.length - 1;
      print('ServiceFlow: Adjusted _currentFlowStep to $_currentFlowStep');
    }

    final currentStep = _flowStack[_currentFlowStep];
    print('ServiceFlow: currentStep type: ${currentStep['type']}');
    
    if (currentStep is! Map<String, dynamic>) {
      return _buildErrorScreen('Invalid step data');
    }

    switch (currentStep['type']) {
      case 'question':
        final Question question = currentStep['question'];
        final Service service = currentStep['service'];
        final Subservice? subservice = currentStep['subservice'];
        final String key = '${service.id}_${question.id}';
        final bool isTextInput = question.questionType == 'text';
        final controller = _getOrCreateController(key);
        
        return QuestionScreenComponent(
          question: question,
          service: service,
          subservice: subservice,
          questionKey: key,
          textController: controller,
          userSelections: _userSelections,
          hasValue: isTextInput ? 
            controller.text.trim().isNotEmpty : 
            _userSelections.containsKey(key),
          onOptionSelected: _onRadioOptionSelected,
          onNextStep: () {
            if (isTextInput) {
              final textValue = controller.text.trim();
              if (textValue.isNotEmpty) {
                _userSelections[key] = textValue;
                _stepSelections['step_${_currentFlowStep}'] = textValue;
                _onNextStep();
              }
            } else {
              _onNextStep();
            }
          },
          onTextChanged: (value) {
            // Update state when text changes
            setState(() {});
          },
        );
        
      case 'subservice_selection':
        final Service service = currentStep['service'];
        final List<Subservice> subservices = currentStep['subservices'];
        
        // Filter subservices based on questionAnswerExclusion
        final filteredSubservices = _filterSubservicesBasedOnAnswers(subservices);
        
        return OptionScreenComponent(
          service: service,
          subservices: filteredSubservices,
          userSelections: _userSelections,
          pressedCard: _pressedCard,
          onSubserviceSelected: _onSubserviceSelected,
          onPressedCardChanged: (value) => setState(() => _pressedCard = value),
        );
        
      case 'service_selection':
        final services = widget.services.where((s) => s.isAlteration).toList();
        
        if (widget.isLoadingServices) {
          return const Center(child: CircularProgressIndicator(color: TailorService.luxuryGold));
        }

        if (widget.serviceError != null) {
          return _buildErrorScreen(widget.serviceError!);
        }

        if (services.isEmpty) {
          return _buildErrorScreen('No repair services available');
        }
        
        return ServiceCardScreenComponent(
          services: services,
          pressedCard: _pressedCard,
          onServiceSelected: _onServiceSelected,
          onPressedCardChanged: (value) => setState(() => _pressedCard = value),
        );
        
      case 'delivery_method':
        final Service service = currentStep['service'];
        
        return DeliveryMethodScreenComponent(
          service: service,
          subservice: _userSelections['selected_subservice'] as Subservice?,
          userSelections: _userSelections,
          onMethodSelected: _onDeliveryMethodSelected,
        );
        
      case 'pickup_selection':
        final Service service = currentStep['service'];
        
        return PickupSelectionScreenComponent(
          service: service,
          subservice: _userSelections['selected_subservice'] as Subservice?,
          userSelections: _userSelections,
          onPickupScheduled: _onPickupScheduled,
        );
        
      case 'post_delivery':
        final Service service = currentStep['service'];
        
        return PostDeliveryScreenComponent(
          service: service,
          subservice: _userSelections['selected_subservice'] as Subservice?,
          userSelections: _userSelections,
          onNext: _onPostDeliveryNext,
        );
        
      case 'notes':
        final Service service = currentStep['service'];
        final Subservice? subservice = currentStep['subservice'];
        
        // Check if notes is the last screen or if there are more steps after
        final bool isLastScreen = _currentFlowStep >= _flowStack.length - 1;
        
        return NotesScreenComponent(
          service: service,
          subservice: subservice,
          userSelections: _userSelections,
          notesController: _getOrCreateController('notes'),
          onComplete: _onCompleteService,
          onNext: null, // Always show "Add to basket" button in notes screen
          selectedCategory: widget.selectedCategory,
          selectedItem: widget.selectedItem,
          itemDescription: widget.itemDescription,
          locationInfo: widget.locationInfo,
        );
        
      case 'add_another':
        final Service service = currentStep['service'];
        
        return AddAnotherScreenComponent(
          onOptionSelected: _onAddAnotherOptionSelected,
          onGoToBasket: _onGoToBasket,
          currentService: _currentService,
          selectedCategory: widget.selectedCategory,
          selectedItem: widget.selectedItem,
          itemDescription: widget.itemDescription,
          userSelections: _userSelections,
          serviceType: 'repair',
        );
        
      default:
        return _buildErrorScreen('Unknown step type: ${currentStep['type']}');
    }
  }

  Widget _buildErrorScreen(String message) {
    return ServiceNotAvailableScreen(
      textController: _serviceRequestController,
      onSubmit: () async {
        // Handle service request submission
        final request = _serviceRequestController.text.trim();
        if (request.isNotEmpty) {
          try {
            // Save to database without authentication
            await FirebaseFirestore.instance.collection('serviceRequests').add({
              'requestText': request,
              'serviceType': 'service_not_available',
              'userSelections': _userSelections,
              'createdAt': FieldValue.serverTimestamp(),
            });
            
            // Clear the input after submission
            _serviceRequestController.clear();
            // Show success message
            CustomToast.showSuccess(context, 'Service request submitted successfully');
          } catch (e) {
            print('Error saving service request: $e');
            CustomToast.showError(context, 'Failed to submit request. Please try again.');
          }
        }
      },
    );
  }




  Widget _buildTextInput(Question question, String key) {
    final controller = _getOrCreateController(key);
    return Column(
      children: [
        QuestionBoxComponent(
          controller: controller,
          placeholder: 'Your response',
          goldenColor: TailorService.luxuryGold,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Dimensions.itemSpacing),
        NextButtonComponent(
          onPressed: controller.text.trim().isNotEmpty ? () {
            _userSelections[key] = controller.text.trim();
            _stepSelections['step_${_currentFlowStep}'] = controller.text.trim();
            _onNextStep();
          } : null,
          enabled: controller.text.trim().isNotEmpty,
          goldenColor: TailorService.luxuryGold,
        ),
      ],
    );
  }

  Widget _buildRadioOptions(Question question, String key) {
    List<Widget> options = question.options.map<Widget>((option) {
      // Don't show price if it's 0
      String priceText = '';
      if (option.priceModifier > 0) {
        priceText = '+ £${(option.priceModifier / 100.0).toStringAsFixed(2)}';
      }
      
      return RepairOptionButtonComponent(
        label: option.answer,
        price: priceText,
        onTap: () => _onRadioOptionSelected(key, option),
        goldenColor: TailorService.luxuryGold,
      );
    }).toList();

    return Column(
      children: options,
    );
  }

  Widget _buildGenericTextInput(Question question, String key) {
    return QuestionBoxComponent(
      controller: _getOrCreateController(key),
      placeholder: 'Your response',
      goldenColor: TailorService.luxuryGold,
      maxLines: 2,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildNextButton(String key) {
    final hasValue = _userSelections.containsKey(key) || 
                    _getControllerText(key).isNotEmpty;
    
    return NextButtonComponent(
      onPressed: hasValue ? _onNextStep : null,
      enabled: hasValue,
      goldenColor: TailorService.luxuryGold,
    );
  }

  TextEditingController _getOrCreateController(String key) {
    // Find existing controller or create new one with proper key mapping
    final existingIndex = _textControllers.indexWhere((controller) => 
      controller.text.isNotEmpty || _textControllers.indexOf(controller) == 0);
    
    if (_textControllers.isEmpty) {
      final controller = TextEditingController();
      _textControllers.add(controller);
      return controller;
    }
    
    // For now, use the first controller but this could be improved with a Map<String, TextEditingController>
    return _textControllers.first;
  }

  String _getControllerText(String key) {
    if (_textControllers.isEmpty) return '';
    return _textControllers.first.text.trim();
  }

  void _onServiceSelected(Service service) {
    setState(() {
      _currentService = service;
      _pressedCard = null;
      
      // Clear any previous selections to prevent conflicts
      _userSelections.clear();
      _stepSelections.clear();
      
      // Rebuild the complete flow from the selected service
      _buildFlowFromService(service);
      _currentFlowStep = 0;
      
      // Reset navigation history
      _navigationHistory.clear();
      _navigationHistory.add(0);
    });
  }

  void _onSubserviceSelected(Service service, Subservice subservice) async {
    setState(() {
      _pressedCard = null;
      
      // Only clear subservice-related selections if we're reselecting a different subservice
      // This preserves base service price and previous question selections
      if (_userSelections.containsKey('selected_subservice') && 
          _userSelections['selected_subservice'] != subservice) {
        // Remove only subservice-related selections and future steps
        _userSelections.removeWhere((key, value) => 
          key == 'selected_subservice' || 
          key.contains('_subservice_')
        );
        // Clear only future step selections (preserve previous steps)
        _stepSelections.removeWhere((stepKey, value) => 
          int.tryParse(stepKey.split('_').last) != null && 
          int.parse(stepKey.split('_').last) >= _currentFlowStep
        );
      }
      
      // Add the subservice selection
      _userSelections['selected_subservice'] = subservice;
      _stepSelections['step_${_currentFlowStep}'] = subservice;
      
      // Insert subservice questions into the flow (with deduplication)
      _insertSubserviceQuestions(service, subservice);
      
      // Move to next step and track in history
      _currentFlowStep++;
      // Add to navigation history for all screens except pickup/post detail screens
      if (_currentFlowStep < _flowStack.length) {
        final nextScreenType = _flowStack[_currentFlowStep]['type'];
        if (!['pickup_selection', 'post_delivery'].contains(nextScreenType)) {
          _navigationHistory.add(_currentFlowStep);
        }
      }
    });
  }

  void _onRadioOptionSelected(String key, dynamic option) {
    setState(() {
      // Only clear the current question's previous selection if we're selecting a different option
      // This preserves base service price and other question selections
      if (_userSelections.containsKey(key) && _userSelections[key] != option) {
        // Remove only the current question's previous selection and future steps
        _userSelections.removeWhere((k, v) => k == key);
        // Clear only future step selections (preserve previous steps)
        _stepSelections.removeWhere((stepKey, value) => 
          int.tryParse(stepKey.split('_').last) != null && 
          int.parse(stepKey.split('_').last) > _currentFlowStep
        );
      }
      
      // Add the current option selection
      _userSelections[key] = option;
      _stepSelections['step_${_currentFlowStep}'] = option;
      
      // Check if this option has a dead end
      if (option is Map && option['deadEnd'] == true) {
        // Skip to notes screen if this is a dead end (notes is now second to last)
        _currentFlowStep = _flowStack.length - 2;
        // Don't add to navigation history for dead end jumps
      } else {
        _currentFlowStep++;
        // Add to navigation history for all screens except pickup/post detail screens
        if (_currentFlowStep < _flowStack.length) {
          final nextScreenType = _flowStack[_currentFlowStep]['type'];
          if (!['pickup_selection', 'post_delivery'].contains(nextScreenType)) {
            _navigationHistory.add(_currentFlowStep);
          }
        }
      }
    });
  }

  void _onNextStep() {
    // Save current step data
    if (_flowStack.isNotEmpty && _currentFlowStep < _flowStack.length) {
      final currentStep = _flowStack[_currentFlowStep];
      if (currentStep['type'] == 'question') {
        final Question question = currentStep['question'];
        final String key = '${_currentService?.id}_${question.id}';
        final textValue = _getControllerText(key);
        if (!_userSelections.containsKey(key) && textValue.isNotEmpty) {
          _userSelections[key] = textValue;
          _stepSelections['step_${_currentFlowStep}'] = textValue;
        }
      }
    }
    
    setState(() {
      int nextStep = _currentFlowStep + 1;
      if (nextStep < _flowStack.length) {
        final nextScreenType = _flowStack[nextStep]['type'];
        // Add to navigation history for all screens except pickup/post detail screens
        // Notes and delivery_method should be in history to allow proper back navigation
        if (!['pickup_selection', 'post_delivery'].contains(nextScreenType)) {
          _navigationHistory.add(nextStep);
        }
      }
      _currentFlowStep = nextStep;
    });
  }

  void _onCompleteService() {
    // After adding to cart in notes screen, move to add another screen
    setState(() {
      _currentFlowStep++;
      if (_currentFlowStep < _flowStack.length) {
        final nextScreenType = _flowStack[_currentFlowStep]['type'];
        // Add to navigation history for all screens except pickup/post detail screens
        if (!['pickup_selection', 'post_delivery'].contains(nextScreenType)) {
          _navigationHistory.add(_currentFlowStep);
        }
      }
    });
  }

  void _onBackPressed() {
    // If we are on the first step, exit to parent
    if (_currentFlowStep == 0) {
      widget.onBack();
      return;
    }
    
    setState(() {
      // Special handling for pickup/post delivery screens
      if (_currentFlowStep < _flowStack.length) {
        final currentStep = _flowStack[_currentFlowStep];
        final currentType = currentStep['type'] as String;
        
        if (currentType == 'pickup_selection' || currentType == 'post_delivery') {
          // When going back from pickup/post screens, go back to delivery method
          final deliveryMethodIndex = _flowStack.indexWhere((step) => 
            step is Map<String, dynamic> && step['type'] == 'delivery_method'
          );
          
          if (deliveryMethodIndex >= 0) {
            _currentFlowStep = deliveryMethodIndex;
            // Remove delivery-related selections
            _userSelections.removeWhere((key, value) =>
              ['pickup_date', 'pickup_time', 'pickup_cost', 'delivery_address'].contains(key)
            );
            // Keep delivery_method selection to maintain the screen
            
            // Update navigation history
            if (_navigationHistory.isNotEmpty) {
              while (_navigationHistory.last > deliveryMethodIndex) {
                _navigationHistory.removeLast();
              }
            }
            return;
          }
        }
      }
      
      // Handle normal back navigation
      if (_navigationHistory.isNotEmpty) {
        _navigationHistory.removeLast();
        
        if (_navigationHistory.isNotEmpty) {
          _currentFlowStep = _navigationHistory.last;
          
          // Clear selections made after this step
          _stepSelections.removeWhere((stepKey, value) {
            final stepIndex = int.tryParse(stepKey.split('_').last);
            return stepIndex != null && stepIndex >= _currentFlowStep;
          });
          
          // Clear user selections based on step type
          final currentStep = _flowStack[_currentFlowStep];
          final stepType = currentStep['type'] as String;
          
          if (stepType == 'subservice_selection') {
            // Clear subservice and its related selections
            _userSelections.removeWhere((key, value) =>
              key == 'selected_subservice' ||
              key.contains('_subservice_') ||
              (value is Subservice)
            );
          } else if (stepType == 'question') {
            // Clear only this question's answer
            final question = currentStep['question'] as Question;
            final key = '${currentStep['service'].id}_${question.id}';
            _userSelections.remove(key);
          } else if (stepType == 'delivery_method') {
            // Clear delivery method and related selections
            _userSelections.removeWhere((key, value) =>
              ['delivery_method', 'pickup_date', 'pickup_time', 'pickup_cost'].contains(key)
            );
          }
        } else {
          // If no history left, go to previous step
          _currentFlowStep--;
        }
      } else {
        // If no history, go to previous step
        _currentFlowStep--;
      }
      
      // Ensure we don't go below 0
      if (_currentFlowStep < 0) {
        _currentFlowStep = 0;
      }
    });
  }

  @override
  void dispose() {
    _serviceRequestController.dispose();
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onBackPressed();
        return false;
      },
      child: Column(
        children: [
          _buildTabIndicator(),
          _buildBackButton(),
          Expanded(child: _buildCurrentScreen()),
        ],
      ),
    );
  }

  Widget _buildTabIndicator() {
    // Determine active tab based on current screen
    int activeTabIndex = 1; // Default to "Service"
    
    if (_flowStack.isNotEmpty && _currentFlowStep < _flowStack.length) {
      final currentStep = _flowStack[_currentFlowStep];
      if (currentStep is Map<String, dynamic> && currentStep['type'] == 'add_another') {
        activeTabIndex = 2; // "Add Another"
      }
    }
    
    return TabIndicatorComponent(
      tabs: const [
        TabItem(title: 'Category', icon: Icons.checkroom),
        TabItem(title: 'Service', icon: Icons.build),
        TabItem(title: 'Add Another', icon: Icons.list),
      ],
      activeTabIndex: activeTabIndex,
      luxuryGold: TailorService.luxuryGold,
    );
  }

  Widget _buildBackButton() {
    // Don't show back button on add_another screen
    if (_isAddAnotherScreen()) {
      return const SizedBox.shrink();
    }
    
    return BackButtonComponent(
      goldenColor: TailorService.luxuryGold,
      onTap: _onBackPressed,
    );
  }

  bool _isAddAnotherScreen() {
    if (_flowStack.isEmpty || _currentFlowStep >= _flowStack.length) {
      return false;
    }
    
    final currentStep = _flowStack[_currentFlowStep];
    return currentStep is Map<String, dynamic> && currentStep['type'] == 'add_another';
  }

  /// Filter subservices based on questionAnswerExclusion logic
  List<Subservice> _filterSubservicesBasedOnAnswers(List<Subservice> subservices) {
    if (_currentService == null) return subservices;
    
    // Only consider selections from questions that have been answered (exclude the current step)
    Map<String, dynamic> relevantSelections = {};
    for (var entry in _userSelections.entries) {
      if (entry.value is QuestionOption) {
        // Only include selections from previous steps to avoid filtering issues
        final stepKey = 'step_${_currentFlowStep}';
        if (entry.key != stepKey) {
          relevantSelections[entry.key] = entry.value;
        }
      }
    }
    
    return subservices.where((subservice) {
      // If no questionAnswerExclusion, include the subservice
      if (subservice.questionAnswerExclusion == null || 
          subservice.questionAnswerExclusion!.trim().isEmpty) {
        return true;
      }
      
      try {
        // Parse the questionAnswerExclusion JSON string
        final exclusionData = json.decode(subservice.questionAnswerExclusion!);
        if (exclusionData is! List) return true;
        
        final excludedAnswerIds = List<String>.from(exclusionData);
        
        // Check if any of the user's relevant selections match the excluded answer IDs
        for (final selection in relevantSelections.values) {
          if (selection is QuestionOption) {
            // If user selected an answer that should exclude this subservice, filter it out
            if (excludedAnswerIds.contains(selection.id)) {
              print('ServiceFlow: Filtering out subservice ${subservice.name} due to exclusion: ${selection.id}');
              return false;
            }
          }
        }
        
        return true;
      } catch (e) {
        print('Error parsing questionAnswerExclusion for subservice ${subservice.id}: $e');
        // If there's an error parsing, include the subservice by default
        return true;
      }
    }).toList();
  }

  // Delivery method handlers
  void _onDeliveryMethodSelected(String method) {
    setState(() {
      _selectedDeliveryMethod = method;
      _userSelections['delivery_method'] = method;
      _stepSelections['step_${_currentFlowStep}'] = method;
      
      // Remove any existing pickup/post delivery steps
      _flowStack.removeWhere((step) => 
        step is Map<String, dynamic> && 
        ['pickup_selection', 'post_delivery'].contains(step['type'])
      );
      
      // Insert appropriate delivery detail screen
      if (method == 'pickup') {
        _insertDeliveryStep({
          'type': 'pickup_selection',
          'service': _currentService,
        });
      } else if (method == 'post') {
        // Remove pickup cost if switching from pickup to post
        _userSelections.remove('pickup_cost');
        _insertDeliveryStep({
          'type': 'post_delivery',
          'service': _currentService,
        });
      }
      
      _onNextStep();
    });
  }

  void _insertDeliveryStep(Map<String, dynamic> step) {
    // Find the delivery method screen index
    final deliveryMethodIndex = _flowStack.indexWhere((s) => 
      s is Map<String, dynamic> && s['type'] == 'delivery_method'
    );
    
    if (deliveryMethodIndex >= 0) {
      // Insert the new step after delivery method
      _flowStack.insert(deliveryMethodIndex + 1, step);
    }
  }

  void _onPickupScheduled(DateTime date, String timeSlot) async {
    // Get pickup cost from shop configuration
    final shopConfig = Provider.of<ShopConfigProvider>(context, listen: false);
    await shopConfig.refreshConfig();
    
    setState(() {
      _selectedPickupDate = date;
      _selectedPickupTime = timeSlot;
      _userSelections['pickup_date'] = date;
      _userSelections['pickup_time'] = timeSlot;
      _userSelections['pickup_cost'] = shopConfig.pickupChargeInPence;
      _stepSelections['step_${_currentFlowStep}'] = {
        'date': date,
        'time': timeSlot,
        'pickup_cost': shopConfig.pickupChargeInPence,
      };
    });
    
    // Move to next step in flow (notes screen)
    setState(() {
      _currentFlowStep++;
      if (_currentFlowStep < _flowStack.length) {
        final nextScreenType = _flowStack[_currentFlowStep]['type'];
        // Add to navigation history for all screens except pickup/post detail screens
        if (!['pickup_selection', 'post_delivery'].contains(nextScreenType)) {
          _navigationHistory.add(_currentFlowStep);
        }
      }
    });
  }

  void _onPostDeliveryNext() {
    setState(() {
      _userSelections['delivery_method'] = 'post';
      _stepSelections['step_${_currentFlowStep}'] = 'post_confirmed';
    });
    
    // Move to next step in flow (notes screen)
    setState(() {
      _currentFlowStep++;
      if (_currentFlowStep < _flowStack.length) {
        final nextScreenType = _flowStack[_currentFlowStep]['type'];
        // Add to navigation history for all screens except pickup/post detail screens
        if (!['pickup_selection', 'post_delivery'].contains(nextScreenType)) {
          _navigationHistory.add(_currentFlowStep);
        }
      }
    });
  }

  void _onAddAnotherOptionSelected(String action) {
    // Handle the add another screen options
    switch (action) {
      case 'add_more_services':
        // Navigate to service selection screen (index 3) in tailor screen
        Navigator.pushReplacementNamed(context, '/tailor', arguments: {
          'index': 3,
          'fromAddMoreServices': true,
          'categoryId': widget.selectedCategory?.id,
          'categoryName': widget.selectedCategory?.name,
          'itemId': widget.selectedItem?.id,
          'itemName': widget.selectedItem?.name,
          'description': widget.itemDescription,
        });
        break;
      case 'repair_new_item':
        // Navigate to category selection screen (index 0) in tailor screen
        Navigator.pushReplacementNamed(context, '/tailor', arguments: {
          'index': 0,
        });
        break;
      default:
        print('ServiceFlow: Unknown add another action: $action');
    }
  }

  void _onGoToBasket() {
    // Navigate to basket screen
    Navigator.pushNamed(context, '/basket');
  }


} 