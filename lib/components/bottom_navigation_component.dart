import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';

class BottomNavigationComponent extends StatelessWidget {
  const BottomNavigationComponent({
    super.key,
  });

  static const Color luxuryGold = Color(0xFFE8D26D);

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
            border: Border(
              top: BorderSide(
                color: luxuryGold.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, -5),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: luxuryGold.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomNavItem(context, Icons.home_outlined, Icons.home, 'Home', navigationProvider.currentScreen == 'Home'),
                  _buildBottomNavItem(context, Icons.content_cut_outlined, Icons.content_cut, 'Tailor', navigationProvider.currentScreen == 'Tailor'),
                  _buildBottomNavItem(context, Icons.local_laundry_service_outlined, Icons.local_laundry_service, 'Dry Cleaning', navigationProvider.currentScreen == 'Dry Cleaning'),
                  _buildOrdersNavItem(context, navigationProvider.currentScreen == 'Orders'),
                  _buildBottomNavItem(context, Icons.person_outline, Icons.person, 'Profile', navigationProvider.currentScreen == 'Profile'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavItem(BuildContext context, IconData outlinedIcon, IconData filledIcon, String label, bool isSelected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
        navigationProvider.handleNavigation(context, label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isSelected ? filledIcon : outlinedIcon,
                    key: ValueKey<bool>(isSelected),
                    color: isSelected ? luxuryGold : Colors.white.withOpacity(0.7),
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: isSelected ? 10 : 9,
                color: isSelected ? luxuryGold : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersNavItem(BuildContext context, bool isSelected) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final orderCount = orderProvider.ongoingOrdersCount;
        
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
            navigationProvider.handleNavigation(context, 'Orders');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        isSelected ? Icons.receipt_long : Icons.receipt_long_outlined,
                        key: ValueKey<bool>(isSelected),
                        color: isSelected ? luxuryGold : Colors.white.withOpacity(0.7),
                        size: 26,
                      ),
                    ),
                    if (orderCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF1A1A1A),
                              width: 1,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            orderCount > 99 ? '99+' : orderCount.toString(),
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Orders',
                  style: GoogleFonts.lato(
                    fontSize: isSelected ? 10 : 9,
                    color: isSelected ? luxuryGold : Colors.white.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}