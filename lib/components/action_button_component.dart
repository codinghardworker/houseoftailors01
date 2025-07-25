import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButtonComponent extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final Color goldenColor;
  final bool enabled;
  final EdgeInsetsGeometry? margin;

  const ActionButtonComponent({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    required this.goldenColor,
    this.enabled = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.symmetric(
        vertical: 16.0,
      ),
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: 14.0,
          ),
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
                      Colors.grey.withOpacity(0.3),
                      Colors.grey.withOpacity(0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: enabled
                  ? goldenColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
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
              Icon(
                icon,
                size: 20.0,
                color: enabled ? Colors.black87 : Colors.grey.withOpacity(0.6),
              ),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: enabled ? Colors.black87 : Colors.grey.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 