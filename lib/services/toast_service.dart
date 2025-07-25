import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToastService {
  static const Color luxuryGold = Color(0xFFE8D26D);
  static const Color darkBackground = Color(0xFF1A1A1A);
  
  static void showSuccess(BuildContext context, String message) {
    _showCustomToast(
      context,
      message,
      Icons.check_circle,
      luxuryGold,
      Colors.green.shade800,
    );
  }
  
  static void showError(BuildContext context, String message) {
    _showCustomToast(
      context,
      message,
      Icons.error,
      Colors.red.shade300,
      Colors.red.shade800,
    );
  }
  
  static void showInfo(BuildContext context, String message) {
    _showCustomToast(
      context,
      message,
      Icons.info,
      Colors.blue.shade300,
      Colors.blue.shade800,
    );
  }
  
  static void _showCustomToast(
    BuildContext context,
    String message,
    IconData icon,
    Color iconColor,
    Color backgroundColor,
  ) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _CustomToast(
        message: message,
        icon: icon,
        iconColor: iconColor,
        backgroundColor: backgroundColor,
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(milliseconds: 3000), () {
      overlayEntry.remove();
    });
  }
}

class _CustomToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  
  const _CustomToast({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
  
  @override
  State<_CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<_CustomToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -50 * (1 - _animation.value)),
            child: Opacity(
              opacity: _animation.value,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.iconColor.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}