import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/cart_provider.dart';
import 'cart_modal_component.dart';

class AppBarComponent extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppBarComponent({
    super.key,
    this.showBackButton = false,
    this.onBackPressed,
  });

  static const Color luxuryGold = Color(0xFFE8D26D);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showBackButton)
          Row(
            children: [
              _buildBackButton(context),
              Container(
                padding: const EdgeInsets.only(bottom: 1),
                child: SizedBox(
                  width: 190,
                  height: 95,
                  child: Image.asset(
                    'assets/images/logo-main.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.business, color: luxuryGold, size: 30),
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            child: SizedBox(
              width: 190,
              height: 95,
              child: Image.asset(
                'assets/images/logo-main.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.business, color: luxuryGold, size: 40),
              ),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCartIcon(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: onBackPressed ?? () {
        final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
        navigationProvider.handleNavigation(context, 'Home');
      },
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCartIcon() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItemCount = cartProvider.itemCount;
    
        return GestureDetector(
          onTap: () => CartModalComponent.showCartModal(context),
          child: SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          Center(child: Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24)),
          if (cartItemCount > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: luxuryGold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A1A1A),
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
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