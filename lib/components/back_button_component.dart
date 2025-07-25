import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BackButtonComponent extends StatelessWidget {
  final VoidCallback? onTap;
  final Color goldenColor;

  const BackButtonComponent({
    super.key,
    this.onTap,
    this.goldenColor = const Color(0xFFE8D26D),
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _handleTap(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: goldenColor.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: goldenColor.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(1.6),
                    decoration: BoxDecoration(
                      color: goldenColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: goldenColor,
                      size: 12.0,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Back',
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 