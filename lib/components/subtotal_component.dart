import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/subservice.dart';
import '../models/question_option.dart';
import '../services/tailor_service.dart';
import './price_component.dart';

class SubtotalComponent extends StatelessWidget {
  final Service? service;
  final Subservice? subservice;
  final Map<String, dynamic>? userSelections;
  final String label;

  const SubtotalComponent({
    Key? key,
    this.service,
    this.subservice,
    this.userSelections,
    this.label = 'Your subtotal',
  }) : super(key: key);

  int _calculateTotalPrice() {
    if (service == null) return 0;
    
    int totalPrice = service!.price;
    
    // Add price modifiers from selected options
    if (userSelections != null) {
      // Track if we've already added a subservice price
      bool hasAddedSubservicePrice = false;
      
      for (var entry in userSelections!.entries) {
        var value = entry.value;
        var key = entry.key;
        
        if (value is QuestionOption) {
          totalPrice += value.priceModifier;
        } else if (value is Subservice) {
          // Add selected subservice price modifier
          totalPrice += value.priceModifier;
          hasAddedSubservicePrice = true;
        } else if (key == 'selected_subservice' && value == subservice) {
          // If subservice is selected but not yet added
          if (!hasAddedSubservicePrice) {
            totalPrice += subservice!.priceModifier;
            hasAddedSubservicePrice = true;
          }
        } else if (key == 'pickup_cost' && value is int) {
          // Add pickup cost
          totalPrice += value;
        }
      }
      
      // If we have a subservice but it's not in userSelections yet
      if (subservice != null && !hasAddedSubservicePrice) {
        totalPrice += subservice!.priceModifier;
      }
    } else if (subservice != null) {
      // If we have no userSelections but have a subservice
      totalPrice += subservice!.priceModifier;
    }
    
    return totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotalPrice();
    
    // Don't show price if it's 0
    if (totalPrice == 0) return const SizedBox.shrink();
    
    return PriceComponent(
      label: label,
      price: '£${(totalPrice / 100.0).toStringAsFixed(2)}',
      goldenColor: TailorService.luxuryGold,
    );
  }
} 