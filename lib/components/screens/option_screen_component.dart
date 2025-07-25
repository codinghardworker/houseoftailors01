import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../services/responsive_grid.dart';
import '../../models/service.dart';
import '../../models/subservice.dart';
import '../../models/question_option.dart';
import '../section_header_component.dart';
import '../category_card_component.dart';
import '../subtotal_component.dart';
import '../../services/dimensions.dart';

class OptionScreenComponent extends StatelessWidget {
  final Service service;
  final List<Subservice> subservices;
  final Map<String, dynamic>? userSelections;
  final String? pressedCard;
  final Function(Service, Subservice) onSubserviceSelected;
  final Function(String) onPressedCardChanged;

  const OptionScreenComponent({
    Key? key,
    required this.service,
    required this.subservices,
    this.userSelections,
    required this.pressedCard,
    required this.onSubserviceSelected,
    required this.onPressedCardChanged,
  }) : super(key: key);

  Widget _buildPriceHeader() {
    // Pass the currently selected subservice if any
    Subservice? selectedSubservice;
    if (userSelections != null) {
      final selected = userSelections!['selected_subservice'];
      if (selected is Subservice) {
        selectedSubservice = selected;
      }
    }
    
    return SubtotalComponent(
      service: service,
      subservice: selectedSubservice,
      userSelections: userSelections,
    );
  }

  int _calculateOptionPrice(Subservice subservice) {
    // Start with base service price
    int totalPrice = service.price;
    
    // Add price modifiers from previous selections
    if (userSelections != null) {
      for (var entry in userSelections!.entries) {
        var value = entry.value;
        if (value is QuestionOption) {
          totalPrice += value.priceModifier;
        }
      }
    }
    
    // Add this option's price modifier
    totalPrice += subservice.priceModifier;
    
    return totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceHeader(),
        const SizedBox(height: Dimensions.itemSpacing),
        SectionHeaderComponent(
          title: "Choose your ",
          goldenText: "option",
          subtitle: "Select the specific option for this service.",
          titleFontSize: Dimensions.titleFontSize,
          subtitleFontSize: Dimensions.subtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: Dimensions.itemSpacing),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: ResponsiveGridDelegate.getDelegate(context, type: GridType.category),
            itemCount: subservices.length,
            itemBuilder: (context, index) {
              final subservice = subservices[index];
              final String imageUrl = subservice.coverImage?.url != null 
                ? 'https://payload.sojo.uk${subservice.coverImage!.url}'
                : '';
              
              // Calculate price for this option
              final int finalPrice = _calculateOptionPrice(subservice);
              
              // Format price text
              final String priceText = finalPrice > 0 
                ? '£${(finalPrice / 100.0).toStringAsFixed(2)}'
                : '';
              
              // Check if this subservice is currently selected
              final bool isSelected = userSelections != null &&
                userSelections!['selected_subservice'] == subservice;
              
              return CategoryCardComponent(
                title: subservice.name,
                imageUrl: imageUrl,
                fallbackIcon: Icons.construction_outlined,
                isPressed: isSelected || pressedCard == subservice.name,
                onTap: () => onSubserviceSelected(service, subservice),
                onTapDown: () => onPressedCardChanged(subservice.name),
                onTapUp: () => onPressedCardChanged(''),
                onTapCancel: () => onPressedCardChanged(''),
                scaleAnimation: null,
                goldenColor: TailorService.luxuryGold,
                subtitle: priceText,
                maxLines: 2,
                aspectRatio: 1,
                imageBoxFit: BoxFit.cover,
              );
            },
          ),
        ),
      ],
    );
  }
} 