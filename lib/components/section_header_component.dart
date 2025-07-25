import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionHeaderComponent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? goldenText;
  final double? titleFontSize;
  final double? subtitleFontSize;
  final FontWeight? titleFontWeight;
  final FontWeight? subtitleFontWeight;
  final TextAlign? textAlign;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color goldenColor;
  final bool showDecorationLine;
  final double? decorationLineWidth;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment? crossAxisAlignment;

  const SectionHeaderComponent({
    super.key,
    required this.title,
    this.subtitle,
    this.goldenText,
    this.titleFontSize,
    this.subtitleFontSize,
    this.titleFontWeight,
    this.subtitleFontWeight,
    this.textAlign,
    this.titleColor,
    this.subtitleColor,
    this.goldenColor = const Color(0xFFE8D26D),
    this.showDecorationLine = true,
    this.decorationLineWidth,
    this.padding,
    this.crossAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we should show decoration line based on content
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final shouldShowLine = showDecorationLine && (hasSubtitle || subtitle == null);
    
    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
        children: [
          // Main title with optional golden text
          RichText(
            textAlign: textAlign ?? TextAlign.start,
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: titleFontSize ?? 28.0,
                    fontWeight: titleFontWeight ?? FontWeight.w400,
                    color: titleColor ?? Colors.white,
                    height: 1.1,
                  ),
                ),
                if (goldenText != null)
                  TextSpan(
                    text: goldenText!,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: titleFontSize ?? 28.0,
                      fontWeight: FontWeight.w600,
                      color: goldenColor,
                      height: 1.1,
                    ),
                  ),
              ],
            ),
          ),
          
          // Subtitle if provided and not empty
          if (hasSubtitle) ...[
            const SizedBox(height: 8.0),
            Text(
              subtitle!,
              textAlign: textAlign ?? TextAlign.start,
              style: GoogleFonts.lato(
                fontSize: subtitleFontSize ?? 14.0,
                color: subtitleColor ?? Colors.white.withOpacity(0.7),
                fontWeight: subtitleFontWeight ?? FontWeight.w400,
                height: 1.3,
              ),
            ),
          ],
          
          // Decorative line - only show when appropriate
          if (shouldShowLine) ...[
            SizedBox(height: hasSubtitle ? 15.0 : 12.0),
            Container(
              width: decorationLineWidth ?? 60,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    goldenColor,
                    goldenColor.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 