import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionCardComponent extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color goldenColor;

  const OptionCardComponent({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.goldenColor = const Color(0xFFE8D26D),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        margin: const EdgeInsets.only(
          bottom: 10.0, // Reduced from 16.0
        ),
        padding: const EdgeInsets.all(14.0), // Reduced from 18.0
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(14.0), // Reduced from 16.0
          border: Border.all(
            color: goldenColor.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: goldenColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 0),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Enhanced icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12.0), // Reduced from 14.0
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    goldenColor.withOpacity(0.25),
                    goldenColor.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(8.0), // Reduced from 10.0
                border: Border.all(
                  color: goldenColor.withOpacity(0.4),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldenColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: goldenColor,
                size: 22.0, // Reduced from 26.0
              ),
            ),
            const SizedBox(width: 14.0), // Reduced from 18.0
            // Enhanced text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 15.0, // Reduced from 17.0
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                      height: 1.2, // Reduced from 1.3
                    ),
                  ),
                  const SizedBox(height: 2.0), // Reduced from 3.0
                  Text(
                    description,
                    style: GoogleFonts.lato(
                      fontSize: 12.0, // Reduced from 13.0
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 0.1,
                      height: 1.2, // Added height
                    ),
                    maxLines: 2, // Added maxLines
                    overflow: TextOverflow.ellipsis, // Added overflow
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            // Enhanced arrow with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(6.0), // Reduced from 8.0
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    goldenColor.withOpacity(0.2),
                    goldenColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(6.0), // Reduced from 8.0
                border: Border.all(
                  color: goldenColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: goldenColor,
                size: 16.0, // Reduced from 18.0
              ),
            ),
          ],
        ),
      ),
    );
  }
} 