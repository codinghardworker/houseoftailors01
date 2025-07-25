import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceOptionButtonComponent extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPressed;
  final VoidCallback onTap;
  final Color goldenColor;

  const ServiceOptionButtonComponent({
    super.key,
    required this.label,
    required this.icon,
    required this.isPressed,
    required this.onTap,
    this.goldenColor = const Color(0xFFE8D26D),
  });

  @override
  Widget build(BuildContext context) {
    final bool showGoldenTouch = isPressed;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: showGoldenTouch ? goldenColor : goldenColor.withOpacity(0.2),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: showGoldenTouch
                ? [
                    goldenColor.withOpacity(0.08),
                    goldenColor.withOpacity(0.03),
                  ]
                : [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: showGoldenTouch
                    ? goldenColor.withOpacity(0.15)
                    : goldenColor.withOpacity(0.05),
                border: Border.all(
                  color: showGoldenTouch ? goldenColor : goldenColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: showGoldenTouch ? goldenColor : goldenColor.withOpacity(0.8),
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: showGoldenTouch ? goldenColor : Colors.white.withOpacity(0.9),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 