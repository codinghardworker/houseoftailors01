import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';
import '../models/subservice.dart';
import '../models/question.dart';
import '../models/question_option.dart';
import '../models/item_category.dart';
import '../models/item.dart';
import '../services/tailor_service.dart';
import '../services/extracted_data_service.dart';
import './screens/perfect_fit_screen_component.dart';
import './screens/option_screen_component.dart';
import './screens/instruction_screen_component.dart';
import './screens/service_card_screen_component.dart';
import './screens/question_screen_component.dart';
import './screens/notes_screen_component.dart';
import './screens/add_another_screen_component.dart';
import './screens/delivery_method_screen_component.dart';
import './screens/pickup_selection_screen_component.dart';
import './screens/post_delivery_screen_component.dart';
import './screens/service_not_available_screen.dart';
import './custom_toast.dart';
import './subtotal_component.dart';
import './back_button_component.dart';
import './tab_indicator_component.dart';
import '../services/dimensions.dart';
import '../providers/shop_config_provider.dart';

class AlterationServiceFlow extends StatefulWidget {
  final int currentScreenIndex;
  final String? selectedService;
  final List<Service> services;
  final bool isLoadingServices;
  final String? serviceError;
  final Function(String, String) onServiceComplete;
  final Function() onBack;
  final Function(String, String)? onAlterationSelected;
  final Function(String)? onFittingMethodSelected;
  final TextEditingController? matchingItemController;
  final TextEditingController? measurementsController;
  final TextEditingController? requirementsController;
  
  // Category and item information for debug reporting
  final ItemCategory? selectedCategory;
  final Item? selectedItem;
  final String? itemDescription;
  final String? locationInfo;

  const AlterationServiceFlow({
    Key? key,
    required this.currentScreenIndex,
    required this.selectedService,
    required this.services,
    required this.isLoadingServices,
    required this.serviceError,
    required this.onServiceComplete,
    required this.onBack,
    this.onAlterationSelected,
    this.onFittingMethodSelected,
    this.matchingItemController,
    this.measurementsController,
    this.requirementsController,
    this.selectedCategory,
    this.selectedItem,
    this.itemDescription,
    this.locationInfo,
  }) : super(key: key);

  @override
  State<AlterationServiceFlow> createState() => _AlterationServiceFlowState();
}

class _AlterationServiceFlowState extends State<AlterationServiceFlow> {
  // Core state
  Service? _currentService;
  Subservice? _currentSubservice;
  Map<String, dynamic> _userSelections = {};
  String? _pressedCard;
  
  // Dynamic flow management
  List<Map<String, dynamic>> _dynamicFlow = [];
  int _currentStepIndex = 0;
  List<int> _navigationHistory = [];
  Map<String, dynamic> _stepSelections = {}; // Track selections per step
  
  // Text controllers management
  Map<String, TextEditingController> _textControllers = {};
  
  // Delivery method state
  String? _selectedDeliveryMethod;
  DateTime? _selectedPickupDate;
  String? _selectedPickupTime;
  
  // Extracted data service
  final ExtractedDataService _dataService = ExtractedDataService();

  // Add controller for service request
  final TextEditingController _serviceRequestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  @override
  void didUpdateWidget(AlterationServiceFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedService != widget.selectedService) {
      _initializeFlow();
    }
  }

  @override
  void dispose() {
    _serviceRequestController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
  }

  void _initializeFlow() {
    _currentService = null;
    _currentSubservice = null;
    _userSelections.clear();
    _stepSelections.clear();
    _dynamicFlow.clear();
    _currentStepIndex = 0;
    _navigationHistory.clear();
    
    // Clear text controllers
    for (var controller in _textControllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        print('AlterationFlow: Error disposing text controller: $e');
      }
    }
    _textControllers.clear();
    
    // Start with service selection if in alteration mode
    if (widget.selectedService == 'Altered') {
      _dynamicFlow = [{'type': 'service_selection'}];
      _navigationHistory.add(0);
    }
  }

  void _buildDynamicFlowFromService(Service service) {
    // Keep the service_selection screen and start adding from index 1
    // This ensures the service selection screen remains available for back navigation
    _dynamicFlow = [{'type': 'service_selection'}]; // Preserve the first screen
    _navigationHistory = [0]; // Keep track that we came from service selection
    
    print('DEBUG: Building dynamic flow for service: ${service.name}');
    print('DEBUG: Service has questions: ${service.questions.length}');
    print('DEBUG: Service has subservices: ${service.hasSubservices}');
    print('DEBUG: Service has fitting choices: ${service.fittingChoices.length}');
    
    // Build flow in logical order based on service structure
    List<Map<String, dynamic>> flow = [];
    
    // 1. Add service-level questions first (these are usually basic service details)
    for (var question in service.questions) {
      flow.add({
        'type': 'question',
        'data': question,
        'context': 'service',
        'service': service,
      });
    }
    
    // 2. Add subservice selection if available (choose specific options)
    if (service.hasSubservices) {
      flow.add({
        'type': 'subservice_selection',
        'data': service.activeSubservices,
        'service': service,
      });
    }
    
    // 3. Add fitting selection screen (how to achieve the perfect fit)
    // This comes after basic service details and options are selected
    if (service.fittingChoices.isNotEmpty || service.serviceType == 'alteration') {
      flow.add({
        'type': 'fitting_selection',
        'data': service,
      });
    }
    
    // 4. Add delivery method selection first
    flow.add({
      'type': 'delivery_method',
      'service': service,
    });
    
    // 5. Add notes screen after delivery method
    flow.add({
      'type': 'notes',
      'service': service,
    });
    
    // 6. Always add completion/add another screen (last)
    flow.add({
      'type': 'add_another',
      'service': service,
    });
    
    // Append the new flow steps to the existing service_selection screen
    _dynamicFlow.addAll(flow);
    
    // Set current step to the first step after service_selection
    // This moves us to the next logical step in the flow
    _currentStepIndex = 1;
    
    print('DEBUG: Built flow with ${_dynamicFlow.length} steps:');
    for (int i = 0; i < _dynamicFlow.length; i++) {
      print('DEBUG: Step $i: ${_dynamicFlow[i]['type']}');
    }
  }

  void _insertDynamicContent(String afterType, List<Map<String, dynamic>> newSteps) {
    // Find insertion point - search the entire flow, not just from current step
    int insertIndex = -1;
    for (int i = 0; i < _dynamicFlow.length; i++) {
      if (_dynamicFlow[i]['type'] == afterType) {
        insertIndex = i + 1;
        break;
      }
    }
    
    if (insertIndex > 0) {
      _dynamicFlow.insertAll(insertIndex, newSteps);
      
      // If we're inserting steps before or at the current position, 
      // we need to adjust the current step index
      if (insertIndex <= _currentStepIndex + 1) {
        // Don't adjust the current step index, let it continue naturally
        print('DEBUG: Inserted ${newSteps.length} steps at position $insertIndex');
        print('DEBUG: Current step index remains: $_currentStepIndex');
        print('DEBUG: Total flow length: ${_dynamicFlow.length}');
        
        // Print the current flow for debugging
        for (int i = 0; i < _dynamicFlow.length; i++) {
          final step = _dynamicFlow[i];
          final marker = i == _currentStepIndex ? ' <- CURRENT' : '';
          print('DEBUG: Flow[$i]: ${step['type']}$marker');
        }
      }
    }
  }

  Future<void> _handleFittingSelection(String method) async {
    if (_currentService == null) return;
    
    List<Map<String, dynamic>> stepsToInsert = [];
    
    print('DEBUG: Checking fitting guide for service: ${_currentService!.id}, method: $method');
    
    // Check if service has fitting guide for this method using extracted data
    final hasGuide = await _dataService.hasFittingGuideForMethod(_currentService!.id, method);
    
    print('DEBUG: Has guide: $hasGuide');
    
    if (hasGuide) {
      // Get the guide content
      final guideContent = await _dataService.getFittingGuideContent(_currentService!.id, method);
      final guideText = _dataService.extractGuideText(guideContent);
      
      print('DEBUG: Guide content keys: ${guideContent?.keys}');
      print('DEBUG: Extracted guide text: $guideText');
      
      // Add instruction screen with the guide content
      stepsToInsert.add({
        'type': 'instructions',
        'data': _currentService,
        'method': method,
        'guideContent': guideContent,
        'guideText': guideText,
      });
      
      // For fitting methods that have guides, also add a follow-up question
      // This ensures the user can provide additional details after seeing the instructions
      if (method == 'match') {
        stepsToInsert.add({
          'type': 'question',
          'data': Question(
            id: 'fitting_match_followup_${DateTime.now().millisecondsSinceEpoch}',
            question: 'Describe your matching item for us.',
            questionType: 'text',
            explainer: 'This is so we can differentiate your items.',
            options: [],
            deadEnd: false,
            active: true,
          ),
          'context': 'fitting',
          'service': _currentService,
          'placeholder': 'Colour, pattern, material',
        });
      } else if (method == 'measure') {
        stepsToInsert.add({
          'type': 'question',
          'data': Question(
            id: 'fitting_measure_followup_${DateTime.now().millisecondsSinceEpoch}',
            question: 'Describe your measurements for us.',
            questionType: 'text',
            explainer: 'For example, take in by 1 inch or waist measurement of 34 inches.',
            options: [],
            deadEnd: false,
            active: true,
          ),
          'context': 'fitting',
          'service': _currentService,
          'placeholder': 'Describe your measurements',
        });
      }
    } else {
      print('DEBUG: No guide found, adding question instead');
      // No guide available, add appropriate question based on method
      if (method == 'match') {
        stepsToInsert.add({
          'type': 'question',
          'data': Question(
            id: 'fitting_match_${DateTime.now().millisecondsSinceEpoch}',
            question: 'Describe your matching item for us.',
            questionType: 'text',
            explainer: 'This is so we can differentiate your items.',
            options: [],
            deadEnd: false,
            active: true,
          ),
          'context': 'fitting',
          'service': _currentService,
          'placeholder': 'Colour, pattern, material',
        });
      } else if (method == 'measure') {
        stepsToInsert.add({
          'type': 'question',
          'data': Question(
            id: 'fitting_measure_${DateTime.now().millisecondsSinceEpoch}',
            question: 'Describe your measurements for us.',
            questionType: 'text',
            explainer: 'For example, take in by 1 inch or waist measurement of 34 inches.',
            options: [],
            deadEnd: false,
            active: true,
          ),
          'context': 'fitting',
          'service': _currentService,
          'placeholder': 'Describe your measurements',
        });
      }
    }
    
    if (stepsToInsert.isNotEmpty) {
      _insertDynamicContent('fitting_selection', stepsToInsert);
    }
  }

  void _handleSubserviceSelection(Subservice subservice) {
    _currentSubservice = subservice;
    
    // First, clean up any existing subservice questions to prevent cross-contamination
    _dynamicFlow.removeWhere((step) => 
      step is Map<String, dynamic> && 
      step['type'] == 'question' && 
      step['context'] == 'subservice'
    );
    
    // Dynamically add subservice questions
    List<Map<String, dynamic>> questionsToAdd = [];
    for (var question in subservice.questions) {
      questionsToAdd.add({
        'type': 'question',
        'data': question,
        'context': 'subservice',
        'service': _currentService,
        'subservice': subservice,
      });
    }
    
    if (questionsToAdd.isNotEmpty) {
      _insertDynamicContent('subservice_selection', questionsToAdd);
    }
    
    print('AlterationFlow: Inserted questions for subservice ${subservice.name}, total flow steps: ${_dynamicFlow.length}');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBack();
        return false;
      },
      child: Column(
        children: [
          _buildTabIndicator(),
          _buildBackButton(),
          Expanded(child: _buildCurrentStep()),
        ],
      ),
    );
  }

  Widget _buildTabIndicator() {
    // Determine active tab based on current screen
    int activeTabIndex = 1; // Default to "Service"
    
    if (_dynamicFlow.isNotEmpty && _currentStepIndex < _dynamicFlow.length) {
      final currentStep = _dynamicFlow[_currentStepIndex];
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
      onTap: _handleBack,
    );
  }

  bool _isAddAnotherScreen() {
    if (_dynamicFlow.isEmpty || _currentStepIndex >= _dynamicFlow.length) {
      return false;
    }
    
    final currentStep = _dynamicFlow[_currentStepIndex];
    return currentStep is Map<String, dynamic> && currentStep['type'] == 'add_another';
  }

  Widget _buildCurrentStep() {
    if (_dynamicFlow.isEmpty || _currentStepIndex >= _dynamicFlow.length) {
      return const Center(
        child: CircularProgressIndicator(
          color: TailorService.luxuryGold,
        ),
      );
    }

    final currentStep = _dynamicFlow[_currentStepIndex];
    final stepType = currentStep['type'] as String;
    
    // Build screen based on step type
    switch (stepType) {
      case 'service_selection':
        return _buildServiceSelection();
        
      case 'fitting_selection':
        return _buildFittingSelection(currentStep);
        
      case 'question':
        return _buildQuestion(currentStep);
        
      case 'subservice_selection':
        return _buildSubserviceSelection(currentStep);
        
      case 'instructions':
        return _buildInstructions(currentStep);
        
      case 'delivery_method':
        final service = currentStep['service'] as Service;
        
        return DeliveryMethodScreenComponent(
          service: service,
          subservice: _currentSubservice,
          userSelections: _userSelections,
          onMethodSelected: _onDeliveryMethodSelected,
        );
        
      case 'pickup_selection':
        final service = currentStep['service'] as Service;
        
        return PickupSelectionScreenComponent(
          service: service,
          subservice: _currentSubservice,
          userSelections: _userSelections,
          onPickupScheduled: _onPickupScheduled,
        );
        
      case 'post_delivery':
        final service = currentStep['service'] as Service;
        
        return PostDeliveryScreenComponent(
          service: service,
          subservice: _currentSubservice,
          userSelections: _userSelections,
          onNext: _onPostDeliveryNext,
        );
        
      case 'notes':
        return _buildNotes(currentStep);
        
      case 'add_another':
        return _buildAddAnother(currentStep);
        
      default:
        return _buildError('Unknown step type: $stepType');
    }
  }

  Widget _buildServiceSelection() {
    final alterationServices = widget.services
        .where((s) => s.serviceType == 'alteration' && s.active)
        .toList();
    
    if (widget.isLoadingServices) {
      return const Center(
        child: CircularProgressIndicator(
          color: TailorService.luxuryGold,
        ),
      );
    }

    if (widget.serviceError != null) {
      return _buildError(widget.serviceError!);
    }

    if (alterationServices.isEmpty) {
      return _buildError('No alteration services available');
    }
    
    return ServiceCardScreenComponent(
      services: alterationServices,
      pressedCard: _pressedCard,
      onServiceSelected: (service) {
        setState(() {
          _currentService = service;
          _pressedCard = null;
          
          // Clear any previous selections to prevent conflicts
          _userSelections.clear();
          _stepSelections.clear();
          
          _buildDynamicFlowFromService(service);
          
          if (widget.onAlterationSelected != null) {
            widget.onAlterationSelected!(
              service.name,
              '£${(service.price / 100.0).toStringAsFixed(2)}',
            );
          }
        });
      },
      onPressedCardChanged: (value) => setState(() => _pressedCard = value),
    );
  }

  Widget _buildFittingSelection(Map<String, dynamic> step) {
    final service = step['data'] as Service;
    
    // Get available fitting choices from the service
    List<String> fittingChoices = List<String>.from(service.fittingChoices);
    
    // Always include in_person fitting for alterations
    if (service.serviceType == 'alteration' && !fittingChoices.contains('in_person')) {
      fittingChoices.add('in_person');
    }
    
    // Create a modified service with the correct fitting choices
    final modifiedService = Service(
      id: service.id,
      name: service.name,
      description: service.description,
      serviceType: service.serviceType,
      fittingChoices: fittingChoices,
      price: service.price,
      tailorPoints: service.tailorPoints,
      coverImage: service.coverImage,
      questions: service.questions,
      subservices: service.subservices,
      deadEnd: service.deadEnd,
      active: service.active,
    );
    
    return PerfectFitScreenComponent(
      service: modifiedService,
      subservice: _currentSubservice,
      userSelections: _userSelections,
      onFittingSelected: (method) async {
        setState(() {
          // Only clear fitting-related selections if we're reselecting a different fitting method
          // This preserves base service price and previous selections
          if (_userSelections.containsKey('fitting_method') && 
              _userSelections['fitting_method'] != method) {
            // Remove only fitting-related selections and future steps
            _userSelections.removeWhere((key, value) => 
              key.startsWith('fitting_') || key == 'fitting_method'
            );
            // Clear only future step selections (preserve previous steps)
            _stepSelections.removeWhere((stepKey, value) => 
              int.tryParse(stepKey.split('_').last) != null && 
              int.parse(stepKey.split('_').last) > _currentStepIndex
            );
          }
          
          _userSelections['fitting_method'] = method;
          _stepSelections['step_${_currentStepIndex}'] = method;
        });
        
        // Handle fitting selection asynchronously to check for guides
        await _handleFittingSelection(method);
        
        setState(() {
          _moveToNextStep();
          
          if (widget.onFittingMethodSelected != null) {
            widget.onFittingMethodSelected!(method);
          }
        });
      },
    );
  }

  Widget _buildQuestion(Map<String, dynamic> step) {
    final question = step['data'] as Question;
    final service = step['service'] as Service?;
    final subservice = step['subservice'] as Subservice?;
    final context = step['context'] as String;
    final placeholder = step['placeholder'] as String?;
    
    final key = _generateQuestionKey(question, context);
    final controller = _getOrCreateController(key, question, context);
    
    return QuestionScreenComponent(
      question: question,
      service: service ?? _currentService!,
      subservice: subservice,
      questionKey: key,
      textController: controller,
      userSelections: _userSelections,
      hasValue: _userSelections.containsKey(key) || controller.text.isNotEmpty,
      placeholder: placeholder,
      onOptionSelected: (key, option) {
        setState(() {
          // Check if we're reselecting on the same question
          if (_userSelections.containsKey(key)) {
            // If selecting a different option, clear only this question and future steps
            if (_userSelections[key] != option) {
              _userSelections.removeWhere((k, v) => k == key);
              // Clear only future step selections (preserve previous steps)
              _stepSelections.removeWhere((stepKey, value) => 
                int.tryParse(stepKey.split('_').last) != null && 
                int.parse(stepKey.split('_').last) > _currentStepIndex
              );
            } else {
              // Selected the same option again, do nothing (preserve reselect functionality)
              return;
            }
          }
          
          // Add the current option selection
          _userSelections[key] = option;
          _stepSelections['step_${_currentStepIndex}'] = option;
          
          // Handle dead ends
          if (option.deadEnd) {
            // Jump to notes screen
            final notesIndex = _dynamicFlow.indexWhere((s) => s['type'] == 'notes');
            if (notesIndex > -1) {
              _currentStepIndex = notesIndex;
              // Don't add notes screen to navigation history
              return;
            }
          }
          
          _moveToNextStep();
        });
      },
      onNextStep: () {
        final text = controller.text.trim();
        if (text.isNotEmpty) {
          setState(() {
            _userSelections[key] = text;
            _stepSelections['step_${_currentStepIndex}'] = text;
            _moveToNextStep();
          });
        }
      },
      onTextChanged: (_) => setState(() {}),
    );
  }

  Widget _buildSubserviceSelection(Map<String, dynamic> step) {
    final subservices = step['data'] as List<Subservice>;
    final service = step['service'] as Service;
    
    // Filter subservices based on questionAnswerExclusion
    final filteredSubservices = _filterSubservicesBasedOnAnswers(subservices);
    
    return OptionScreenComponent(
      service: service,
      subservices: filteredSubservices,
      userSelections: _userSelections,
      pressedCard: _pressedCard,
      onSubserviceSelected: (service, subservice) {
        setState(() {
          _pressedCard = null;
          
          // Only clear subservice-related selections if we're reselecting a different subservice
          // This preserves base service price and previous question selections
          if (_userSelections.containsKey('selected_subservice') && 
              _userSelections['selected_subservice'] != subservice) {
            // Remove only subservice-related selections and future steps
            _userSelections.removeWhere((key, value) => 
              key == 'selected_subservice' || key.contains('_subservice_')
            );
            // Clear only future step selections (preserve previous steps)
            _stepSelections.removeWhere((stepKey, value) => 
              int.tryParse(stepKey.split('_').last) != null && 
              int.parse(stepKey.split('_').last) >= _currentStepIndex
            );
          }
          
          // Add the subservice selection
          _userSelections['selected_subservice'] = subservice;
          _stepSelections['step_${_currentStepIndex}'] = subservice;
          
          _handleSubserviceSelection(subservice);
          _moveToNextStep();
        });
      },
      onPressedCardChanged: (value) => setState(() => _pressedCard = value),
    );
  }

  /// Filter subservices based on questionAnswerExclusion logic
  List<Subservice> _filterSubservicesBasedOnAnswers(List<Subservice> subservices) {
    if (_currentService == null) return subservices;
    
    // Only consider selections from questions that have been answered (exclude the current step)
    Map<String, dynamic> relevantSelections = {};
    for (var entry in _userSelections.entries) {
      if (entry.value is QuestionOption) {
        // Only include selections from previous steps to avoid filtering issues
        final stepKey = 'step_${_currentStepIndex}';
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
              print('AlterationFlow: Filtering out subservice ${subservice.name} due to exclusion: ${selection.id}');
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

  Widget _buildInstructions(Map<String, dynamic> step) {
    final service = step['data'] as Service;
    final method = step['method'] as String;
    final guideText = step['guideText'] as String?;
    
    // Create a custom instruction screen component that can display the guide text
    return InstructionScreenComponent(
      service: service,
      subservice: _currentSubservice,
      userSelections: _userSelections,
      customInstructions: guideText,
      fittingMethod: method,
      onNext: () {
        setState(() {
          _moveToNextStep();
        });
      },
    );
  }

  Widget _buildNotes(Map<String, dynamic> step) {
    final service = step['service'] as Service;
    
    // Notes screen shows "Add to basket" button and handles adding to cart
    // After adding to cart, it moves to add_another screen
    
    return NotesScreenComponent(
      service: service,
      subservice: _currentSubservice,
      userSelections: _userSelections,
      notesController: widget.requirementsController ?? _getOrCreateController('notes', null, 'notes'),
      onComplete: () {
        // After adding to cart in notes screen, move to add another screen
        _moveToNextStep();
      },
      onNext: null, // Always show "Add to basket" button in notes screen
      selectedCategory: widget.selectedCategory,
      selectedItem: widget.selectedItem,
      itemDescription: widget.itemDescription,
      locationInfo: widget.locationInfo,
    );
  }

  Widget _buildAddAnother(Map<String, dynamic> step) {
    return AddAnotherScreenComponent(
      onOptionSelected: (option) {
        if (option == 'add_more_services') {
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
        } else if (option == 'repair_new_item') {
          // Navigate to category selection screen (index 0) in tailor screen
          Navigator.pushReplacementNamed(context, '/tailor', arguments: {
            'index': 0,
          });
        }
      },
      onGoToBasket: () {
        // Navigate to basket screen
        Navigator.pushNamed(context, '/basket');
      },
      currentService: _currentService,
      selectedCategory: widget.selectedCategory,
      selectedItem: widget.selectedItem,
      itemDescription: widget.itemDescription,
      userSelections: _userSelections,
      serviceType: 'alteration',
    );
  }

  Widget _buildError(String message) {
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
              'serviceType': 'alteration_service_not_available',
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


  String _generateQuestionKey(Question question, String context) {
    final serviceId = _currentService?.id ?? 'unknown';
    final subserviceId = _currentSubservice?.id ?? '';
    return '${serviceId}_${context}_${subserviceId}_${question.id}';
  }

  TextEditingController _getOrCreateController(String key, Question? question, String context) {
    // Use provided controllers for specific contexts
    if (context == 'fitting' && question != null) {
      if (question.question.toLowerCase().contains('match')) {
        return widget.matchingItemController ?? _createInternalController(key);
      } else if (question.question.toLowerCase().contains('measurement')) {
        return widget.measurementsController ?? _createInternalController(key);
      }
    } else if (context == 'notes') {
      return widget.requirementsController ?? _createInternalController(key);
    }
    
    return _createInternalController(key);
  }

  TextEditingController _createInternalController(String key) {
    if (!_textControllers.containsKey(key)) {
      _textControllers[key] = TextEditingController();
    }
    return _textControllers[key]!;
  }

  void _moveToNextStep() {
    print('AlterationFlow: _moveToNextStep called - currentIndex: $_currentStepIndex, flowLength: ${_dynamicFlow.length}');
    
    setState(() {
      if (_currentStepIndex < _dynamicFlow.length - 1) {
        // Add current step to navigation history before moving forward
        // Only add screens that users can navigate back to (exclude pickup/post detail screens)
        int nextStep = _currentStepIndex + 1;
        print('AlterationFlow: Moving to nextStep: $nextStep');
        
        if (nextStep < _dynamicFlow.length) {
          final nextScreenType = _dynamicFlow[nextStep]['type'];
          print('AlterationFlow: Next screen type: $nextScreenType');
          
          if (!['pickup_selection', 'post_delivery'].contains(nextScreenType)) {
            _navigationHistory.add(nextStep);
            print('AlterationFlow: Added to navigation history');
          }
        }
        
        _currentStepIndex++;
        print('AlterationFlow: Updated currentStepIndex to: $_currentStepIndex');
      } else {
        print('AlterationFlow: Cannot move to next step - already at last step');
      }
    });
  }

  void _handleBack() {
    // If we are on the very first step of the flow, exit to parent
    if (_currentStepIndex == 0) {
      widget.onBack();
      return;
    }
    
    setState(() {
      // Special handling for pickup/post delivery screens
      if (_currentStepIndex < _dynamicFlow.length) {
        final currentStep = _dynamicFlow[_currentStepIndex];
        final currentType = currentStep['type'] as String;
        
        if (currentType == 'pickup_selection' || currentType == 'post_delivery') {
          // When going back from pickup/post screens, go back to delivery method
          final deliveryMethodIndex = _dynamicFlow.indexWhere((step) => 
            step is Map<String, dynamic> && step['type'] == 'delivery_method'
          );
          
          if (deliveryMethodIndex >= 0) {
            _currentStepIndex = deliveryMethodIndex;
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
          _currentStepIndex = _navigationHistory.last;
          
          // Clear selections made after this step
          _stepSelections.removeWhere((stepKey, value) {
            final stepIndex = int.tryParse(stepKey.split('_').last);
            return stepIndex != null && stepIndex >= _currentStepIndex;
          });
          
          // Clear user selections based on step type
          final currentStep = _dynamicFlow[_currentStepIndex];
          final stepType = currentStep['type'] as String;
          
          if (stepType == 'subservice_selection') {
            // Clear subservice and its related selections
            _userSelections.removeWhere((key, value) =>
              key == 'selected_subservice' ||
              key.contains('_subservice_') ||
              (value is Subservice)
            );
            _currentSubservice = null;
          } else if (stepType == 'question') {
            // Clear only this question's answer
            final question = currentStep['data'] as Question;
            final context = currentStep['context'] as String;
            final key = _generateQuestionKey(question, context);
            _userSelections.remove(key);
          } else if (stepType == 'fitting_selection') {
            // Clear fitting method and related selections
            _userSelections.removeWhere((key, value) =>
              key.startsWith('fitting_') ||
              key == 'fitting_method'
            );
          }
        } else {
          // If no history left, go to previous step
          _currentStepIndex--;
        }
      } else {
        // If no history, go to previous step
        _currentStepIndex--;
      }
      
      // Ensure we don't go below 0
      if (_currentStepIndex < 0) {
        _currentStepIndex = 0;
      }
    });
  }

  void _calculateAndSaveOrder() {
    if (_currentService == null) return;
    
    int totalPrice = _currentService!.price;
    
    // Add subservice modifier
    if (_currentSubservice != null) {
      totalPrice += _currentSubservice!.priceModifier;
    }
    
    // Add option modifiers
    for (var value in _userSelections.values) {
      if (value is QuestionOption) {
        totalPrice += value.priceModifier;
      }
    }
    
    widget.onServiceComplete(
      _currentService!.name,
      '£${(totalPrice / 100.0).toStringAsFixed(2)}',
    );
  }

  // Delivery method handlers
  void _onDeliveryMethodSelected(String method) {
    setState(() {
      _selectedDeliveryMethod = method;
      _userSelections['delivery_method'] = method;
      _stepSelections['step_${_currentStepIndex}'] = method;
      
      // Remove any existing pickup/post delivery steps
      _dynamicFlow.removeWhere((step) => 
        step is Map<String, dynamic> && 
        ['pickup_selection', 'post_delivery'].contains(step['type'])
      );
      
      // Insert appropriate delivery detail screen
      if (method == 'pickup') {
        _insertDynamicContent('delivery_method', [
          {'type': 'pickup_selection', 'service': _currentService}
        ]);
      } else if (method == 'post') {
        // Remove pickup cost if switching from pickup to post
        _userSelections.remove('pickup_cost');
        _insertDynamicContent('delivery_method', [
          {'type': 'post_delivery', 'service': _currentService}
        ]);
      }
      
      _moveToNextStep();
    });
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
      _stepSelections['step_${_currentStepIndex}'] = {
        'date': date,
        'time': timeSlot,
        'pickup_cost': shopConfig.pickupChargeInPence,
      };
    });
    
    // Move to next step in flow (notes screen)
    _moveToNextStep();
  }

  void _onPostDeliveryNext() {
    setState(() {
      _userSelections['delivery_method'] = 'post';
      _stepSelections['step_${_currentStepIndex}'] = 'post_confirmed';
    });
    
    // Move to next step in flow (notes screen)
    _moveToNextStep();
  }


}