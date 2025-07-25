class Dimensions {
  // Font sizes
  static const double titleFontSize = 22.0; // Reduced from 24.0
  static const double subtitleFontSize = 13.0; // Reduced from 14.0
  static const double cardTitleFontSize = 12.0; // Reduced from 13.0
  static const double cardSubtitleFontSize = 10.0; // Reduced from 11.0
  static const double buttonFontSize = 16.0;
  static const double headerTitleFontSize = 28.0;
  static const double headerSubtitleFontSize = 14.0;
  static const double errorFontSize = 18.0;
  static const double errorSubtitleFontSize = 14.0;

  // Padding and spacing
  static const double screenPadding = 14.0; // Reduced from 16.0
  static const double sectionSpacing = 20.0; // Reduced from 24.0
  static const double itemSpacing = 12.0; // Reduced from 16.0
  static const double smallSpacing = 6.0; // Reduced from 8.0
  static const double cardSpacing = 8.0; // Reduced from 12.0

  // Card dimensions
  static const double cardAspectRatio = 0.85;
  static const double cardPaddingHorizontal = 10.0;
  static const double cardPaddingVertical = 12.0;

  // Grid dimensions
  static const int gridCrossAxisCount = 2;
  static const int gridCrossAxisCountTablet = 3;
  static const int gridCrossAxisCountDesktop = 4;
  
  // Category grid dimensions (more dense for category cards)
  static const int categoryGridCrossAxisCountSmall = 2; // Small phones
  static const int categoryGridCrossAxisCountMedium = 3; // Regular phones
  static const int categoryGridCrossAxisCountLarge = 4; // Large phones/small tablets
  static const int categoryGridCrossAxisCountTablet = 5; // Tablets
  static const int categoryGridCrossAxisCountLargeTablet = 6; // Large tablets
  static const int categoryGridCrossAxisCountDesktop = 7; // Desktop
  static const int categoryGridCrossAxisCountLargeDesktop = 8; // Large desktop
  
  // Home service grid dimensions (like tailor/altered cards)
  static const int homeServiceGridCrossAxisCount = 2; // Always 2 for home services
  
  static const double gridCrossAxisSpacing = 12.0;
  static const double gridMainAxisSpacing = 12.0;

  // Input dimensions
  static const double inputMaxLines = 4.0;
  static const double inputMinLines = 2.0;

  // Icon sizes
  static const double largeIconSize = 48.0;
  static const double mediumIconSize = 32.0;
  static const double smallIconSize = 24.0;

  // Button dimensions
  static const double buttonHeight = 48.0;
  static const double buttonWidth = 200.0;
  static const double buttonRadius = 8.0;

  // Image dimensions
  static const double categoryImageSize = 120.0;
  static const double itemImageSize = 100.0;
  static const double serviceImageSize = 80.0;

  // Container dimensions
  static const double maxContainerWidth = 600.0;
  static const double minContainerHeight = 400.0;
} 