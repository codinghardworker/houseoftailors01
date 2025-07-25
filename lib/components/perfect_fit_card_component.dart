import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PerfectFitCardComponent extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color goldenColor;
  final bool isPressed;
  final bool isCompact; // Add compact mode flag
  final String? priceText; // Add price text support

  const PerfectFitCardComponent({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.goldenColor = const Color(0xFFE8D26D),
    this.isPressed = false,
    this.isCompact = false, // Default to false for backward compatibility
    this.priceText, // Optional price text
  });

  @override
  State<PerfectFitCardComponent> createState() => _PerfectFitCardComponentState();
}

class _PerfectFitCardComponentState extends State<PerfectFitCardComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Add missing getters for screen dimensions and orientation
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;
  double get screenWidth => MediaQuery.of(context).size.width;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    _scaleController.forward();
  }

  void _handleTapUp() {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildHorizontalLayout(),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 6.0, // Reduced from 8.0
      ),
      padding: const EdgeInsets.all(
        14.0, // Reduced from 18.0
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isPressed
              ? [
                  widget.goldenColor.withOpacity(0.25),
                  widget.goldenColor.withOpacity(0.15),
                  widget.goldenColor.withOpacity(0.08),
                ]
              : [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(14.0), // Reduced from 16.0
        border: Border.all(
          color: widget.isPressed
              ? widget.goldenColor.withOpacity(0.6)
              : widget.goldenColor.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          if (widget.isPressed)
            BoxShadow(
              color: widget.goldenColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 0),
              spreadRadius: 0,
            ),
        ],
      ),
      child: _buildRowContent(),
    );
  }

  Widget _buildRowContent() {
    return Row(
      children: [
        // Icon container - using OptionCardComponent styling
        Container(
          padding: const EdgeInsets.all(12.0), // Reduced from 14.0
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.goldenColor.withOpacity(0.25),
                widget.goldenColor.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(8.0), // Reduced from 10.0
            border: Border.all(
              color: widget.goldenColor.withOpacity(0.4),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.goldenColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: 22.0, // Reduced from 26.0
            color: widget.goldenColor,
          ),
        ),
        const SizedBox(width: 14.0), // Reduced from 18.0
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 15.0, // Reduced from 17.0
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  height: 1.2, // Reduced from 1.3
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0), // Reduced from 6.0
              Text(
                widget.description,
                style: GoogleFonts.inter(
                  fontSize: 12.0, // Reduced from 13.0
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 0.1,
                  height: 1.2, // Reduced from 1.3
                ),
                maxLines: 2, // Reduced from 3
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.priceText != null) ...[
                const SizedBox(height: 4.0),
                Text(
                  widget.priceText!,
                  style: GoogleFonts.inter(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: widget.goldenColor,
                    letterSpacing: 0.1,
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
} 