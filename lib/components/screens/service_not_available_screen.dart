import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../services/dimensions.dart';
import '../section_header_component.dart';
import '../action_button_component.dart';
import '../question_box_component.dart';

class ServiceNotAvailableScreen extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onSubmit;

  const ServiceNotAvailableScreen({
    super.key,
    required this.textController,
    required this.onSubmit,
  });

  @override
  State<ServiceNotAvailableScreen> createState() => _ServiceNotAvailableScreenState();
}

class _ServiceNotAvailableScreenState extends State<ServiceNotAvailableScreen> {
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  DateTime? _lastSubmitTime;
  static const Duration _rateLimitDuration = Duration(seconds: 3);

  void _handleSubmit() {
    if (_isSubmitting || _isSubmitted) return;
    
    final now = DateTime.now();
    if (_lastSubmitTime != null && 
        now.difference(_lastSubmitTime!) < _rateLimitDuration) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _lastSubmitTime = now;
    });
    
    widget.onSubmit();
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Dimensions.itemSpacing),
        SectionHeaderComponent(
          title: "Sorry, we don't offer this service.",
          goldenText: "",
          subtitle: "Unfortunately, we don't currently offer this service as it may be too large of an alteration, an item type we don't offer or an alteration that is not recommended on this type of item.",
          titleFontSize: Dimensions.titleFontSize,
          subtitleFontSize: Dimensions.subtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: Dimensions.sectionSpacing),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go back to select a service we do offer, or submit a service request below.',
                  style: TextStyle(
                    fontSize: Dimensions.subtitleFontSize,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Dimensions.itemSpacing),
                QuestionBoxComponent(
                  controller: widget.textController,
                  placeholder: 'e.g. swimming costume hole repair',
                  goldenColor: TailorService.luxuryGold,
                  maxLines: 3,
                  onChanged: (_) {},
                ),
                const SizedBox(height: Dimensions.itemSpacing),
                ActionButtonComponent(
                  title: _isSubmitted ? 'Submitted' : (_isSubmitting ? 'Submitting...' : 'Submit'),
                  icon: _isSubmitted ? Icons.check : (_isSubmitting ? Icons.hourglass_empty : Icons.send),
                  onPressed: _handleSubmit,
                  goldenColor: TailorService.luxuryGold,
                  enabled: !_isSubmitting && !_isSubmitted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 