import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../services/responsive_grid.dart';
import '../../models/service.dart';
import '../section_header_component.dart';
import '../category_card_component.dart';
import '../../services/dimensions.dart';

class ServiceCardScreenComponent extends StatelessWidget {
  final List<Service> services;
  final String? pressedCard;
  final Function(Service) onServiceSelected;
  final Function(String) onPressedCardChanged;

  const ServiceCardScreenComponent({
    Key? key,
    required this.services,
    required this.pressedCard,
    required this.onServiceSelected,
    required this.onPressedCardChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderComponent(
          title: "What service does your ",
          goldenText: "item need?",
          subtitle: "Choose the service you'd like us to complete on your item.",
          titleFontSize: Dimensions.headerTitleFontSize,
          subtitleFontSize: Dimensions.headerSubtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: Dimensions.sectionSpacing),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: ResponsiveGridDelegate.getDelegate(context, type: GridType.category),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final imageUrl = service.coverImage?.fullUrl ?? '';
              final priceText = service.price > 0 
                  ? 'From £${(service.price / 100.0).toStringAsFixed(2)}' 
                  : '';
              
              return CategoryCardComponent(
                title: service.name,
                imageUrl: imageUrl,
                fallbackIcon: Icons.design_services,
                isPressed: pressedCard == service.name,
                onTap: () => onServiceSelected(service),
                onTapDown: () => onPressedCardChanged(service.name),
                onTapUp: () => onServiceSelected(service),
                onTapCancel: () => onPressedCardChanged(''),
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