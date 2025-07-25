import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NextButtonComponent extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool enabled;
  final String label;
  final Color goldenColor;

  const NextButtonComponent({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.label = 'Next',
    this.goldenColor = const Color(0xFFE8D26D),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? [
                      goldenColor,
                      goldenColor.withOpacity(0.8),
                    ]
                  : [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? goldenColor.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: goldenColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: enabled ? Colors.black87 : Colors.white.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: enabled ? Colors.black87 : Colors.white.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 