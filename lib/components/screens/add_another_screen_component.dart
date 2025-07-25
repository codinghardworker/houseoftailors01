import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../section_header_component.dart';
import '../option_card_component.dart';
import '../action_button_component.dart';
import '../cart_modal_component.dart';
import '../../services/tailor_service.dart';
import '../../services/dimensions.dart';
import '../../models/service.dart' as ModelService;
import '../../models/item_category.dart' as ModelItemCategory;
import '../../models/item.dart';
import '../../providers/cart_provider.dart';

class AddAnotherScreenComponent extends StatefulWidget {
  final Function(String) onOptionSelected;
  final VoidCallback onGoToBasket;
  final ModelService.Service? currentService;
  final ModelItemCategory.ItemCategory? selectedCategory;
  final Item? selectedItem;
  final String? itemDescription;
  final Map<String, dynamic>? userSelections;
  final String? serviceType;

  const AddAnotherScreenComponent({
    Key? key,
    required this.onOptionSelected,
    required this.onGoToBasket,
    this.currentService,
    this.selectedCategory,
    this.selectedItem,
    this.itemDescription,
    this.userSelections,
    this.serviceType,
  }) : super(key: key);

  @override
  State<AddAnotherScreenComponent> createState() => _AddAnotherScreenComponentState();
}

class _AddAnotherScreenComponentState extends State<AddAnotherScreenComponent> {

  @override
  Widget build(BuildContext context) {
    final headerContent = TailorService.getAddAnotherScreenHeader();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Dimensions.itemSpacing),
        const SizedBox(height: Dimensions.itemSpacing),
        SectionHeaderComponent(
          title: headerContent.title,
          goldenText: headerContent.goldenText,
          subtitle: headerContent.subtitle,
          titleFontSize: 24.0, // Reduced from headerTitleFontSize
          subtitleFontSize: 13.0, // Reduced from headerSubtitleFontSize
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: 16.0), // Reduced from sectionSpacing
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  _buildOptionCards(),
                  const SizedBox(height: 20.0), // Reduced from sectionSpacing
                  _buildGoToBasketButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCards() {
    final options = TailorService.getAddAnotherOptions();
    
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          OptionCardComponent(
            title: options[i].title,
            description: options[i].description,
            icon: _getIconFromString(options[i].icon),
            onTap: () => widget.onOptionSelected(options[i].action),
            goldenColor: TailorService.luxuryGold,
          ),
          if (i < options.length - 1)
            const SizedBox(height: 8.0), // Small gap between cards
        ],
      ],
    );
  }

  Widget _buildGoToBasketButton() {
    return Builder(
      builder: (context) => ActionButtonComponent(
        title: 'Go to basket',
        icon: Icons.arrow_forward,
        onPressed: () {
          _showCartModal(context);
        },
        goldenColor: TailorService.luxuryGold,
      ),
    );
  }


  void _showCartModal(BuildContext context) {
    CartModalComponent.showCartModal(context);
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'design_services':
        return Icons.design_services;
      case 'add_shopping_cart':
        return Icons.add_shopping_cart;
      case 'checkroom':
        return Icons.checkroom;
      case 'push_pin':
        return Icons.push_pin;
      case 'straighten':
        return Icons.straighten;
      case 'person':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }
} 