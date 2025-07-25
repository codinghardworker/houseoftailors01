import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriceComponent extends StatelessWidget {
  final String label;
  final String price;
  final Color goldenColor;
  final double? fontSize;
  final double? labelFontSize;
  final FontWeight? labelFontWeight;
  final FontWeight? priceFontWeight;
  final EdgeInsetsGeometry? margin;

  const PriceComponent({
    super.key,
    required this.label,
    required this.price,
    this.goldenColor = const Color(0xFFE8D26D),
    this.fontSize,
    this.labelFontSize,
    this.labelFontWeight,
    this.priceFontWeight,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: labelFontSize ?? 16.0,
              fontWeight: labelFontWeight ?? FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            price,
            style: GoogleFonts.lato(
              fontSize: fontSize ?? 16.0,
              fontWeight: priceFontWeight ?? FontWeight.w700,
              color: goldenColor,
            ),
          ),
        ],
      ),
    );
  }
} 