import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../models/service.dart';
import '../../models/subservice.dart';
import '../section_header_component.dart';
import '../next_button_component.dart';
import '../subtotal_component.dart';
import '../../services/dimensions.dart';

class InstructionScreenComponent extends StatelessWidget {
  final Service service;
  final VoidCallback onNext;
  final String? customInstructions;
  final String? fittingMethod;
  final Subservice? subservice;
  final Map<String, dynamic>? userSelections;

  const InstructionScreenComponent({
    Key? key,
    required this.service,
    required this.onNext,
    this.customInstructions,
    this.fittingMethod,
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

  Widget _buildInstructionStep(int number, String text, {bool isDarkTheme = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: TailorService.luxuryGold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: Dimensions.subtitleFontSize,
                color: isDarkTheme ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseInstructionSteps(String instructions) {
    // Parse the instructions text to extract numbered steps
    List<String> steps = [];
    
    // Split by newlines first since our extraction now uses newlines
    final lines = instructions.split('\n');
    
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Check if line starts with number followed by period
      final numberMatch = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(trimmed);
      if (numberMatch != null) {
        final stepText = numberMatch.group(2)?.trim();
        if (stepText != null && stepText.isNotEmpty) {
          steps.add(stepText);
        }
      } else if (trimmed.startsWith('•')) {
        // Handle bullet points
        final bulletText = trimmed.substring(1).trim();
        if (bulletText.isNotEmpty) {
          steps.add(bulletText);
        }
      } else if (!trimmed.contains(':') && trimmed.length > 10) {
        // Add as step if it's substantial text and not a header
        steps.add(trimmed);
      }
    }
    
    // If no structured steps found, try the old regex method
    if (steps.isEmpty) {
      final regex = RegExp(r'(\d+\.\s)');
      final parts = instructions.split(regex);
      
      for (int i = 1; i < parts.length; i += 2) {
        if (i + 1 < parts.length) {
          final stepText = parts[i + 1].trim();
          if (stepText.isNotEmpty) {
            steps.add(stepText);
          }
        }
      }
    }
    
    return steps;
  }

  IconData _getMethodIcon() {
    switch (fittingMethod?.toLowerCase()) {
      case 'pin':
        return Icons.push_pin;
      case 'match':
        return Icons.checkroom;
      case 'measure':
        return Icons.straighten;
      case 'person':
        return Icons.person;
      default:
        return Icons.push_pin;
    }
  }

  String _getMethodTitle() {
    switch (fittingMethod?.toLowerCase()) {
      case 'pin':
        return 'Pin fitting guide';
      case 'match':
        return 'Match fitting guide';
      case 'measure':
        return 'Measurement guide';
      case 'person':
        return 'In-person fitting guide';
      default:
        return 'Fitting guide';
    }
  }

  Widget _buildCustomInstructions(BuildContext context) {
    if (customInstructions == null || customInstructions!.isEmpty) {
      return _buildDefaultInstructions(context);
    }

    final steps = _parseInstructionSteps(customInstructions!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.sectionSpacing),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.grey[900],
            collapsedBackgroundColor: Colors.grey[900],
            iconColor: TailorService.luxuryGold,
            collapsedIconColor: TailorService.luxuryGold,
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Row(
            children: [
              Icon(
                _getMethodIcon(),
                color: TailorService.luxuryGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _getMethodTitle(),
                style: TextStyle(
                  fontSize: Dimensions.subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (steps.isNotEmpty) ...[
                    // Display parsed steps
                    for (int i = 0; i < steps.length; i++) ...[
                      _buildInstructionStep(i + 1, steps[i], isDarkTheme: true),
                      if (i < steps.length - 1) const SizedBox(height: 12),
                    ],
                  ] else ...[
                    // Display raw text if parsing failed
                    Text(
                      customInstructions!,
                      style: TextStyle(
                        fontSize: Dimensions.subtitleFontSize,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultInstructions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.sectionSpacing),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.grey[900],
            collapsedBackgroundColor: Colors.grey[900],
            iconColor: TailorService.luxuryGold,
            collapsedIconColor: TailorService.luxuryGold,
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          title: Row(
            children: [
              Icon(
                _getMethodIcon(),
                color: TailorService.luxuryGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _getMethodTitle(),
                style: TextStyle(
                  fontSize: Dimensions.subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionStep(1, 'Fold the sleeve hem under to your desired length using a mirror.', isDarkTheme: true),
                  const SizedBox(height: 12),
                  _buildInstructionStep(2, 'Place the pin at the highest point to ensure it does not flop down.', isDarkTheme: true),
                  const SizedBox(height: 12),
                  _buildInstructionStep(3, 'Pin the front, sides, and back to secure the fold evenly.', isDarkTheme: true),
                  const SizedBox(height: 12),
                  _buildInstructionStep(4, 'Check the length in the mirror and adjust if needed.', isDarkTheme: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceHeader(),
        const SizedBox(height: Dimensions.itemSpacing),
        SectionHeaderComponent(
          title: "Learn how to ",
          goldenText: "fit your item",
          subtitle: "Follow these steps to ensure the perfect fit.",
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
                _buildCustomInstructions(context),
                NextButtonComponent(
                  onPressed: onNext,
                  enabled: true,
                  goldenColor: TailorService.luxuryGold,
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