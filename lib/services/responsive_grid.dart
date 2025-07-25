import 'package:flutter/material.dart';
import 'dimensions.dart';

enum GridType {
  category,
  homeService,
  general,
}

class ResponsiveGridDelegate {
  static SliverGridDelegate getDelegate(BuildContext context, {GridType type = GridType.general}) {
    final crossAxisCount = getCrossAxisCount(context, type: type);
    
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: Dimensions.gridCrossAxisSpacing,
      mainAxisSpacing: Dimensions.gridMainAxisSpacing,
      childAspectRatio: _getAspectRatio(type),
    );
  }
  
  static int getCrossAxisCount(BuildContext context, {GridType type = GridType.general}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (type) {
      case GridType.category:
        return _getCategoryGridCount(screenWidth);
      case GridType.homeService:
        return Dimensions.homeServiceGridCrossAxisCount;
      case GridType.general:
      default:
        return _getGeneralGridCount(screenWidth);
    }
  }
  
  static int _getCategoryGridCount(double screenWidth) {
    if (screenWidth > 1400) {
      return Dimensions.categoryGridCrossAxisCountLargeDesktop; // 8 columns
    } else if (screenWidth > 1200) {
      return Dimensions.categoryGridCrossAxisCountDesktop; // 7 columns
    } else if (screenWidth > 900) {
      return Dimensions.categoryGridCrossAxisCountLargeTablet; // 6 columns
    } else if (screenWidth > 700) {
      return Dimensions.categoryGridCrossAxisCountTablet; // 5 columns
    } else if (screenWidth > 500) {
      return Dimensions.categoryGridCrossAxisCountLarge; // 4 columns
    } else {
      return Dimensions.categoryGridCrossAxisCountSmall; // 2 columns (not 3)
    }
  }
  
  static int _getGeneralGridCount(double screenWidth) {
    if (screenWidth > 1200) {
      return Dimensions.gridCrossAxisCountDesktop;
    } else if (screenWidth > 768) {
      return Dimensions.gridCrossAxisCountTablet;
    } else {
      return Dimensions.gridCrossAxisCount;
    }
  }
  
  static double _getAspectRatio(GridType type) {
    switch (type) {
      case GridType.category:
        return 0.75; // Slightly taller for category cards
      case GridType.homeService:
        return 1.2; // Wider for home service cards
      case GridType.general:
      default:
        return Dimensions.cardAspectRatio;
    }
  }
}