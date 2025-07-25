import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RepairOptionButtonComponent extends StatelessWidget {
  final String label;
  final String? price;
  final VoidCallback onTap;
  final Color goldenColor;

  const RepairOptionButtonComponent({
    super.key,
    required this.label,
    this.price,
    required this.onTap,
    this.goldenColor = const Color(0xFFE8D26D),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(
          bottom: 8.0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (price?.isNotEmpty ?? false) ...[
              Text(
                price!,
                style: GoogleFonts.lato(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: goldenColor,
                ),
              ),
              const SizedBox(width: 8.0),
            ],
            Icon(
              Icons.arrow_forward_ios,
              size: 14.0,
              color: Colors.white.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
} 