import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../models/service.dart';
import '../../models/subservice.dart';
import '../section_header_component.dart';
import '../perfect_fit_card_component.dart';
import '../subtotal_component.dart';
import '../../services/dimensions.dart';

class PerfectFitScreenComponent extends StatelessWidget {
  final Service service;
  final Function(String) onFittingSelected;
  final Subservice? subservice;
  final Map<String, dynamic>? userSelections;

  const PerfectFitScreenComponent({
    Key? key,
    required this.service,
    required this.onFittingSelected,
    this.subservice,
    this.userSelections,
  }) : super(key: key);

  Widget _buildPriceHeader() {
    return SubtotalComponent(
      service: service,
      subservice: subservice,
      userSelections: userSelections,
    );
  }

  Widget _buildFittingOption(String choice) {
    String title;
    String description;
    IconData icon;
    
    switch (choice) {
      case 'match':
        title = 'Match to another item';
        description = 'Best for simple alterations and if you don\'t have any fitting materials. You will need a similar item that fits you correctly.';
        icon = Icons.checkroom;
        break;
      case 'pin':
        title = 'Pin your item';
        description = 'Best for fitting if you have someone to help you. You will need a few sewing pins, safety pins or clips.';
        icon = Icons.push_pin;
        break;
      case 'measure':
        title = 'Measure your item';
        description = 'Best for getting the most accurate fit and if you are fitting your item alone. You will need a measuring tape.';
        icon = Icons.straighten;
        break;
      case 'in_person':
        title = 'In-person fitting';
        description = 'Best for complex alterations and professional advice. Come along to our space at Selfridges London to get fitted in-person by a SOJO tailor.';
        icon = Icons.person;
        break;
      default:
        title = choice;
        description = 'Select this option';
        icon = Icons.help_outline;
    }
    
    return PerfectFitCardComponent(
      title: title,
      description: description,
      icon: icon,
      onTap: () => onFittingSelected(choice),
      goldenColor: TailorService.luxuryGold,
    );
  }



  @override
  Widget build(BuildContext context) {
    // Get available fitting choices, always include in_person
    final List<String> availableChoices = [...service.fittingChoices];
    if (!availableChoices.contains('in_person')) {
      availableChoices.add('in_person');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceHeader(),
        const SizedBox(height: Dimensions.smallSpacing), // Reduced spacing
        SectionHeaderComponent(
          title: "How would you like to fit your item?",
          goldenText: "",
          subtitle: "Help us ensure we get you the perfect fit by selecting one of the options below.",
          titleFontSize: Dimensions.titleFontSize,
          subtitleFontSize: Dimensions.subtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: 16.0), // Added small padding below section header
        Expanded(
          child: _buildListLayout(availableChoices),
        ),
      ],
    );
  }

  Widget _buildListLayout(List<String> availableChoices) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.screenPadding),
        child: Column(
          children: [
            // Only show available fitting options
            for (String choice in availableChoices) ...[
              _buildFittingOption(choice),
              if (choice != availableChoices.last)
                const SizedBox(height: Dimensions.cardSpacing),
            ],
          ],
        ),
      ),
    );
  }
} 