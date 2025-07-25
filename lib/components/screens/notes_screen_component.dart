import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../models/service.dart';
import '../../models/subservice.dart';
import '../../models/question_option.dart';
import '../../models/item_category.dart';
import '../../models/item.dart';
import '../section_header_component.dart';
import '../question_box_component.dart';
import '../action_button_component.dart';
import '../subtotal_component.dart';
import '../../services/dimensions.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart' as cart;
import '../custom_toast.dart';
import '../cart_modal_component.dart';

class NotesScreenComponent extends StatelessWidget {
  final Service service;
  final Subservice? subservice;
  final TextEditingController notesController;
  final Map<String, dynamic>? userSelections;
  final VoidCallback onComplete;
  final VoidCallback? onNext;
  
  // Add optional parameters for category and item information
  final ItemCategory? selectedCategory;
  final Item? selectedItem;
  final String? itemDescription;
  final String? locationInfo;

  const NotesScreenComponent({
    Key? key,
    required this.service,
    this.subservice,
    required this.notesController,
    this.userSelections,
    required this.onComplete,
    this.onNext,
    this.selectedCategory,
    this.selectedItem,
    this.itemDescription,
    this.locationInfo,
  }) : super(key: key);

  Widget _buildPriceHeader() {
    return SubtotalComponent(
      service: service,
      subservice: subservice,
      userSelections: userSelections,
    );
  }

  String? _getFittingDetails(Map<String, dynamic>? userSelections) {
    if (userSelections == null) return null;
    
    // Look for fitting detail responses - these are text inputs for fitting instructions
    for (var entry in userSelections.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Look for fitting-related text responses (contains "fitting" and is a string, but not the method itself)
      if (key.contains('fitting') && 
          key != 'fitting_method' && // Exclude the choice itself
          value is String && 
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    
    return null;
  }

void _debugPrintCompleteFlow(BuildContext context) {
  print('\n' + '='*60);
  print('       COMPLETE TAILOR FLOW DEBUG REPORT');
  print('='*60);
  
  // Get cart provider to understand the flow context
  final cartProvider = Provider.of<cart.CartProvider>(context, listen: false);
  
  // Create maps for storing question information
  final Map<String, String> allQuestionsMap = {};
  final Map<String, String> textQuestions = {}; // Local variable instead of field
  
  // Store service questions
  for (var question in service.questions) {
    allQuestionsMap[question.id] = question.question;
    // Also store text questions separately if needed
    if (question.questionType == 'text') {
      textQuestions[question.id] = question.question;
    }
  }
  
  // Store ALL subservice questions, not just the selected one
  for (var sub in service.subservices) {
    for (var question in sub.questions) {
      // Store with subservice prefix to handle questions unique to each subservice
      final prefixedId = '${sub.id}_${question.id}';
      allQuestionsMap[prefixedId] = question.question;
      if (question.questionType == 'text') {
        textQuestions[prefixedId] = question.question;
      }
    }
  }
  
  print('\n📋 FLOW OVERVIEW:');
  print('Flow Type: ${service.serviceType == 'alteration' ? 'ALTERATION' : 'REPAIR'} Flow');
  print('Current Date: ${DateTime.now().toString()}');
  print('Total Items in Cart: ${cartProvider.itemCount}');
  
  print('\n🏷️ CATEGORY & ITEM SELECTION:');
  if (selectedCategory != null) {
    print('Selected Category: ${selectedCategory!.name}');
    print('Category ID: ${selectedCategory!.id}');
    if (selectedCategory!.coverImage != null) {
      print('Category Image: ${selectedCategory!.coverImage!.fullUrl}');
    }
  } else {
    print('Selected Category: [NOT_PROVIDED]');
  }
  
  if (selectedItem != null) {
    print('Selected Item: ${selectedItem!.name}');
    print('Item ID: ${selectedItem!.id}');
    if (selectedItem!.coverImage != null) {
      print('Item Image: ${selectedItem!.coverImage!.fullUrl}');
    }
    print('Item Categories: ${selectedItem!.itemCategories.map((c) => c.name).join(", ")}');
    print('Available Services: ${selectedItem!.services.length}');
  } else {
    print('Selected Item: [NOT_PROVIDED]');
  }
  
  if (itemDescription != null && itemDescription!.isNotEmpty) {
    print('Item Description: $itemDescription');
  } else {
    print('Item Description: [NOT_PROVIDED]');
  }
  
  print('\n🔧 SERVICE SELECTION:');
  print('Service Name: ${service.name}');
  print('Service Type: ${service.serviceType}');
  print('Service ID: ${service.id}');
  print('Base Price: £${(service.price / 100.0).toStringAsFixed(2)}');
  print('Tailor Points: ${service.tailorPoints}');
  print('Service Description: ${service.description}');
  
  if (service.subservices.isNotEmpty) {
    print('\nAvailable Service Options:');
    for (var sub in service.subservices) {
      final isSelected = subservice?.id == sub.id;
      final marker = isSelected ? ' ← SELECTED' : '';
      print('  • ${sub.name} (${sub.priceModifier > 0 ? "+" : ""}£${(sub.priceModifier / 100.0).toStringAsFixed(2)})$marker');
    }
  }
  
  if (subservice != null) {
    print('\n🎯 SELECTED SERVICE OPTION:');
    print('Option Name: ${subservice!.name}');
    print('Option ID: ${subservice!.id}');
    print('Price Modifier: ${subservice!.priceModifier > 0 ? "+" : ""}£${(subservice!.priceModifier / 100.0).toStringAsFixed(2)}');
    print('Points Modifier: ${subservice!.tailorPointsModifier}');
    
    if (subservice!.description != null) {
      print('Description: ${subservice!.description}');
    }
    
    if (subservice!.questions.isNotEmpty) {
      print('Subservice Questions: ${subservice!.questions.length}');
    }
  }

  // Print fitting method if available
  String? fittingMethod;
  if (userSelections != null) {
    fittingMethod = userSelections!['fitting_method'] as String?;
  }
  
  if (fittingMethod != null) {
    print('\n📐 FITTING METHOD:');
    switch (fittingMethod) {
      case 'pin':
        print('Method: Pin fitting (using pins/clips)');
        print('Instructions: Fold to desired length and pin in place');
        break;
      case 'match':
        print('Method: Match to another item');
        print('Instructions: Use a similar item that fits correctly');
        break;
      case 'measure':
        print('Method: Measurement-based fitting');
        print('Instructions: Use measuring tape for precise measurements');
        break;
      case 'in_person':
        print('Method: In-person fitting at Selfridges');
        print('Instructions: Visit our Selfridges London location');
        break;
      default:
        print('Method: $fittingMethod');
    }
  }

  // Print location/instructions if available
  print('\n📍 LOCATION/INSTRUCTIONS:');
  if (locationInfo != null && locationInfo!.isNotEmpty) {
    print('Location: $locationInfo');
  } else {
    print('Location: [NOT_PROVIDED]');
  }

  if (userSelections != null && userSelections!.isNotEmpty) {
    print('\n❓ DYNAMIC QUESTIONS & ANSWERS:');
    double questionTotalModifier = 0.0;
    double subserviceTotalModifier = 0.0;
    int questionCount = 0;
    
    userSelections!.forEach((key, value) {
      if (value is QuestionOption) {
        questionCount++;
        
        String questionText = 'Question not found';
        String questionId = '';
        
        // Search through all questions to find the matching option
        for (var question in service.questions) {
          if (question.options.any((opt) => opt.id == value.id)) {
            questionText = question.question;
            questionId = question.id;
            break;
          }
        }
        
        if (questionText == 'Question not found' && subservice != null) {
          for (var question in subservice!.questions) {
            if (question.options.any((opt) => opt.id == value.id)) {
              questionText = question.question;
              questionId = question.id;
              break;
            }
          }
        }
        
        print('\nQuestion ${questionCount}: $questionText');
        print('  Question ID: $questionId');
        print('  Selected Answer: ${value.answer}');
        print('  Answer ID: ${value.id}');
        if (value.priceModifier != 0) {
          final priceModifier = value.priceModifier / 100.0;
          print('  Price Impact: ${priceModifier > 0 ? "+" : ""}£${priceModifier.toStringAsFixed(2)}');
          questionTotalModifier += priceModifier;
        }
        if (value.tailorPointsModifier != 0) {
          print('  Points Impact: ${value.tailorPointsModifier}');
        }
        // Note: deadEnd property might not exist in QuestionOption
      } 
      else if (value is Subservice) {
        print('\n🎯 SUBSERVICE SELECTION:');
        print('  Selected Option: ${value.name}');
        print('  Option ID: ${value.id}');
        final priceModifier = value.priceModifier / 100.0;
        print('  Price Modifier: ${priceModifier > 0 ? "+" : ""}£${priceModifier.toStringAsFixed(2)}');
        subserviceTotalModifier += priceModifier;
      } 
      else if (value is String && key == 'fitting_method') {
        print('\n📐 FITTING METHOD DETAILS:');
        print('  Method: $value');
      } 
      else if (value is String) {
        // Handle text responses - improved version
        questionCount++;
        String questionId = key;
        String questionText = 'Question not found';
        
        // First try exact match
        questionText = allQuestionsMap[questionId] ?? 'Question not found';
        
        // If not found, try removing '_text_response' suffix and check different ID patterns
        if (questionText == 'Question not found') {
          if (questionId.endsWith('_text_response')) {
            questionId = questionId.replaceAll('_text_response', '');
          }
          
          // Try direct match
          questionText = allQuestionsMap[questionId] ?? 'Question not found';
          
          // If still not found, try matching by the question ID part (after the last underscore)
          if (questionText == 'Question not found') {
            final questionIdPart = questionId.split('_').last;
            for (var entry in allQuestionsMap.entries) {
              if (entry.key.endsWith(questionIdPart)) {
                questionId = entry.key;
                questionText = entry.value;
                break;
              }
            }
          }
        }
        
        print('\nQuestion ${questionCount}: $questionText');
        print('  Question ID: $questionId');
        print('  Text Response: $value');
        
        // Only show available IDs if question still not found
        if (questionText == 'Question not found') {
          print('  ! Available Question IDs:');
          for (var entry in allQuestionsMap.entries) {
            if (entry.key.contains('_text') || entry.value.toLowerCase().contains('specify')) {
              print('    - ${entry.key}: ${entry.value}');
            }
          }
        }
      }
    });

    // Print delivery information
    print('\n🚚 DELIVERY INFORMATION:');
    String? deliveryMethod;
    DateTime? pickupDate;
    String? pickupTime;
    double deliveryCost = 0.0;
    
    if (userSelections != null) {
      deliveryMethod = userSelections!['delivery_method'] as String?;
      pickupDate = userSelections!['pickup_date'] as DateTime?;
      pickupTime = userSelections!['pickup_time'] as String?;
      if (userSelections!['pickup_cost'] is int) {
        deliveryCost = (userSelections!['pickup_cost'] as int) / 100.0;
      }
    }
    
    if (deliveryMethod != null) {
      print('Delivery Method: ${deliveryMethod.toUpperCase()}');
      
      if (deliveryMethod == 'pickup') {
        if (pickupDate != null) {
          print('Pickup Date: ${pickupDate.day}/${pickupDate.month}/${pickupDate.year}');
        }
        if (pickupTime != null) {
          print('Pickup Time: $pickupTime');
        }
        if (deliveryCost > 0) {
          print('Pickup Service Cost: £${deliveryCost.toStringAsFixed(2)}');
        }
      } else if (deliveryMethod == 'post') {
        print('Post Delivery: Items will be sent to shop address');
        print('Shop Address: SOJO Tailor Services, Oxford Street, London W1A 0AB');
      }
    } else {
      print('Delivery Method: [NOT_SELECTED]');
    }

    // Print price breakdown
    print('\n💰 PRICE BREAKDOWN:');
    final basePrice = service.price / 100.0;
    print('Base Price: £${basePrice.toStringAsFixed(2)}');
    
    if (questionTotalModifier != 0) {
      print('Question Modifiers: ${questionTotalModifier > 0 ? "+" : ""}£${questionTotalModifier.toStringAsFixed(2)}');
    }
    
    if (subserviceTotalModifier != 0) {
      print('Service Option Modifier: ${subserviceTotalModifier > 0 ? "+" : ""}£${subserviceTotalModifier.toStringAsFixed(2)}');
    }
    
    if (deliveryCost > 0) {
      print('Delivery Cost: +£${deliveryCost.toStringAsFixed(2)}');
    }
    
    final totalModifiers = questionTotalModifier + subserviceTotalModifier + deliveryCost;
    print('Total Modifiers: ${totalModifiers > 0 ? "+" : ""}£${totalModifiers.toStringAsFixed(2)}');
    
    final totalPrice = basePrice + totalModifiers;
    print('Final Total: £${totalPrice.toStringAsFixed(2)}');
  }

  print('\n📝 TAILOR NOTES:');
  String notes = notesController.text.trim();
  if (notes.isNotEmpty) {
    print('Notes: $notes');
    print('Notes Length: ${notes.length} characters');
  } else {
    print('Notes: No special instructions provided');
  }

  print('\n🛠️ TECHNICAL DETAILS:');
  print('Service Has Questions: ${service.questions.isNotEmpty} (${service.questions.length} questions)');
  print('Service Has Subservices: ${service.subservices.isNotEmpty} (${service.subservices.length} options)');
  print('Fitting Choices Available: ${service.fittingChoices.join(", ")}');
  print('Service Active: ${service.active}');
  print('Service Dead End: ${service.deadEnd}');
  
  if (subservice != null) {
    print('Subservice Has Questions: ${subservice!.questions.isNotEmpty}');
    print('Subservice Question Count: ${subservice!.questions.length}');
    print('Subservice Active: ${subservice!.active}');
    print('Subservice Dead End: ${subservice!.deadEnd}');
  }

  print('\n📊 FLOW STATISTICS:');
  int totalSteps = 1; // Category selection
  totalSteps += 1; // Item selection  
  totalSteps += 1; // Description
  totalSteps += 1; // Service selection
  if (service.subservices.isNotEmpty) totalSteps += 1;
  if (service.fittingChoices.isNotEmpty) totalSteps += 1;
  totalSteps += service.questions.length;
  if (subservice != null) totalSteps += subservice!.questions.length;
  totalSteps += 1; // Notes
  
  print('Estimated Total Steps: $totalSteps');
  
  // Count questions answered and text inputs
  int questionsAnswered = 0;
  int textInputs = 0;
  if (userSelections != null) {
    for (var entry in userSelections!.entries) {
      if (entry.value is QuestionOption) {
        questionsAnswered++;
      } else if (entry.value is String) {
        textInputs++;
      }
    }
  }
  
  print('Questions Answered: $questionsAnswered');
  print('Text Inputs Provided: $textInputs');

  print('\n' + '='*60);
  print('           END OF FLOW DEBUG REPORT');
  print('='*60 + '\n');
}

double _calculateCorrectTotalPrice() {
  final basePrice = service.price / 100.0;
  double questionTotalModifier = 0.0;
  double subserviceTotalModifier = 0.0;
  double deliveryCost = 0.0;
  
  if (userSelections != null) {
    userSelections!.forEach((key, value) {
      if (value is QuestionOption) {
        final priceModifier = value.priceModifier / 100.0;
        questionTotalModifier += priceModifier;
      } else if (value is Subservice) {
        final priceModifier = value.priceModifier / 100.0;
        subserviceTotalModifier += priceModifier;
      } else if (key == 'pickup_cost' && value is int) {
        // Add pickup cost (stored in pence, convert to pounds)
        deliveryCost += value / 100.0;
      }
    });
  }
  
  return basePrice + questionTotalModifier + subserviceTotalModifier + deliveryCost;
}

  void _addToCart(BuildContext context) {
    final cartProvider = Provider.of<cart.CartProvider>(context, listen: false);
    
    // Debug: Check notes content before processing
    print('NOTES CAPTURE DEBUG: Notes controller text: "${notesController.text}"');
    print('NOTES CAPTURE DEBUG: Notes controller text length: ${notesController.text.length}');
    print('NOTES CAPTURE DEBUG: Notes trimmed: "${notesController.text.trim()}"');
    
    // Create the same allQuestionsMap as used in debug output
    final Map<String, String> allQuestionsMap = {};
    
    // Store service questions
    for (var question in service.questions) {
      allQuestionsMap[question.id] = question.question;
    }
    
    // Store ALL subservice questions with prefixed IDs
    for (var sub in service.subservices) {
      for (var question in sub.questions) {
        final prefixedId = '${sub.id}_${question.id}';
        allQuestionsMap[prefixedId] = question.question;
      }
    }
    
    // Create question answer modifiers from userSelections
    final List<cart.QuestionAnswer> questionAnswers = [];
    Subservice? selectedSubservice;
    
    // First, extract the selected subservice from userSelections
    if (userSelections != null) {
      userSelections!.forEach((key, value) {
        if (value is Subservice) {
          selectedSubservice = value;
        }
      });
    }
    
    if (userSelections != null) {
      // First process all service questions
      for (var question in service.questions) {
        // Check for radio/select option answers
        userSelections!.forEach((key, value) {
          if (value is QuestionOption) {
            if (question.options.any((opt) => opt.id == value.id)) {
              questionAnswers.add(cart.QuestionAnswer(
                question: question.question,
                answer: value.answer,
                answerId: value.id,
                priceModifier: value.priceModifier.toDouble(),
                tailorPointsModifier: value.tailorPointsModifier,
              ));
            }
          }
        });

        // Check for text answers - try multiple possible key formats
        final possibleTextKeys = [
          '${question.id}_text_response',
          question.id,
          '${question.id}_text'
        ];
        
        for (final textKey in possibleTextKeys) {
          if (userSelections!.containsKey(textKey) && userSelections![textKey] is String) {
            final textResponse = userSelections![textKey] as String;
            if (textResponse.isNotEmpty) {
              questionAnswers.add(cart.QuestionAnswer(
                question: question.question,
                answer: textResponse,
                answerId: question.id,
                questionId: question.id,
                priceModifier: 0.0,
                tailorPointsModifier: 0,
                textResponse: textResponse,
                isTextInput: true,
              ));
              break; // Found the text response, no need to check other keys
            }
          }
        }
      }
      
      // Also check for any text responses that might be stored with different key patterns
      userSelections!.forEach((key, value) {
        if (value is String && value.isNotEmpty && !key.contains('fitting')) {
          // Look for the matching question text
          String questionText = 'Question not found';
          
          // Try to find matching question from allQuestionsMap
          questionText = allQuestionsMap[key] ?? 'Question not found';
          
          if (questionText == 'Question not found') {
            // Try removing suffixes and matching
            String cleanKey = key.replaceAll('_text_response', '').replaceAll('_text', '');
            questionText = allQuestionsMap[cleanKey] ?? 'Question not found';
          }
          
          if (questionText == 'Question not found') {
            // Try matching by the question ID part (after the last underscore)
            final questionIdPart = key.split('_').last;
            for (var entry in allQuestionsMap.entries) {
              if (entry.key.endsWith(questionIdPart)) {
                questionText = entry.value;
                break;
              }
            }
          }
          
          // Add the text response if we found a matching question
          if (questionText != 'Question not found') {
            questionAnswers.add(cart.QuestionAnswer(
              question: questionText,
              answer: value,
              answerId: key,
              questionId: key,
              priceModifier: 0.0,
              tailorPointsModifier: 0,
              textResponse: value,
              isTextInput: true,
            ));
          }
        }
      });
    }
    
    // Create subservice details if subservice is selected
    cart.SubserviceDetails? subserviceDetails;
    if (selectedSubservice != null) {
      final List<cart.QuestionAnswer> subserviceAnswers = [];
      
      // Process all subservice questions
      for (var question in selectedSubservice!.questions) {
        if (userSelections != null) {
          // Check for radio/select option answers
          userSelections!.forEach((key, value) {
            if (value is QuestionOption) {
              if (question.options.any((opt) => opt.id == value.id)) {
                subserviceAnswers.add(cart.QuestionAnswer(
                  question: question.question,
                  answer: value.answer,
                  answerId: value.id,
                  priceModifier: value.priceModifier.toDouble(),
                  tailorPointsModifier: value.tailorPointsModifier,
                ));
              }
            }
          });

          // Check for text answers - try multiple possible key formats
          final possibleTextKeys = [
            '${selectedSubservice!.id}_${question.id}_text_response',
            '${selectedSubservice!.id}_${question.id}',
            '${question.id}_text_response',
            question.id,
            '${question.id}_text'
          ];
          
          for (final textKey in possibleTextKeys) {
            if (userSelections!.containsKey(textKey) && userSelections![textKey] is String) {
              final textResponse = userSelections![textKey] as String;
              if (textResponse.isNotEmpty) {
                subserviceAnswers.add(cart.QuestionAnswer(
                  question: question.question,
                  answer: textResponse,
                  answerId: question.id,
                  questionId: question.id,
                  priceModifier: 0.0,
                  tailorPointsModifier: 0,
                  textResponse: textResponse,
                  isTextInput: true,
                ));
                break; // Found the text response, no need to check other keys
              }
            }
          }
        }
      }
      
      subserviceDetails = cart.SubserviceDetails(
        subservice: cart.Subservice(
          id: selectedSubservice!.id,
          name: selectedSubservice!.name,
          fittingChoices: selectedSubservice!.fittingChoices ?? [],
          priceModifier: selectedSubservice!.priceModifier.toDouble(),
          tailorPointsModifier: selectedSubservice!.tailorPointsModifier,
          questions: [], // Not needed for cart
          active: selectedSubservice!.active,
          description: selectedSubservice!.description,
          deadEnd: selectedSubservice!.deadEnd,
          coverImageUrl: selectedSubservice!.coverImage?.fullUrl,
        ),
        questionAnswerModifiers: subserviceAnswers,
      );
    }
    
    // Calculate the correct total price
    final correctTotalPrice = _calculateCorrectTotalPrice();
    
    // Extract delivery information from userSelections
    String? deliveryMethod;
    DateTime? pickupDate;
    String? pickupTime;
    double? pickupCost;
    
    if (userSelections != null) {
      deliveryMethod = userSelections!['delivery_method'] as String?;
      pickupDate = userSelections!['pickup_date'] as DateTime?;
      pickupTime = userSelections!['pickup_time'] as String?;
      if (userSelections!['pickup_cost'] is int) {
        pickupCost = (userSelections!['pickup_cost'] as int) / 100.0; // Convert pence to pounds
      }
    }
    
    // Get notes content for debugging
    final notesContent = notesController.text.trim();
    
    // Create service details
    final serviceDetails = cart.ServiceDetails(
      service: cart.Service(
        id: service.id,
        name: service.name,
        serviceType: service.serviceType,
        fittingChoices: service.fittingChoices,
        price: correctTotalPrice * 100, // Store as pence for cart compatibility
        tailorPoints: service.tailorPoints,
        questions: [], // Not needed for cart
        subservices: [], // Not needed for cart
        active: service.active,
        description: service.description,
        deadEnd: service.deadEnd,
        coverImageUrl: service.coverImage?.fullUrl,
      ),
      basePrice: service.price.toDouble(), // Store original base price in pounds
      fittingChoice: service.serviceType == 'alteration' ? (userSelections?['fitting_method'] as String?) : null,
      fittingDetails: service.serviceType == 'alteration' ? _getFittingDetails(userSelections) : null, // Dynamic fitting details
      repairLocation: service.serviceType == 'repair' ? locationInfo : null, // Case 5 location
      serviceDescription: service.serviceType == 'repair' ? itemDescription : null, // Case 2 description for repair
      tailorNotes: notesContent,
      questionAnswerModifiers: questionAnswers,
      subserviceDetails: subserviceDetails,
      serviceType: service.serviceType,
      // Add delivery information
      deliveryMethod: deliveryMethod,
      pickupDate: pickupDate,
      pickupTime: pickupTime,
      pickupCost: pickupCost,
    );
    
    // Debug: Check if notes were properly set in ServiceDetails
    print('NOTES CAPTURE DEBUG: ServiceDetails tailorNotes: "${serviceDetails.tailorNotes}"');
    print('NOTES CAPTURE DEBUG: ServiceDetails tailorNotes length: ${serviceDetails.tailorNotes.length}');
    
    // Create cart item
    final itemName = selectedItem?.name ?? itemDescription ?? 'Unknown Item';
    final cartItem = cart.CartItem(
      itemCategory: cart.ItemCategory(
        id: selectedCategory?.id ?? 'unknown',
        name: selectedCategory?.name ?? 'Unknown Category',
        coverImageUrl: selectedCategory?.coverImage?.fullUrl,
      ),
      itemDescription: itemName,
      item: cart.Service(
        id: selectedItem?.id ?? 'unknown',
        name: itemName,
        serviceType: service.serviceType,
        fittingChoices: [],
        price: 0.0,
        tailorPoints: 0,
        questions: [],
        subservices: [],
        active: true,
        description: itemName,
        deadEnd: false,
        coverImageUrl: selectedItem?.coverImage?.fullUrl,
      ),
      serviceDetails: [serviceDetails],
    );
    
    // Add to cart
    cartProvider.addItem(cartItem);
    
    // Show success toast
    final totalPrice = cartProvider.formatPrice(serviceDetails.totalPrice);
    final toastMessage = 'Selected Item: $itemName\nFinal Total: $totalPrice\nService Name: ${service.name}';
    
    CustomToast.showSuccess(context, toastMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceHeader(),
        const SizedBox(height: Dimensions.itemSpacing),
        SectionHeaderComponent(
          title: "Is there anything else we should know?",
          goldenText: "",
          subtitle: "Please leave any other notes which you'd like passed on to our tailors.",
          titleFontSize: Dimensions.titleFontSize,
          subtitleFontSize: Dimensions.subtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: Dimensions.itemSpacing),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                QuestionBoxComponent(
                  controller: notesController,
                  placeholder: 'Notes to our tailors...',
                  goldenColor: TailorService.luxuryGold,
                  maxLines: Dimensions.inputMaxLines.toInt(),
                  onChanged: (_) {},
                ),
                const SizedBox(height: Dimensions.itemSpacing),
                ActionButtonComponent(
                  title: onNext != null ? 'Next' : 'Add to basket',
                  icon: onNext != null ? Icons.arrow_forward : Icons.shopping_basket,
                  onPressed: () {
                    try {
                      // Debug: Check notes content before processing
                      print('NOTES DEBUG: Notes controller text: "${notesController.text}"');
                      print('NOTES DEBUG: Notes controller text length: ${notesController.text.length}');
                      print('NOTES DEBUG: Notes trimmed: "${notesController.text.trim()}"');
                      
                      if (onNext != null) {
                        // Continue to next step (delivery method)
                        print('NotesScreen: Next button pressed, calling onNext callback');
                        onNext!();
                      } else {
                        // Complete the service (add to cart)
                        print('NotesScreen: Add to basket button pressed');
                        _debugPrintCompleteFlow(context);
                        _addToCart(context);
                        onComplete();
                      }
                    } catch (e) {
                      print('NotesScreen: Error in button onPressed: $e');
                    }
                  },
                  goldenColor: TailorService.luxuryGold,
                  enabled: true, // Explicitly enable the button
                ),
                const SizedBox(height: Dimensions.itemSpacing),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 