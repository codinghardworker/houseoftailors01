import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../models/service.dart';
import '../../models/subservice.dart';
import '../../models/question.dart';
import '../../models/question_option.dart';
import '../section_header_component.dart';
import '../question_box_component.dart';
import '../next_button_component.dart';
import '../repair_option_button_component.dart';
import '../subtotal_component.dart';
import '../../services/dimensions.dart';

class QuestionScreenComponent extends StatefulWidget {
  final Question question;
  final Service service;
  final Subservice? subservice;
  final String questionKey;
  final TextEditingController textController;
  final Map<String, dynamic>? userSelections;
  final bool hasValue;
  final Function(String, QuestionOption) onOptionSelected;
  final VoidCallback onNextStep;
  final Function(String)? onTextChanged;
  final String? placeholder;

  const QuestionScreenComponent({
    Key? key,
    required this.question,
    required this.service,
    this.subservice,
    required this.questionKey,
    required this.textController,
    this.userSelections,
    required this.hasValue,
    required this.onOptionSelected,
    required this.onNextStep,
    this.onTextChanged,
    this.placeholder,
  }) : super(key: key);

  @override
  State<QuestionScreenComponent> createState() => _QuestionScreenComponentState();
}

class _QuestionScreenComponentState extends State<QuestionScreenComponent> {
  bool _hasTextValue = false;

  @override
  void initState() {
    super.initState();
    _hasTextValue = widget.textController.text.trim().isNotEmpty;
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    if (hasText != _hasTextValue) {
      setState(() {
        _hasTextValue = hasText;
      });
    }
    widget.onTextChanged?.call(widget.textController.text);
  }

  Widget _buildPriceHeader() {
    return SubtotalComponent(
      service: widget.service,
      subservice: widget.subservice,
      userSelections: widget.userSelections,
    );
  }

  Widget _buildTextInput() {
    return QuestionBoxComponent(
      controller: widget.textController,
      placeholder: widget.placeholder ?? 'Your response',
      goldenColor: TailorService.luxuryGold,
      maxLines: widget.question.isTextType ? 3 : 2,
      onChanged: (value) {
        _onTextChanged();
      },
    );
  }

  Widget _buildRadioOptions() {
    return Column(
      children: widget.question.options.map((option) {
        String priceText = '';
        if (option.priceModifier > 0) {
          priceText = '+ £${(option.priceModifier / 100.0).toStringAsFixed(2)}';
        }
        
        return RepairOptionButtonComponent(
          label: option.answer,
          price: priceText,
          onTap: () => widget.onOptionSelected(widget.questionKey, option),
          goldenColor: TailorService.luxuryGold,
        );
      }).toList(),
    );
  }

  Widget _buildNextButton() {
    final bool isEnabled = widget.question.isTextType ? _hasTextValue : widget.hasValue;
    
    return NextButtonComponent(
      onPressed: isEnabled ? widget.onNextStep : null,
      enabled: isEnabled,
      goldenColor: TailorService.luxuryGold,
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
          title: widget.question.question,
          goldenText: "",
          subtitle: widget.question.explainer ?? "",
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
                if (widget.question.isTextType || !widget.question.hasOptions) ...[
                  _buildTextInput(),
                  const SizedBox(height: Dimensions.itemSpacing),
                  _buildNextButton(),
                ] else if (widget.question.isRadioType && widget.question.hasOptions)
                  _buildRadioOptions(),
                const SizedBox(height: Dimensions.itemSpacing),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 