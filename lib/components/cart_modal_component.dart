import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../services/user_location_service.dart';
import 'location_drawer_component.dart';

class CartModalComponent {
  static const Color luxuryGold = Color(0xFFE8D26D);
  static const Color darkBackground = Color(0xFF1A1A1A);

  static void showCartModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => const _CartModalContent(),
    );
  }
}

class _CartModalContent extends StatefulWidget {
  const _CartModalContent();

  @override
  State<_CartModalContent> createState() => _CartModalContentState();
}

class _CartModalContentState extends State<_CartModalContent> {
  static const Color luxuryGold = Color(0xFFE8D26D);
  static const Color darkBackground = Color(0xFF1A1A1A);
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: darkBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            border: Border.all(
              color: luxuryGold.withOpacity(0.2),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, -4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: luxuryGold.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              _buildHeader(context),
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.isEmpty) {
                      return _buildEmptyCart();
                    }
                    return _buildCartContent(cartProvider, scrollController);
                  },
                ),
              ),
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  if (cartProvider.isEmpty) return const SizedBox.shrink();
                  return _buildBottomSection(context, cartProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      width: 36,
      height: 3,
      decoration: BoxDecoration(
        color: luxuryGold.withOpacity(0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: luxuryGold.withOpacity(0.2),
            width: 0.8,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Your basket',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isEmpty) {
                return Center(
                  child: Text(
                    'Empty basket',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }
              return Center(
                child: Text(
                  '${cartProvider.itemCount} ${cartProvider.itemCount == 1 ? 'item' : 'items'} • ${cartProvider.formatPrice(cartProvider.subtotal)}',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: luxuryGold.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  luxuryGold.withOpacity(0.15),
                  luxuryGold.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: luxuryGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 28,
              color: luxuryGold.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your basket is empty',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add some items to get started',
            style: GoogleFonts.lato(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartProvider cartProvider, ScrollController scrollController) {
    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = cartProvider.items[index];
                return _buildCartItem(item, cartProvider, index);
              },
              childCount: cartProvider.items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add padding above ALL item headings
          const SizedBox(height: 6),
          
          // Item name only (no delete button)
          Text(
            item.itemDescription,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          
          // Services list - NO remove buttons
          ...item.serviceDetails.asMap().entries.map((entry) {
            int serviceIndex = entry.key;
            ServiceDetails service = entry.value;
            return _buildServiceRow(
              service, 
              cartProvider, 
              serviceIndex,
              index,
              false, // Never show delete button
            );
          }).toList(),
          
          // Separator line (except for last item)
          if (index < cartProvider.items.length - 1) ...[
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: luxuryGold.withOpacity(0.15),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceRow(ServiceDetails service, CartProvider cartProvider, int serviceIndex, int itemIndex, bool showDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              service.service.name,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            cartProvider.formatPrice(service.totalPrice),
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: luxuryGold,
            ),
          ),
          if (showDelete) ...[
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => cartProvider.removeItem(itemIndex),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: luxuryGold.withOpacity(0.2),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Compact Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  cartProvider.formatPrice(cartProvider.subtotal),
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: luxuryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Manage Basket Button with Auth Check
            Consumer<AuthService>(
              builder: (context, authService, child) {
                final isLoggedIn = authService.isLoggedIn;
                return GestureDetector(
                  onTap: () async {
                    if (isLoggedIn) {
                      try {
                        // Store context before async operations
                        final navigatorContext = Navigator.of(context);
                        
                        // Close modal first
                        Navigator.of(context).pop();
                        
                        // Always get fresh location data from database
                        UserLocationService.clearCache();
                        final location = await UserLocationService.getLocation();
                        
                        print('DEBUG: Location check - City: ${location['city']}, Town: ${location['town']}');
                        
                        if (location['city'] != null && 
                            location['town'] != null && 
                            location['city']!.isNotEmpty && 
                            location['town']!.isNotEmpty) {
                          // Location already selected, go to basket
                          print('DEBUG: Location found, navigating to basket');
                          navigatorContext.pushNamed('/basket');
                        } else {
                          // Show location selection modal
                          print('DEBUG: No location found, showing location modal');
                          // For now, let's also provide a direct path to basket
                          navigatorContext.pushNamed('/basket');
                          // _showLocationModal(context);
                        }
                      } catch (e) {
                        print('DEBUG: Error getting location: $e');
                        // Fallback: navigate to basket
                        Navigator.of(context).pop();
                        await Future.delayed(const Duration(milliseconds: 100));
                        Navigator.of(context).pushNamed('/basket');
                      }
                    } else {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/login');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          luxuryGold,
                          luxuryGold.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: luxuryGold.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isLoggedIn ? 'Manage your basket' : 'Sign in to manage basket',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: darkBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => LocationDrawerComponent(
        onLocationSelected: () {
          // After location is selected, navigate to basket
          print('DEBUG: Location selected, navigating to basket');
          Navigator.of(context).pushNamed('/basket');
        },
      ),
    );
  }
} 