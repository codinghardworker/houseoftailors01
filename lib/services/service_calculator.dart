import '../models/service.dart';
import '../models/subservice.dart';
import '../models/question.dart';
import '../models/question_option.dart';

class ServiceCalculator {
  /// Calculate total price for a service with selected options
  static ServiceCalculation calculateServicePrice({
    required Service service,
    List<Subservice>? selectedSubservices,
    Map<String, QuestionOption>? selectedOptions,
  }) {
    int basePrice = service.price;
    int baseTailorPoints = service.tailorPoints;
    
    int totalPriceModifier = 0;
    int totalTailorPointsModifier = 0;
    
    List<PriceBreakdown> breakdown = [
      PriceBreakdown(
        description: service.name,
        price: basePrice,
        tailorPoints: baseTailorPoints,
        type: PriceBreakdownType.base,
      ),
    ];

    // Add subservice modifiers
    if (selectedSubservices != null) {
      for (final subservice in selectedSubservices) {
        totalPriceModifier += subservice.priceModifier;
        totalTailorPointsModifier += subservice.tailorPointsModifier;
        
        breakdown.add(PriceBreakdown(
          description: subservice.name,
          price: subservice.priceModifier,
          tailorPoints: subservice.tailorPointsModifier,
          type: PriceBreakdownType.subservice,
        ));
      }
    }

    // Add question option modifiers
    if (selectedOptions != null) {
      for (final option in selectedOptions.values) {
        totalPriceModifier += option.priceModifier;
        totalTailorPointsModifier += option.tailorPointsModifier;
        
        if (option.priceModifier != 0 || option.tailorPointsModifier != 0) {
          breakdown.add(PriceBreakdown(
            description: option.answer,
            price: option.priceModifier,
            tailorPoints: option.tailorPointsModifier,
            type: PriceBreakdownType.option,
          ));
        }
      }
    }

    final totalPrice = basePrice + totalPriceModifier;
    final totalTailorPoints = baseTailorPoints + totalTailorPointsModifier;

    return ServiceCalculation(
      service: service,
      basePrice: basePrice,
      baseTailorPoints: baseTailorPoints,
      totalPrice: totalPrice,
      totalTailorPoints: totalTailorPoints,
      priceModifier: totalPriceModifier,
      tailorPointsModifier: totalTailorPointsModifier,
      breakdown: breakdown,
      selectedSubservices: selectedSubservices ?? [],
      selectedOptions: selectedOptions ?? {},
    );
  }

  /// Calculate total for multiple services
  static MultiServiceCalculation calculateMultipleServices(
    List<ServiceCalculation> serviceCalculations,
  ) {
    int totalPrice = 0;
    int totalTailorPoints = 0;
    
    for (final calculation in serviceCalculations) {
      totalPrice += calculation.totalPrice;
      totalTailorPoints += calculation.totalTailorPoints;
    }

    return MultiServiceCalculation(
      serviceCalculations: serviceCalculations,
      totalPrice: totalPrice,
      totalTailorPoints: totalTailorPoints,
    );
  }

  /// Get price range for a service (min and max possible prices)
  static PriceRange getServicePriceRange(Service service) {
    int minPrice = service.price;
    int maxPrice = service.price;

    // Calculate min/max from subservices
    for (final subservice in service.subservices) {
      if (subservice.active) {
        if (subservice.priceModifier < 0) {
          minPrice += subservice.priceModifier;
        } else {
          maxPrice += subservice.priceModifier;
        }
      }
    }

    // Calculate min/max from question options
    for (final question in service.questions) {
      int minOption = 0;
      int maxOption = 0;
      
      for (final option in question.options) {
        if (option.active) {
          if (option.priceModifier < minOption) {
            minOption = option.priceModifier;
          }
          if (option.priceModifier > maxOption) {
            maxOption = option.priceModifier;
          }
        }
      }
      
      minPrice += minOption;
      maxPrice += maxOption;
    }

    return PriceRange(
      minPrice: minPrice,
      maxPrice: maxPrice,
      basePrice: service.price,
    );
  }

  /// Check if a service configuration is valid
  static ValidationResult validateServiceConfiguration({
    required Service service,
    List<Subservice>? selectedSubservices,
    Map<String, QuestionOption>? selectedOptions,
  }) {
    List<String> errors = [];
    List<String> warnings = [];

    // Validate subservices belong to the service
    if (selectedSubservices != null) {
      for (final subservice in selectedSubservices) {
        if (!service.subservices.any((s) => s.id == subservice.id)) {
          errors.add('Subservice ${subservice.name} does not belong to service ${service.name}');
        }
        if (!subservice.active) {
          warnings.add('Subservice ${subservice.name} is not active');
        }
      }
    }

    // Validate question options
    if (selectedOptions != null) {
      for (final entry in selectedOptions.entries) {
        final questionId = entry.key;
        final option = entry.value;
        
        final question = service.questions.firstWhere(
          (q) => q.id == questionId,
          orElse: () => throw ArgumentError('Question $questionId not found in service'),
        );

        if (!question.options.any((o) => o.id == option.id)) {
          errors.add('Option ${option.answer} does not belong to question ${question.question}');
        }
        
        if (!option.active) {
          warnings.add('Option ${option.answer} is not active');
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Format price in dollars
  static String formatPrice(int priceInCents) {
    return '\$${(priceInCents / 100).toStringAsFixed(2)}';
  }

  /// Format price range
  static String formatPriceRange(PriceRange range) {
    if (range.minPrice == range.maxPrice) {
      return formatPrice(range.minPrice);
    }
    return '${formatPrice(range.minPrice)} - ${formatPrice(range.maxPrice)}';
  }
}

class ServiceCalculation {
  final Service service;
  final int basePrice;
  final int baseTailorPoints;
  final int totalPrice;
  final int totalTailorPoints;
  final int priceModifier;
  final int tailorPointsModifier;
  final List<PriceBreakdown> breakdown;
  final List<Subservice> selectedSubservices;
  final Map<String, QuestionOption> selectedOptions;

  ServiceCalculation({
    required this.service,
    required this.basePrice,
    required this.baseTailorPoints,
    required this.totalPrice,
    required this.totalTailorPoints,
    required this.priceModifier,
    required this.tailorPointsModifier,
    required this.breakdown,
    required this.selectedSubservices,
    required this.selectedOptions,
  });

  double get totalPriceInDollars => totalPrice / 100.0;
  double get basePriceInDollars => basePrice / 100.0;
  String get formattedTotalPrice => ServiceCalculator.formatPrice(totalPrice);
  String get formattedBasePrice => ServiceCalculator.formatPrice(basePrice);
}

class MultiServiceCalculation {
  final List<ServiceCalculation> serviceCalculations;
  final int totalPrice;
  final int totalTailorPoints;

  MultiServiceCalculation({
    required this.serviceCalculations,
    required this.totalPrice,
    required this.totalTailorPoints,
  });

  double get totalPriceInDollars => totalPrice / 100.0;
  String get formattedTotalPrice => ServiceCalculator.formatPrice(totalPrice);
  int get serviceCount => serviceCalculations.length;
}

class PriceBreakdown {
  final String description;
  final int price;
  final int tailorPoints;
  final PriceBreakdownType type;

  PriceBreakdown({
    required this.description,
    required this.price,
    required this.tailorPoints,
    required this.type,
  });

  double get priceInDollars => price / 100.0;
  String get formattedPrice => ServiceCalculator.formatPrice(price);
}

enum PriceBreakdownType {
  base,
  subservice,
  option,
}

class PriceRange {
  final int minPrice;
  final int maxPrice;
  final int basePrice;

  PriceRange({
    required this.minPrice,
    required this.maxPrice,
    required this.basePrice,
  });

  double get minPriceInDollars => minPrice / 100.0;
  double get maxPriceInDollars => maxPrice / 100.0;
  double get basePriceInDollars => basePrice / 100.0;
  
  bool get hasRange => minPrice != maxPrice;
  int get priceSpread => maxPrice - minPrice;
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
} 