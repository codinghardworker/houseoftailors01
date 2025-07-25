import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TabIndicatorComponent extends StatelessWidget {
  final List<TabItem> tabs;
  final int activeTabIndex;
  final Color luxuryGold;

  const TabIndicatorComponent({
    super.key,
    required this.tabs,
    required this.activeTabIndex,
    this.luxuryGold = const Color(0xFFE8D26D),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 4.0,
      ),
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          return Expanded(
            child: Container(
              margin: index > 0 
                ? const EdgeInsets.only(left: 1.0)
                : EdgeInsets.zero,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 6.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.0),
                  color: _getTabColor(index),
                  boxShadow: index == activeTabIndex ? [
                    BoxShadow(
                      color: luxuryGold.withOpacity(0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getTabIcon(index),
                      size: 12.0,
                      color: _getTabIconColor(index),
                    ),
                    const SizedBox(width: 3.0),
                    Flexible(
                      child: Text(
                        tabs[index].title,
                        style: GoogleFonts.lato(
                          fontSize: 10.0,
                          fontWeight: index == activeTabIndex 
                            ? FontWeight.w700 
                            : FontWeight.w600,
                          color: _getTabTextColor(index),
                          letterSpacing: 0.1,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getTabColor(int index) {
    if (index == activeTabIndex) {
      return luxuryGold;
    } else if (index < activeTabIndex) {
      return Colors.white.withOpacity(0.1);
    } else {
      return Colors.transparent;
    }
  }

  IconData _getTabIcon(int index) {
    if (index < activeTabIndex) {
      return Icons.check_circle;
    } else {
      return tabs[index].icon;
    }
  }

  Color _getTabIconColor(int index) {
    if (index == activeTabIndex) {
      return Colors.black87;
    } else if (index < activeTabIndex) {
      return luxuryGold;
    } else {
      return Colors.white.withOpacity(0.4);
    }
  }

  Color _getTabTextColor(int index) {
    if (index == activeTabIndex) {
      return Colors.black87;
    } else if (index < activeTabIndex) {
      return Colors.white.withOpacity(0.8);
    } else {
      return Colors.white.withOpacity(0.5);
    }
  }
}

class TabItem {
  final String title;
  final IconData icon;

  const TabItem({
    required this.title,
    required this.icon,
  });
} 