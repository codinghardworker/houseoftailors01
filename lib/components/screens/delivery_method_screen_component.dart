import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../models/service.dart';
import '../../models/subservice.dart';
import '../section_header_component.dart';
import '../perfect_fit_card_component.dart';
import '../subtotal_component.dart';
import '../../services/dimensions.dart';

class DeliveryMethodScreenComponent extends StatelessWidget {
  final Service service;
  final Function(String) onMethodSelected;
  final Subservice? subservice;
  final Map<String, dynamic>? userSelections;

  const DeliveryMethodScreenComponent({
    Key? key,
    required this.service,
    required this.onMethodSelected,
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

  Widget _buildDeliveryOption(BuildContext context, String method) {
    String title;
    String description;
    IconData icon;
    
    switch (method) {
      case 'pickup':
        title = 'Pickup';
        description = 'Schedule a convenient pickup time. We\'ll collect your items from your location.';
        icon = Icons.local_shipping_outlined;
        break;
      case 'post':
        title = 'Post';
        description = 'Send your items by post. We\'ll provide packaging and shipping instructions.';
        icon = Icons.mail_outline;
        break;
      default:
        title = method;
        description = 'Select this delivery method';
        icon = Icons.help_outline;
    }
    
    return PerfectFitCardComponent(
      title: title,
      description: description,
      icon: icon,
      onTap: () {
        // Call the method selection immediately without any API calls
        onMethodSelected(method);
      },
      goldenColor: TailorService.luxuryGold,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Static delivery methods - no API calls
    final List<String> deliveryMethods = ['pickup', 'post'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceHeader(),
        const SizedBox(height: Dimensions.smallSpacing),
        SectionHeaderComponent(
          title: "How would you like to send your items?",
          goldenText: "",
          subtitle: "Choose between pickup or post to get your items to our tailors.",
          titleFontSize: Dimensions.titleFontSize,
          subtitleFontSize: Dimensions.subtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.screenPadding),
              child: Column(
                children: [
                  for (String method in deliveryMethods) ...[
                    _buildDeliveryOption(context, method),
                    if (method != deliveryMethods.last)
                      const SizedBox(height: Dimensions.cardSpacing),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}