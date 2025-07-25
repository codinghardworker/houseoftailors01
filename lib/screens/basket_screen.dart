import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/app_bar_component.dart';
import '../components/bottom_navigation_component.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/loyalty_provider.dart';
import '../config/stripe_config.dart';
import '../services/stripe_service.dart';
import '../services/order_service.dart';
import '../services/toast_service.dart';

class BasketScreen extends StatefulWidget {
  const BasketScreen({super.key});

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> with TickerProviderStateMixin {
  static const luxuryGold = Color(0xFFE8D26D);
  static const darkBackground = Color(0xFF1A1A1A);
  final TextEditingController _discountController = TextEditingController();
  final Set<String> _expandedServices = {};
  AnimationController? _bottomSheetController;
  Animation<double>? _bottomSheetAnimation;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bottomSheetAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bottomSheetController!,
      curve: Curves.easeInOut,
    ));
    _initializeStripe();
    _checkLoyaltyDiscount();
  }

  Future<void> _initializeStripe() async {
    try {
      await StripeConfig.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('Stripe initialization failed: $e');
      }
    }
  }

  Future<void> _checkLoyaltyDiscount() async {
    try {
      final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      if (loyaltyProvider.isEligibleForFreeOrder) {
        cartProvider.applyLoyaltyDiscount(5000.0); // £50 in pence
      } else {
        cartProvider.clearLoyaltyDiscount();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking loyalty discount: $e');
      }
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _bottomSheetController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Fixed header section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppBarComponent(),
                      _buildTitle(),
                      Container(
                        height: 1,
                        color: luxuryGold.withOpacity(0.2),
                      ),
                    ],
                  ),
                ),
                // Scrollable cards section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 70), // Space for bottom drawer
                    child: _buildBasketItems(),
                  ),
                ),
              ],
            ),
            // Bottom drawer
            _buildBottomDrawer(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationComponent(),
    );
  }

  Widget _buildTitle() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Your ',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: 'basket',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: luxuryGold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasketItems() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.items.isEmpty) {
          return Center(
            child: Text(
              'Your basket is empty.',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              children: cartProvider.items.asMap().entries.map((entry) {
                int index = entry.key;
                CartItem item = entry.value;
                return _buildCartItem(item, cartProvider, index);
              }).toList(),
            ),
          ),
        );
      },
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
          
          // Services list - ALL services get remove buttons
          ...item.serviceDetails.asMap().entries.map((entry) {
            int serviceIndex = entry.key;
            ServiceDetails service = entry.value;
            return _buildServiceRow(
              service, 
              cartProvider, 
              serviceIndex,
              index,
              true, // Always show delete button for ALL services
            );
          }).toList(),
          
          const SizedBox(height: 12),
          
          // Add another service button for this item
          GestureDetector(
            onTap: () {
              // Navigate to index 3 in tailor screen for adding more services to this item
              Navigator.pushNamed(context, '/tailor', arguments: {
                'index': 3,
                'categoryId': item.itemCategory.id,
                'categoryName': item.itemCategory.name,
                'itemId': item.item.id,
                'itemName': item.item.name,
                'description': item.itemDescription,
                'fromAddMoreServices': true,
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: luxuryGold,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add another service to this item',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: darkBackground,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.add,
                    size: 16,
                    color: darkBackground,
                  ),
                ],
              ),
            ),
          ),
          
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
    final serviceKey = '${itemIndex}_${service.service.id}';
    final isExpanded = _expandedServices.contains(serviceKey);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.service.name,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // Debug: Always check notes regardless of empty status
                    () {
                      print('BASKET DEBUG - Service: ${service.service.name}, Notes: "${service.tailorNotes}", IsEmpty: ${service.tailorNotes.isEmpty}');
                      return const SizedBox.shrink();
                    }(),
                  ],
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
                  onTap: () => cartProvider.removeService(itemIndex, serviceIndex),
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
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedServices.remove(serviceKey);
                } else {
                  _expandedServices.add(serviceKey);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                isExpanded ? 'Hide service info' : 'See service info',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          if (isExpanded) _buildServiceDetails(service, cartProvider),
        ],
      ),
    );
  }

  Widget _buildServiceDetails(ServiceDetails service, CartProvider cartProvider) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: luxuryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items with prices shown first
          _buildDetailRow('Base price:', cartProvider.formatPrice(service.basePrice)),
          
          // Pickup cost if available
          if (service.deliveryMethod == 'pickup' && service.pickupCost != null && service.pickupCost! > 0)
            _buildDetailRow('Pickup Cost:', '+ £${service.pickupCost!.toStringAsFixed(2)}'),
          
          // Question answers with price modifiers
          ...service.questionAnswerModifiers.where((qa) => !qa.isTextInput || qa.priceModifier > 0).map((qa) {
            String answer = qa.isTextInput && qa.textResponse != null && qa.textResponse!.isNotEmpty 
              ? qa.textResponse! 
              : qa.answer;
            
            // Debug print to see what's being displayed
            print('BASKET DEBUG - Question: "${qa.question}", Answer: "$answer"');
            
            return _buildDetailRow(
              '${qa.question} - $answer', 
              qa.priceModifier > 0 ? '+ ${cartProvider.formatPrice(qa.priceModifier)}' : ''
            );
          }).toList(),
          
          // Subservice details if present
          if (service.subserviceDetails != null) ...[
            _buildDetailRow(
              service.subserviceDetails!.subservice.name, 
              '+ ${cartProvider.formatPrice(service.subserviceDetails!.subservice.priceModifier)}'
            ),
            ...service.subserviceDetails!.questionAnswerModifiers.where((qa) => !qa.isTextInput || qa.priceModifier > 0).map((qa) {
              String answer = qa.isTextInput && qa.textResponse != null && qa.textResponse!.isNotEmpty 
                ? qa.textResponse! 
                : qa.answer;
              
              // Debug print to see what's being displayed for subservice
              print('BASKET DEBUG - Subservice Question: "${qa.question}", Answer: "$answer"');
              
              return _buildDetailRow(
                '${qa.question} - $answer', 
                qa.priceModifier > 0 ? '+ ${cartProvider.formatPrice(qa.priceModifier)}' : ''
              );
            }).toList(),
          ],
          
          // Items without prices shown after
          // Delivery method and details
          if (service.deliveryMethod != null)
            _buildDetailRow('Delivery Method:', service.deliveryMethod == 'pickup' ? 'Pickup Service' : 'Post Delivery'),
          
          // Pickup time and date
          if (service.deliveryMethod == 'pickup' && service.pickupTime != null && service.pickupDate != null) ...[
            _buildDetailRow('Pickup Time:', service.pickupTime!),
            _buildDetailRow('Pickup Date:', _formatPickupDate(service.pickupDate!)),
          ],
          
          // Text-based questions (like question 3) displayed separately
          ...service.questionAnswerModifiers.where((qa) => qa.isTextInput && qa.textResponse != null && qa.textResponse!.isNotEmpty).map((qa) => 
            _buildDetailRow('${qa.question} - ${qa.textResponse}', '')
          ).toList(),
          
          // Subservice text questions
          if (service.subserviceDetails != null)
            ...service.subserviceDetails!.questionAnswerModifiers.where((qa) => qa.isTextInput && qa.textResponse != null && qa.textResponse!.isNotEmpty).map((qa) => 
              _buildDetailRow('${qa.question} - ${qa.textResponse}', '')
            ).toList(),
          
          // Notes - always show if not empty after trim
          if (service.tailorNotes.trim().isNotEmpty)
            _buildDetailRow('Notes - ${service.tailorNotes.trim()}', ''),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (price.isNotEmpty)
            Text(
              price,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: luxuryGold.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomDrawer() {
    if (_bottomSheetAnimation == null || _bottomSheetController == null) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _bottomSheetAnimation!,
        builder: (context, child) {
          return GestureDetector(
            onPanUpdate: (details) {
              if (details.delta.dy < 0) {
                // Swiping up
                if (_bottomSheetController!.value < 1.0) {
                  _bottomSheetController!.forward();
                }
              } else if (details.delta.dy > 0) {
                // Swiping down
                if (_bottomSheetController!.value > 0.0) {
                  _bottomSheetController!.reverse();
                }
              }
            },
            child: Container(
              height: 60 + (_bottomSheetAnimation!.value * 195), // Collapsed: 60, Expanded: 280
              decoration: BoxDecoration(
                color: darkBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: luxuryGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: luxuryGold.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Collapsed content (visible only when closed) - subtotal
                  if (_bottomSheetAnimation!.value < 0.1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
                          );
                        },
                      ),
                    ),
                  
                  // Expanded content (visible when pulled up)
                  if (_bottomSheetAnimation!.value > 0)
                    Expanded(
                      child: Opacity(
                        opacity: _bottomSheetAnimation!.value,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                              // Discount code section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: luxuryGold.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Centered vertically, left-aligned horizontally
                                          Positioned.fill(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: TextField(
                                                  controller: _discountController,
                                                  style: GoogleFonts.lato(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.left,
                                                  decoration: InputDecoration(
                                                    hintText: 'Discount code',
                                                    hintStyle: GoogleFonts.lato(
                                                      fontSize: 12,
                                                      color: Colors.white.withOpacity(0.6),
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                    border: InputBorder.none,
                                                    contentPadding: EdgeInsets.zero,
                                                    enabledBorder: InputBorder.none,
                                                    focusedBorder: InputBorder.none,
                                                    errorBorder: InputBorder.none,
                                                    focusedErrorBorder: InputBorder.none,
                                                    isDense: true,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: luxuryGold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: luxuryGold.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Apply',
                                        style: GoogleFonts.lato(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: luxuryGold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Shipping
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Shipping',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Calculated at checkout',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.5),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              
                              // Subtotal
                              Consumer<CartProvider>(
                                builder: (context, cartProvider, child) {
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Subtotal',
                                            style: GoogleFonts.lato(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
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
                                      if (cartProvider.loyaltyDiscountApplied) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.card_giftcard,
                                                  size: 14,
                                                  color: luxuryGold,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Loyalty Discount',
                                                  style: GoogleFonts.lato(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: luxuryGold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '-${cartProvider.formatPrice(cartProvider.loyaltyDiscount)}',
                                              style: GoogleFonts.lato(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: luxuryGold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          height: 1,
                                          color: luxuryGold.withOpacity(0.2),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total',
                                              style: GoogleFonts.lato(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              cartProvider.formatPrice(cartProvider.total),
                                              style: GoogleFonts.lato(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: luxuryGold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              
                              // Add new item button
                              GestureDetector(
                                onTap: () {
                                  // Navigate to index 0 for adding a new item
                                  Navigator.pushNamed(context, '/tailor', arguments: {'index': 0});
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: luxuryGold.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Add a new item',
                                        style: GoogleFonts.lato(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.add,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              
                              // Checkout button
                              Consumer<CartProvider>(
                                builder: (context, cartProvider, child) {
                                  return GestureDetector(
                                    onTap: () {
                                      if (cartProvider.items.isNotEmpty && !_isProcessingPayment) {
                                        _showStripeCheckoutBottomSheet(context, cartProvider);
                                      }
                                    },
                                child: Container(
                                  width: double.infinity,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: _isProcessingPayment ? [
                                        Colors.grey,
                                        Colors.grey.withOpacity(0.8),
                                      ] : [
                                        luxuryGold,
                                        luxuryGold.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isProcessingPayment) ...[
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(darkBackground),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Processing...',
                                          style: GoogleFonts.lato(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: darkBackground,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Go to checkout',
                                          style: GoogleFonts.lato(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: darkBackground,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: darkBackground,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                );
                                },
                              ),
                              const SizedBox(height: 4),
                              
                              // Terms text
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'By continuing, I agree to House of Tailors\'s terms and conditions, privacy policy and service policies.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                    fontSize: 9,
                                    color: Colors.white.withOpacity(0.4),
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStripeCheckoutBottomSheet(BuildContext context, CartProvider cartProvider) async {
    // Prevent double-click
    if (_isProcessingPayment) return;
    
    setState(() {
      _isProcessingPayment = true;
    });
    
    try {
      // Check if this is a zero amount payment (loyalty discount)
      final total = cartProvider.total; // Use total instead of subtotal to include discount
      final amountInPence = total.round();
      
      if (kDebugMode) {
        print('=== PAYMENT AMOUNT CHECK ===');
        print('Subtotal: ${cartProvider.formatPrice(cartProvider.subtotal)}');
        print('Loyalty Discount: ${cartProvider.formatPrice(cartProvider.loyaltyDiscount)}');
        print('Total: ${cartProvider.formatPrice(cartProvider.total)}');
        print('Amount in pence: $amountInPence');
        print('Is zero amount: ${amountInPence == 0}');
        print('============================');
      }
      
      if (amountInPence == 0) {
        // Handle zero amount payment without Stripe PaymentSheet
        await _processZeroAmountPayment(cartProvider);
        return;
      }
      
      // Initialize PaymentSheet for non-zero amounts
      final paymentIntentResponse = await _initializePaymentSheet(cartProvider);
      
      // Present the PaymentSheet
      await Stripe.instance.presentPaymentSheet();
      
      // Payment succeeded - capture shipping details
      final paymentSheetResult = await Stripe.instance.retrievePaymentIntent(paymentIntentResponse['client_secret']);
      
      // Get billing details for order saving
      Map<String, dynamic> billingDetails = {};
      if (paymentSheetResult.paymentMethodId != null) {
        try {
          final paymentMethodResponse = await StripeService.retrievePaymentMethod(paymentSheetResult.paymentMethodId!);
          billingDetails = paymentMethodResponse['billing_details'] ?? {};
        } catch (e) {
          if (kDebugMode) {
            print('Error retrieving payment method details: $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('=== PAYMENT SUCCEEDED ===');
        print('Payment Intent ID: ${paymentSheetResult.id}');
        print('Amount: ${paymentSheetResult.amount}');
        print('Currency: ${paymentSheetResult.currency}');
        print('Status: ${paymentSheetResult.status}');
        
        if (billingDetails.isNotEmpty) {
          print('=== BILLING DETAILS ===');
          print('Customer Name: ${billingDetails['name']}');
          print('Customer Email: ${billingDetails['email']}');
          print('Customer Phone: ${billingDetails['phone']}');
          
          if (billingDetails['address'] != null) {
            final address = billingDetails['address'];
            print('Address Line 1: ${address['line1']}');
            print('Address Line 2: ${address['line2']}');
            print('City: ${address['city']}');
            print('State: ${address['state']}');
            print('Postal Code: ${address['postal_code']}');
            print('Country: ${address['country']}');
          }
        }
        
        if (paymentSheetResult.receiptEmail != null) {
          print('Receipt Email: ${paymentSheetResult.receiptEmail}');
        }
        
        print('=== ORDER SUMMARY ===');
        print('Items: ${cartProvider.items.length}');
        for (var item in cartProvider.items) {
          print('- ${item.itemDescription}: ${cartProvider.formatPrice(item.totalPrice)}');
        }
        print('Total: ${cartProvider.formatPrice(cartProvider.subtotal)}');
        print('========================');
      }
      
      // Save order to database
      try {
        final orderId = await OrderService.saveOrder(
          items: cartProvider.items,
          totalAmount: cartProvider.total, // Use total to include loyalty discount
          paymentIntentId: paymentSheetResult.id,
          billingDetails: billingDetails,
          currency: paymentSheetResult.currency ?? 'gbp',
        );
        
        if (kDebugMode) {
          print('Order saved to database with ID: $orderId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving order to database: $e');
        }
      }
      
      cartProvider.clearCart();
      
      // Refresh loyalty progress after successful order (OrderService already incremented it)
      try {
        final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
        await loyaltyProvider.refreshLoyaltyProgress();
        if (kDebugMode) {
          print('Loyalty progress refreshed after successful order');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing loyalty progress after order: $e');
        }
      }
      
      _showSuccessToast(context);
      
    } on StripeException catch (e) {
      if (kDebugMode) {
        print('Stripe error: ${e.error.localizedMessage}');
      }
      
      // Handle specific Stripe errors
      if (e.error.code == FailureCode.Canceled) {
        // User canceled payment - don't show error
        if (kDebugMode) {
          print('Payment was canceled by user');
        }
      } else {
        // Show error for other Stripe issues
        _showErrorToast(context, 'Payment failed: ${e.error.localizedMessage ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Payment failed: $e');
      }
      
      // Only show error if it's not a user cancellation
      if (!e.toString().toLowerCase().contains('cancel')) {
        _showErrorToast(context, 'Payment failed. Please try again.');
      }
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _processZeroAmountPayment(CartProvider cartProvider) async {
    try {
      if (kDebugMode) {
        print('=== PROCESSING ZERO AMOUNT PAYMENT ===');
        print('Total: £0.00 (Loyalty Discount Applied)');
        print('Items: ${cartProvider.items.length}');
        for (var item in cartProvider.items) {
          print('- ${item.itemDescription}: ${cartProvider.formatPrice(item.totalPrice)}');
        }
        print('Loyalty Discount: -${cartProvider.formatPrice(cartProvider.loyaltyDiscount)}');
        print('=======================================');
      }
      
      // Show custom billing form for zero amount orders
      final billingDetails = await _showBillingDetailsForm();
      
      if (billingDetails == null) {
        // User canceled the form
        return;
      }
      
      // Create payment intent ID for zero amount orders
      final paymentIntentId = 'pi_loyalty_${DateTime.now().millisecondsSinceEpoch}';
      
      // Save order to database with collected billing details
      try {
        final orderId = await OrderService.saveOrder(
          items: cartProvider.items,
          totalAmount: cartProvider.total, // This will be 0 for loyalty discount orders
          paymentIntentId: paymentIntentId,
          billingDetails: billingDetails,
          currency: 'gbp',
        );
        
        if (kDebugMode) {
          print('Zero amount order saved to database with ID: $orderId');
          print('=== ZERO AMOUNT BILLING DETAILS ===');
          print('Customer Name: ${billingDetails['name']}');
          print('Customer Email: ${billingDetails['email']}');
          print('Customer Phone: ${billingDetails['phone']}');
          if (billingDetails['address'] != null) {
            final address = billingDetails['address'];
            print('Address: ${address['line1']}, ${address['city']}, ${address['postal_code']}');
          }
          print('==================================');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving zero amount order to database: $e');
        }
        throw Exception('Failed to save order');
      }
      
      cartProvider.clearCart();
      
      // Refresh loyalty progress after successful order
      try {
        final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
        await loyaltyProvider.refreshLoyaltyProgress();
        if (kDebugMode) {
          print('Loyalty progress refreshed after zero amount order');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing loyalty progress after zero amount order: $e');
        }
      }
      
      _showSuccessToast(context);
      
    } catch (e) {
      if (kDebugMode) {
        print('Zero amount payment failed: $e');
      }
      _showErrorToast(context, 'Order failed. Please try again.');
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<Map<String, dynamic>> _initializePaymentSheet(CartProvider cartProvider) async {
    try {
      // Create payment intent
      final total = cartProvider.total; // Use total to include loyalty discount
      final amountInPence = total.round(); // Prices are already in pence
      
      if (kDebugMode) {
        print('Checkout - Total raw: $total');
        print('Checkout - Total display: ${cartProvider.formatPrice(total)}');
        print('Checkout - Amount in pence: $amountInPence');
      }
      
      final paymentIntentResponse = await StripeService.createPaymentIntent(
        amount: amountInPence,
        currency: 'gbp',
        customerEmail: null,
        shippingAddress: {
          'address': {
            'country': 'GB',
          },
          'name': 'Customer',
        },
      );

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentResponse['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: 'House of Tailors',
          allowsDelayedPaymentMethods: true,
          billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration(
            email: CollectionMode.always,
            name: CollectionMode.always,
            phone: CollectionMode.always,
            address: AddressCollectionMode.full,
          ),
          billingDetails: BillingDetails(
            address: Address(
              country: 'GB',
              city: '',
              line1: '',
              line2: '',
              postalCode: '',
              state: '',
            ),
            email: '',
            name: '',
            phone: '',
          ),
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: luxuryGold,
              background: Colors.white,
              componentBackground: Colors.white,
              componentText: Colors.black,
              primaryText: Colors.black,
              secondaryText: Colors.black.withOpacity(0.7),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 8,
              borderWidth: 1,
            ),
          ),
        ),
      );
      
      return paymentIntentResponse;
    } catch (e) {
      throw Exception('Failed to initialize payment: $e');
    }
  }

  void _showSuccessToast(BuildContext context) {
    ToastService.showSuccess(context, 'Payment successful! Your order has been placed.');
    
    // Refresh orders in the background
    Provider.of<OrderProvider>(context, listen: false).refreshOrders();
  }

  void _showErrorToast(BuildContext context, String message) {
    ToastService.showError(context, message);
  }

  Future<Map<String, dynamic>?> _showBillingDetailsForm() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final line1Controller = TextEditingController();
    final line2Controller = TextEditingController();
    final cityController = TextEditingController();
    final postalCodeController = TextEditingController();
    
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: darkBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(
            color: luxuryGold.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Complete Your ',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: 'Free Order',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: luxuryGold,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Please provide your details to complete this loyalty discount order.',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              
              // Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField('Full Name *', nameController, setModalState),
                      _buildFormField('Email Address *', emailController, setModalState, keyboardType: TextInputType.emailAddress),
                      _buildFormField('Phone Number *', phoneController, setModalState, keyboardType: TextInputType.phone),
                      _buildFormField('Address Line 1 *', line1Controller, setModalState),
                      _buildFormField('Address Line 2 (Optional)', line2Controller, setModalState),
                      _buildFormField('City/Town *', cityController, setModalState),
                      _buildFormField('Postal Code *', postalCodeController, setModalState),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              // Submit Button
              Container(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    // Validate required fields
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty ||
                        line1Controller.text.trim().isEmpty ||
                        cityController.text.trim().isEmpty ||
                        postalCodeController.text.trim().isEmpty) {
                      _showErrorToast(context, 'Please fill in all required fields');
                      return;
                    }
                    
                    // Validate email format
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
                      _showErrorToast(context, 'Please enter a valid email address');
                      return;
                    }
                    
                    final billingDetails = {
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'address': {
                        'line1': line1Controller.text.trim(),
                        'line2': line2Controller.text.trim(),
                        'city': cityController.text.trim(),
                        'state': '',
                        'postal_code': postalCodeController.text.trim(),
                        'country': 'GB',
                      }
                    };
                    
                    Navigator.pop(context, billingDetails);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: luxuryGold,
                    foregroundColor: darkBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Complete Free Order',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _formatPickupDate(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = today.add(const Duration(days: 1));
    
    if (date.isAtSameMomentAs(today)) {
      return 'Today, ${_formatShortDate(date)}';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow, ${_formatShortDate(date)}';
    } else {
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      String dayName = dayNames[date.weekday - 1];
      return '$dayName, ${_formatShortDate(date)}';
    }
  }
  
  String _formatShortDate(DateTime date) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String monthName = monthNames[date.month - 1];
    return '$monthName ${date.day}';
  }

  Widget _buildFormField(String label, TextEditingController controller, StateSetter setModalState, {TextInputType? keyboardType}) {
    final isOptional = label.contains('(Optional)');
    final cleanLabel = label.replaceAll(' (Optional)', '');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: luxuryGold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Placeholder text - centered vertically, left aligned
                if (controller.text.isEmpty)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          isOptional 
                            ? '${cleanLabel.toLowerCase().replaceAll(' *', '')} (optional)'
                            : 'Enter ${cleanLabel.toLowerCase().replaceAll(' *', '')}',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                // TextField
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    // Trigger rebuild to show/hide placeholder
                    setModalState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

 