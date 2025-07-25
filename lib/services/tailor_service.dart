import 'package:flutter/material.dart';
import '../components/tab_indicator_component.dart';

class TailorService {
  static const Color luxuryGold = Color(0xFFE8D26D);

  // Tab configuration for tailor screens
  static List<TabItem> getTailorTabs() {
    return [
      const TabItem(
        title: 'Your item',
        icon: Icons.check_circle,
      ),
      const TabItem(
        title: 'Your service',
        icon: Icons.design_services,
      ),
      const TabItem(
        title: 'Add another',
        icon: Icons.add_circle_outline,
      ),
    ];
  }

  // Category data for garment selection
  static List<CategoryItem> getCategories() {
    return [
      CategoryItem(
        name: 'Hoodie/ sweatshirt',
        icon: Icons.checkroom,
        image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400&h=400&fit=crop&crop=center',
      ),
      CategoryItem(
        name: 'Skirts / Shorts',
        icon: Icons.woman,
        image: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=400&fit=crop&crop=center',
      ),
      CategoryItem(
        name: 'Suiting',
        icon: Icons.business_center,
        image: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400&h=400&fit=crop&crop=center',
      ),
      CategoryItem(
        name: 'Dresses / Jumpsuits',
        icon: Icons.woman_2,
        image: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&h=400&fit=crop&crop=center',
      ),
      CategoryItem(
        name: 'Coats / Jackets',
        icon: Icons.outdoor_grill,
        image: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400&h=400&fit=crop&crop=center',
      ),
      CategoryItem(
        name: 'Knitwear',
        icon: Icons.style,
        image: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400&h=400&fit=crop&crop=center',
      ),
      CategoryItem(
        name: 'Trousers / Jeans',
        icon: Icons.person,
        image: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400&h=400&fit=crop&crop=center',
      ),
      CategoryItem(
        name: 'Tops',
        icon: Icons.checkroom_outlined,
        image: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop&crop=center',
      ),
      CategoryItem(
        name: 'Jumpers',
        icon: Icons.style_outlined,
        image: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400&h=400&fit=crop&crop=center',
      ),
    ];
  }

  // Header content for different screens
  static HeaderContent getTailorScreenHeader() {
    return HeaderContent(
      title: 'Choose your ',
      goldenText: 'garment',
      subtitle: 'Select the category that best fits your item for professional tailoring services.',
    );
  }

  static HeaderContent getItemSelectionHeader() {
    return HeaderContent(
      title: 'Select your item that needs ',
      goldenText: 'altering or repairing.',
      subtitle: 'Start with just one item. Don\'t worry, you can add another item later on.',
    );
  }

  static HeaderContent getProductDescriptionHeader() {
    return HeaderContent(
      title: 'Describe your item ',
      goldenText: 'for us.',
      subtitle: 'This is so we can identify your item once it arrives in our studio.',
    );
  }

  static HeaderContent getServiceSelectionHeader(String selectedItem) {
    return HeaderContent(
      title: 'Would you like your ${selectedItem.toLowerCase()} ',
      goldenText: 'repaired or altered?',
      subtitle: 'Need both? Choose one and we\'ll add the other one later.',
    );
  }

  // Product items data for different categories
  static Map<String, List<ProductItem>> getCategoryProducts() {
    return {
      'Hoodie/ sweatshirt': [
        ProductItem(
          name: 'Classic Sweatshirt',
          image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400&h=400&fit=crop&crop=center',
          description: 'Comfortable cotton blend sweatshirt',
        ),
        ProductItem(
          name: 'Knitted Jumper',
          image: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400&h=400&fit=crop&crop=center',
          description: 'Warm knitted pullover',
        ),
        ProductItem(
          name: 'Casual Hoodie',
          image: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=400&fit=crop&crop=center',
          description: 'Relaxed fit hoodie with drawstring',
        ),
      ],
      'Suiting': [
        ProductItem(
          name: 'Business Suit',
          image: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400&h=400&fit=crop&crop=center',
          description: 'Professional tailored suit',
        ),
        ProductItem(
          name: 'Formal Blazer',
          image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=center',
          description: 'Classic business blazer',
        ),
        ProductItem(
          name: 'Dress Shirt',
          image: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&h=400&fit=crop&crop=center',
          description: 'Crisp formal dress shirt',
        ),
      ],
    };
  }

  static List<ProductItem> getDefaultProducts() {
    return [
      ProductItem(
        name: 'Classic Item',
        image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400&h=400&fit=crop&crop=center',
        description: 'Quality garment for tailoring',
      ),
      ProductItem(
        name: 'Premium Item',
        image: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400&h=400&fit=crop&crop=center',
        description: 'High-quality clothing item',
      ),
      ProductItem(
        name: 'Designer Item',
        image: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop&crop=center',
        description: 'Stylish designer piece',
      ),
    ];
  }

  static List<ProductItem> getProductsForCategory(String category) {
    final products = getCategoryProducts();
    return products[category] ?? getDefaultProducts();
  }

  // Tab configurations for item selection
  static List<TabItem> getItemSelectionTabs() {
    return [
      const TabItem(
        title: 'Your item',
        icon: Icons.check_circle,
      ),
      const TabItem(
        title: 'Your service',
        icon: Icons.design_services,
      ),
      const TabItem(
        title: 'Add another',
        icon: Icons.add_circle_outline,
      ),
    ];
  }

  // Navigation logic
  static void navigateToItemSelection(BuildContext context, String category) {
    // This would be implemented based on your routing setup
    print('Navigating to item selection for category: $category');
  }

  // Animation configurations
  static Duration get cardAnimationDuration => const Duration(milliseconds: 200);
  static Duration get fadeAnimationDuration => const Duration(milliseconds: 800);
  
  static double getCardScale({required bool isPressed}) {
    return isPressed ? 0.96 : 1.0;
  }

  // Grid configuration
  static int getCategoryGridCrossAxisCount() => 2;
  static double getCategoryGridCrossAxisSpacing() => 14;
  static double getCategoryGridMainAxisSpacing() => 14;
  static double getCategoryGridChildAspectRatio() => 0.82;

  // Responsive sizing helpers
  static double getTitleFontSize(BuildContext context) {
    return 32.0;
  }

  static double getSubtitleFontSize(BuildContext context) {
    return 14.0;
  }

  static double getCardFontSize(BuildContext context) {
    return 13.0;
  }

  static List<Map<String, dynamic>> getRepairOptions() {
    return [
      {
        'name': 'Zip replacement',
        'price': 'From £20.00',
        'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&crop=center',
        'icon': Icons.construction_outlined,
      },
      {
        'name': 'Fix stitching',
        'price': 'From £15.00',
        'image': 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&h=300&fit=crop&crop=center',
        'icon': Icons.healing_outlined,
      },
      {
        'name': 'Mend rips/holes',
        'price': 'From £15.00',
        'image': 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400&h=300&fit=crop&crop=center',
        'icon': Icons.handyman_outlined,
      },
      {
        'name': 'Replace ribbing',
        'price': 'From £25.00',
        'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&crop=center',
        'icon': Icons.pattern_outlined,
      },
    ];
  }

  static HeaderContent getRepairSelectionHeader(String selectedItem) {
    return HeaderContent(
      title: 'What repair does your ${selectedItem.toLowerCase()} ',
      goldenText: 'need?',
      subtitle: 'We know that repairs can be unique. If you\'re unsure on what to select, use the help button in the left hand corner to ask our team.',
    );
  }

  static List<Map<String, dynamic>> getZipRepairOptions() {
    return [
      {
        'name': 'Main zip',
        'price': '+ £10.00',
      },
      {
        'name': 'Small zip',
        'price': null, // No price for small zip
      },
    ];
  }

  static HeaderContent getZipRepairOptionHeader(String selectedItem) {
    return HeaderContent(
      title: 'Would you like the main zip replaced or a ',
      goldenText: 'smaller zip replaced?',
      subtitle: '',
    );
  }

  static HeaderContent getFixStitchingLocationHeader() {
    return const HeaderContent(
      title: 'Where do you need your ',
      goldenText: 'repair?',
      subtitle: 'Please describe the location of your repair.',
    );
  }

  // Mend rips/holes flow data and headers
  static HeaderContent getMendRipsLocationHeader() {
    return const HeaderContent(
      title: 'Where do you need your ',
      goldenText: 'repair?',
      subtitle: 'Please describe the location of your repair.',
    );
  }

  static HeaderContent getMendRipsQuantityHeader() {
    return const HeaderContent(
      title: 'How many rips/ holes do you need ',
      goldenText: 'fixing?',
      subtitle: '',
    );
  }

  static List<Map<String, dynamic>> getMendRipsQuantityOptions() {
    return [
      {
        'name': '1 hole / rip',
        'price': null,
      },
      {
        'name': '2-3 holes / rips',
        'price': '+ £10.00',
      },
      {
        'name': '4-6 holes / rips',
        'price': '+ £20.00',
      },
      {
        'name': '7-9 holes / rips',
        'price': '+ £30.00',
      },
      {
        'name': '10 + holes/ rips',
        'price': '+ £45.00',
      },
    ];
  }

  static HeaderContent getMendRipsSizeHeader() {
    return const HeaderContent(
      title: 'What is the size of your ',
      goldenText: 'hole(s)/ rip(s)',
      subtitle: 'Please give the average size of the rips when there are varying sizes. Please measure from the widest part.',
    );
  }

  static List<Map<String, dynamic>> getMendRipsSizeOptions() {
    return [
      {
        'name': '0- 1cm',
        'price': null,
      },
      {
        'name': '1.5cm - 3cm',
        'price': '+ £5.00',
      },
      {
        'name': '3.5cm- 5cm',
        'price': '+ £10.00',
      },
      {
        'name': '5.5cm-7cm',
        'price': '+ £15.00',
      },
      {
        'name': '7cm +',
        'price': '+ £20.00',
      },
    ];
  }

  static HeaderContent getMendRipsMethodHeader(String selectedItem) {
    return HeaderContent(
      title: 'What does your ${selectedItem.toLowerCase()} ',
      goldenText: 'need?',
      subtitle: 'We know that alterations and repairs can be unique. If you\'re unsure on what to select, use the help button in the left hand corner to ask our team.',
    );
  }

  static List<Map<String, dynamic>> getMendRipsMethodOptions() {
    return [
      {
        'name': 'Visible darning',
        'price': '£35.00',
        'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&crop=center',
      },
      {
        'name': 'Patch',
        'price': '£35.00',
        'image': 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&h=300&fit=crop&crop=center',
      },
      {
        'name': 'Create discrete seam',
        'price': '£30.00',
        'image': 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400&h=300&fit=crop&crop=center',
      },
      {
        'name': 'Fix rip along seam',
        'price': '£30.00',
        'image': 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400&h=400&fit=crop&crop=center',
      },
    ];
  }

  static HeaderContent getMendRipsColorHeader() {
    return const HeaderContent(
      title: 'Would you prefer a close colour match or a contrast? Please specify ',
      goldenText: '\'close match\' or your desired contrast colour.',
      subtitle: 'If you choose close colour match we will select the closest match from our selection of over 2,000 yarns. We cannot guarantee an exact match.',
    );
  }

  static String getMendRipsColorPlaceholder() {
    return 'Your response...';
  }

  static List<Map<String, dynamic>> getZipOptions() {
    return [
      {
        'name': 'Source bespoke zip',
        'price': '£40.00',
        'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop',
      },
      {
        'name': 'Zip colour - Standard Black',
        'price': '£30.00',
        'image': 'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=400&h=300&fit=crop',
      },
      {
        'name': 'Zip colour - Standard Navy',
        'price': '£30.00',
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=300&fit=crop',
      },
      {
        'name': 'Zip colour - Standard Grey',
        'price': '£30.00',
        'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=300&fit=crop',
      },
      {
        'name': 'Zip colour - Standard Red',
        'price': '£20.00',
        'image': 'https://images.unsplash.com/photo-1529720317453-c8da503f2051?w=400&h=300&fit=crop',
      },
      {
        'name': 'Zip colour - Standard Green',
        'price': '£20.00',
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=300&fit=crop',
      },
    ];
  }

  static HeaderContent getZipOptionsHeader(String selectedItem) {
    return HeaderContent(
      title: 'What does your ',
      goldenText: '${selectedItem.toLowerCase()} need?',
      subtitle: 'We know that alterations and repairs can be unique. If you\'re unsure on what to select, use the help button in the left hand corner to ask our team.',
    );
  }

  static HeaderContent getNotesScreenHeader() {
    return const HeaderContent(
      title: 'Is there anything else we should ',
      goldenText: 'know?',
      subtitle: 'Please leave any other notes which you\'d like passed on to our tailors.',
    );
  }

  static String getNotesInputPlaceholder() {
    return 'Notes to our tailors...';
  }

  static HeaderContent getAddAnotherScreenHeader() {
    return const HeaderContent(
      title: 'What else should we take ',
      goldenText: 'care?',
      subtitle: 'We all have a pile in the back of our wardrobe that we don\'t wear. Now\'s the time to show them some love and care.',
    );
  }

  static List<AddAnotherOption> getAddAnotherOptions() {
    return [
      const AddAnotherOption(
        title: 'Add more services to this item',
        description: 'Continue with your current item',
        icon: 'design_services',
        action: 'add_more_services',
      ),
      const AddAnotherOption(
        title: 'Repair or alter a new item',
        description: 'Start fresh with a new garment',
        icon: 'add_shopping_cart',
        action: 'repair_new_item',
      ),
    ];
  }

  // Replace ribbing flow data and headers
  static HeaderContent getReplaceRibbingLocationHeader() {
    return const HeaderContent(
      title: 'Where do you need your ',
      goldenText: 'repair?',
      subtitle: 'Please describe the location of your repair.',
    );
  }

  static HeaderContent getReplaceRibbingOptionsHeader(String selectedItem) {
    return HeaderContent(
      title: 'What does your ${selectedItem.toLowerCase()} ',
      goldenText: 'need?',
      subtitle: 'We know that alterations and repairs can be unique. If you\'re unsure on what to select, use the help button in the left hand corner to ask our team.',
    );
  }

  static List<Map<String, dynamic>> getReplaceRibbingOptions() {
    return [
      {
        'name': 'Replace ribbing of one sleeve',
        'price': '£25.00',
        'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&crop=center',
      },
      {
        'name': 'Replace ribbing of both sleeves',
        'price': '£50.00',
        'image': 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&h=300&fit=crop&crop=center',
      },
      {
        'name': 'Replace ribbing around neckline',
        'price': '£45.00',
        'image': 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400&h=300&fit=crop&crop=center',
      },
      {
        'name': 'Replace ribbing waistband',
        'price': '£55.00',
        'image': 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400&h=400&fit=crop&crop=center',
      },
    ];
  }

  static HeaderContent getReplaceRibbingQuestionHeader() {
    return const HeaderContent(
      title: 'Any specific requirements for the ',
      goldenText: 'ribbing replacement?',
      subtitle: 'Please let us know about color preferences, material specifications, or any other details.',
    );
  }

  static String getReplaceRibbingQuestionPlaceholder() {
    return 'Your requirements...';
  }

  // Alteration flow data and headers
  static List<Map<String, dynamic>> getAlterationOptions() {
    return [
      {
        'name': 'Shorten Sleeves',
        'price': 'From £30.00',
        'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&crop=center',
        'icon': Icons.content_cut_outlined,
      },
      {
        'name': 'Crop',
        'price': 'From £30.00',
        'image': 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&h=300&fit=crop&crop=center',
        'icon': Icons.crop_outlined,
      },
      {
        'name': 'Take in from Sides',
        'price': 'From £35.00',
        'image': 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400&h=300&fit=crop&crop=center',
        'icon': Icons.compress_outlined,
      },
      {
        'name': 'Up-size',
        'price': 'From £30.00',
        'image': 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400&h=400&fit=crop&crop=center',
        'icon': Icons.expand_outlined,
      },
    ];
  }

  static HeaderContent getAlterationSelectionHeader(String selectedItem) {
    return HeaderContent(
      title: 'What alteration does your ${selectedItem.toLowerCase()} ',
      goldenText: 'need?',
      subtitle: 'We know that alterations can be unique. If you\'re unsure on what to select, use the help button in the left hand corner to ask our team.',
    );
  }

  static HeaderContent getPerfectFitHeader() {
    return const HeaderContent(
      title: 'How would you like to fit your ',
      goldenText: 'item?',
      subtitle: 'Help us ensure we get you the perfect fit by selecting one of the options below.',
    );
  }

  static List<Map<String, dynamic>> getPerfectFitOptions() {
    return [
      {
        'title': 'Match to another item',
        'description': 'Best for simple alterations and if you don\'t have any fitting materials. You will need a similar item that fits you correctly.',
        'icon': 'checkroom',
      },
      {
        'title': 'Pin your item',
        'description': 'Best for fitting if you have someone to help you. You will need a few sewing pins, safety pins or clips.',
        'icon': 'push_pin',
      },
      {
        'title': 'Measure your item',
        'description': 'Best for getting the most accurate fit and and if you are fitting your item alone. You will need a measuring tape.',
        'icon': 'straighten',
      },
      {
        'title': 'In-person fitting',
        'description': 'Best for complex alterations and professional advice. Come along to our space at Selfridges London to get fitted in-person by a SOJO tailor.',
        'icon': 'person',
      },
    ];
  }

  static HeaderContent getMatchingItemHeader() {
    return const HeaderContent(
      title: 'Describe your matching item ',
      goldenText: 'for us.',
      subtitle: 'This is so we can differentiate your items.',
    );
  }

  static String getMatchingItemPlaceholder() {
    return 'Colour, pattern, material';
  }

  static HeaderContent getMeasurementsHeader() {
    return const HeaderContent(
      title: 'Describe your measurements ',
      goldenText: 'for us.',
      subtitle: 'For example, take in by 1 inch or waist measurement of 34 inches.',
    );
  }

  static String getMeasurementsPlaceholder() {
    return 'Your measurements...';
  }
}

// Data models
class CategoryItem {
  final String name;
  final IconData icon;
  final String image;

  CategoryItem({
    required this.name,
    required this.icon,
    required this.image,
  });
}

class ProductItem {
  final String name;
  final String image;
  final String description;

  ProductItem({
    required this.name,
    required this.image,
    required this.description,
  });
}

class HeaderContent {
  final String title;
  final String goldenText;
  final String subtitle;

  const HeaderContent({
    required this.title,
    required this.goldenText,
    this.subtitle = '',
  });
}

class AddAnotherOption {
  final String title;
  final String description;
  final String icon;
  final String action;

  const AddAnotherOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.action,
  });
} 