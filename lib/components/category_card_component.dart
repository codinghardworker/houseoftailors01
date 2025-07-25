import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/image_service.dart';

class CategoryCardComponent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String imageUrl;
  final IconData? fallbackIcon;
  final bool isPressed;
  final VoidCallback onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapCancel;
  final Animation<double>? scaleAnimation;
  final Color goldenColor;
  final double? borderRadius;
  final double? fontSize;
  final double? subtitleFontSize;
  final FontWeight? fontWeight;
  final int? maxLines;
  final EdgeInsetsGeometry? textPadding;
  final double? aspectRatio;
  final BoxFit? imageBoxFit;

  const CategoryCardComponent({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
    this.subtitle,
    this.fallbackIcon,
    this.isPressed = false,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.scaleAnimation,
    this.goldenColor = const Color(0xFFE8D26D),
    this.borderRadius,
    this.fontSize,
    this.subtitleFontSize,
    this.fontWeight,
    this.maxLines,
    this.textPadding,
    this.aspectRatio,
    this.imageBoxFit,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorderRadius = borderRadius ?? 20.0;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing based on screen width
    final responsiveFontSize = fontSize ?? _getResponsiveFontSize(screenWidth);
    final responsiveSubtitleFontSize = subtitleFontSize ?? _getResponsiveSubtitleFontSize(screenWidth);
    final responsivePadding = textPadding ?? _getResponsivePadding(screenWidth);
    
    return GestureDetector(
      onTapDown: onTapDown != null ? (_) => onTapDown!() : null,
      onTapUp: onTapUp != null ? (_) => onTapUp!() : null,
      onTapCancel: onTapCancel,
      onTap: onTap,
      child: AnimatedBuilder(
        animation: scaleAnimation ?? AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          return Transform.scale(
            scale: isPressed && scaleAnimation != null ? scaleAnimation!.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardBorderRadius),
                border: Border.all(
                  color: isPressed 
                    ? goldenColor.withOpacity(0.4) 
                    : goldenColor.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  if (isPressed)
                    BoxShadow(
                      color: goldenColor.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 0),
                      spreadRadius: 1,
                    ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isPressed
                      ? [
                          goldenColor.withOpacity(0.06),
                          Colors.white.withOpacity(0.03),
                        ]
                      : [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.03),
                        ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardBorderRadius),
                child: Column(
                  children: [
                    // Image Section
                    Expanded(
                      flex: 4,
                      child: _buildImageSection(context, cardBorderRadius),
                    ),
                    // Text Section
                    _buildTextSection(context, cardBorderRadius, responsiveFontSize, responsiveSubtitleFontSize, responsivePadding),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _getResponsiveFontSize(double screenWidth) {
    if (screenWidth > 1400) return 11; // Large desktop
    if (screenWidth > 1200) return 10; // Desktop
    if (screenWidth > 900) return 10;  // Large tablet
    if (screenWidth > 700) return 11;  // Tablet
    if (screenWidth > 500) return 12;  // Large phone
    if (screenWidth > 380) return 12;  // Medium phone
    return 13; // Small phone
  }

  double _getResponsiveSubtitleFontSize(double screenWidth) {
    if (screenWidth > 1400) return 8;  // Large desktop
    if (screenWidth > 1200) return 8;  // Desktop
    if (screenWidth > 900) return 9;   // Large tablet
    if (screenWidth > 700) return 9;   // Tablet
    if (screenWidth > 500) return 10;  // Large phone
    if (screenWidth > 380) return 10;  // Medium phone
    return 10; // Small phone
  }

  EdgeInsetsGeometry _getResponsivePadding(double screenWidth) {
    if (screenWidth > 1400) return const EdgeInsets.symmetric(horizontal: 8, vertical: 8);   // Large desktop
    if (screenWidth > 1200) return const EdgeInsets.symmetric(horizontal: 8, vertical: 10);  // Desktop
    if (screenWidth > 900) return const EdgeInsets.symmetric(horizontal: 10, vertical: 10);  // Large tablet
    if (screenWidth > 700) return const EdgeInsets.symmetric(horizontal: 10, vertical: 12);  // Tablet
    if (screenWidth > 500) return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);  // Large phone
    if (screenWidth > 380) return const EdgeInsets.symmetric(horizontal: 12, vertical: 14);  // Medium phone
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 16); // Small phone
  }

  Widget _buildImageSection(BuildContext context, double cardBorderRadius) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(cardBorderRadius),
              topRight: Radius.circular(cardBorderRadius),
            ),
            color: Colors.white.withOpacity(0.05),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(cardBorderRadius),
              topRight: Radius.circular(cardBorderRadius),
            ),
            child: ImageService.buildImage(
              imageUrl: imageUrl,
              fallbackIcon: fallbackIcon ?? Icons.image_not_supported,
              fit: imageBoxFit ?? BoxFit.cover,
              iconColor: goldenColor.withOpacity(0.6),
              iconSize: 36,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(cardBorderRadius),
                topRight: Radius.circular(cardBorderRadius),
              ),
            ),
          ),
        ),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(cardBorderRadius),
              topRight: Radius.circular(cardBorderRadius),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextSection(BuildContext context, double cardBorderRadius, double fontSize, double subtitleFontSize, EdgeInsetsGeometry padding) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isPressed 
            ? goldenColor.withOpacity(0.08)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(cardBorderRadius),
          bottomRight: Radius.circular(cardBorderRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: subtitle != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: fontSize,
              fontWeight: fontWeight ?? FontWeight.w700,
              color: isPressed ? goldenColor : Colors.white,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: maxLines ?? 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.lato(
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w700,
                color: goldenColor,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
} 