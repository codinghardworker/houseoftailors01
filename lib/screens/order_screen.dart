import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/app_bar_component.dart';
import '../components/bottom_navigation_component.dart';
import '../providers/order_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/shop_config_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin, RouteAware {
  static const Color luxuryGold = Color(0xFFE8D26D);
  late TabController _tabController;
  final Set<String> _expandedServices = {};
  final Set<String> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    
    // Set current screen when entering OrderScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationProvider>(context, listen: false).setCurrentScreen('Orders');
      // Refresh orders when screen loads
      Provider.of<OrderProvider>(context, listen: false).refreshOrders();
    });
    
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.setCurrentTab(_tabController.index);
  }

  // Method to refresh orders when screen becomes visible
  void _refreshOrdersIfNeeded() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if (!orderProvider.isLoading) {
      orderProvider.refreshOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBarComponent(showBackButton: true),
              const SizedBox(height: 2),
              
              // Add refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Orders',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Consumer<OrderProvider>(
                    builder: (context, orderProvider, child) {
                      return IconButton(
                        onPressed: orderProvider.isLoading ? null : () => orderProvider.refreshOrders(),
                        icon: orderProvider.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(luxuryGold),
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                color: luxuryGold,
                                size: 24,
                              ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: luxuryGold,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: luxuryGold,
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  labelStyle: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Orders'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tab Bar View with Consumer
              Expanded(
                child: Consumer<OrderProvider>(
                  builder: (context, orderProvider, child) {
                    return RefreshIndicator(
                      onRefresh: orderProvider.refreshOrders,
                      color: luxuryGold,
                      backgroundColor: const Color(0xFF1A1A1A),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Orders Tab
                          _buildOrdersList(orderProvider.ongoingOrders, orderProvider.isLoading),
                          // History Tab
                          _buildOrdersList(orderProvider.completedOrders, orderProvider.isLoading),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationComponent(),
    );
  }

  Widget _buildOrdersList(List<Order> orders, bool isLoading) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(luxuryGold),
          strokeWidth: 2,
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          ...orders.map((order) => Column(
            children: [
              _buildComprehensiveOrderCard(order),
              const SizedBox(height: 16),
            ],
          )).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildComprehensiveOrderCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: luxuryGold.withOpacity(0.25),
          width: 0.8,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.01),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Order and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                'Ordered on ${order.date}',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Progress & When/Where Combined Row
          Row(
            children: [
              // Progress Section (Left)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Pickup with label
                        Column(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isStepCompleted(order.status, 0) ? luxuryGold : Colors.transparent,
                                border: !_isStepCompleted(order.status, 0) ? Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ) : null,
                              ),
                              child: Icon(
                                order.deliveryMethod == 'post' ? Icons.mail : Icons.local_shipping,
                                color: _isStepCompleted(order.status, 0) ? Colors.black : Colors.white.withOpacity(0.4),
                                size: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.deliveryMethod == 'post' ? 'Post' : 'Pickup',
                              style: GoogleFonts.lato(
                                fontSize: 7,
                                color: _isStepCompleted(order.status, 0) ? Colors.white : Colors.white.withOpacity(0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // Line 1-2
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            color: _isStepCompleted(order.status, 1) ? luxuryGold : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        // Processing with label
                        Column(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isStepCompleted(order.status, 1) ? luxuryGold : Colors.transparent,
                                border: !_isStepCompleted(order.status, 1) ? Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ) : null,
                              ),
                              child: Icon(
                                Icons.content_cut,
                                color: _isStepCompleted(order.status, 1) ? Colors.black : Colors.white.withOpacity(0.4),
                                size: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Process',
                              style: GoogleFonts.lato(
                                fontSize: 7,
                                color: _isStepCompleted(order.status, 1) ? Colors.white : Colors.white.withOpacity(0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // Line 2-3
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            color: _isStepCompleted(order.status, 2) ? luxuryGold : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        // Completion with label
                        Column(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isStepCompleted(order.status, 2) ? luxuryGold : Colors.transparent,
                                border: !_isStepCompleted(order.status, 2) ? Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ) : null,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: _isStepCompleted(order.status, 2) ? Colors.black : Colors.white.withOpacity(0.4),
                                size: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Done',
                              style: GoogleFonts.lato(
                                fontSize: 7,
                                color: _isStepCompleted(order.status, 2) ? Colors.white : Colors.white.withOpacity(0.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // When/Where Section (Right) - Only Address
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Shop Location with Map Link - only for pickup orders
                        if (order.deliveryMethod == 'pickup')
                          Consumer<ShopConfigProvider>(
                            builder: (context, shopConfig, child) {
                              return GestureDetector(
                                onTap: () => _openShopMaps(shopConfig),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.store,
                                      color: luxuryGold.withOpacity(0.8),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Shop Location',
                                      style: GoogleFonts.lato(
                                        fontSize: 12,
                                        color: luxuryGold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: luxuryGold.withOpacity(0.8),
                                      size: 10,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        if (order.deliveryMethod == 'pickup') const SizedBox(height: 4),
                        // User Location with icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: luxuryGold.withOpacity(0.8),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                order.location,
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Items list with basket screen functionality - compact
          ..._buildItemsList(order),
          
          const SizedBox(height: 6),
          
          // Total Price and Show More/Less Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: £${(order.totalPrice * 100).toStringAsFixed(2)}',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: luxuryGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (order.items.length > 2)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final isExpanded = _expandedOrders.contains(order.orderNumber);
                      if (isExpanded) {
                        _expandedOrders.remove(order.orderNumber);
                      } else {
                        _expandedOrders.add(order.orderNumber);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: luxuryGold.withOpacity(0.5),
                        width: 1,
                      ),
                      color: luxuryGold.withOpacity(0.12),
                    ),
                    child: Text(
                      _expandedOrders.contains(order.orderNumber)
                        ? 'Show less (${order.items.length - 2} items hidden)'
                        : 'Show more (${order.items.length - 2} more items)',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        color: luxuryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 12,
            color: luxuryGold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItemsList(Order order) {
    final isExpanded = _expandedOrders.contains(order.orderNumber);
    final shouldShowButton = order.items.length > 2;
    final itemsToShow = shouldShowButton && !isExpanded ? 2 : order.items.length;
    
    List<Widget> widgets = [];
    
    // Show limited items
    for (int index = 0; index < itemsToShow; index++) {
      final item = order.items[index];
      widgets.add(_buildOrderItemWithInfo(item, index));
      if (index < itemsToShow - 1) {
        widgets.add(const SizedBox(height: 4));
      }
    }
    
    
    return widgets;
  }

  Widget _buildOrderItemWithInfo(CartItem item, int itemIndex) {
    final itemKey = 'item_${itemIndex}';
    final isItemExpanded = _expandedOrders.contains(itemKey);
    final shouldShowServiceButton = item.serviceDetails.length > 3;
    final servicesToShow = shouldShowServiceButton && !isItemExpanded ? 3 : item.serviceDetails.length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name - compact
          Text(
            item.itemDescription,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          
          // Services list with Show/Hide Info functionality - compact
          ...item.serviceDetails.asMap().entries.take(servicesToShow).map((entry) {
            int serviceIndex = entry.key;
            ServiceDetails service = entry.value;
            return _buildServiceRow(service, serviceIndex, itemIndex);
          }).toList(),
          
          // Show more/less button for services
          if (shouldShowServiceButton) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isItemExpanded) {
                    _expandedOrders.remove(itemKey);
                  } else {
                    _expandedOrders.add(itemKey);
                  }
                });
              },
              child: Text(
                isItemExpanded 
                  ? 'Show less services'
                  : 'Show ${item.serviceDetails.length - 3} more services',
                style: GoogleFonts.lato(
                  fontSize: 9,
                  color: luxuryGold.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildServiceRow(ServiceDetails service, int serviceIndex, int itemIndex) {
    final serviceKey = '${itemIndex}_${service.service.id}';
    final isExpanded = _expandedServices.contains(serviceKey);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  service.service.name,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Text(
                formatPrice(service.totalPrice),
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: luxuryGold,
                ),
              ),
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
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                isExpanded ? 'Hide service info' : 'Show service info',
                style: GoogleFonts.lato(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          if (isExpanded) _buildServiceDetails(service),
        ],
      ),
    );
  }

  Widget _buildServiceDetails(ServiceDetails service) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: luxuryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items with prices shown first
          _buildDetailRow('Base price:', formatPrice(service.basePrice)),
          
          // Pickup cost if available
          if (service.deliveryMethod == 'pickup' && service.pickupCost != null && service.pickupCost! > 0)
            _buildDetailRow('Pickup Cost:', '+ £${service.pickupCost!.toStringAsFixed(2)}'),
          
          // Question answers with price modifiers
          ...service.questionAnswerModifiers.where((qa) => !qa.isTextInput || qa.priceModifier > 0).map((qa) {
            String answer = qa.isTextInput && qa.textResponse != null && qa.textResponse!.isNotEmpty 
              ? qa.textResponse! 
              : qa.answer;
            
            return _buildDetailRow(
              '${qa.question} - $answer', 
              qa.priceModifier > 0 ? '+ ${formatPrice(qa.priceModifier)}' : ''
            );
          }).toList(),
          
          // Subservice details if present
          if (service.subserviceDetails != null) ...[
            _buildDetailRow(
              service.subserviceDetails!.subservice.name, 
              '+ ${formatPrice(service.subserviceDetails!.subservice.priceModifier)}'
            ),
            ...service.subserviceDetails!.questionAnswerModifiers.where((qa) => !qa.isTextInput || qa.priceModifier > 0).map((qa) {
              String answer = qa.isTextInput && qa.textResponse != null && qa.textResponse!.isNotEmpty 
                ? qa.textResponse! 
                : qa.answer;
              
              return _buildDetailRow(
                '${qa.question} - $answer', 
                qa.priceModifier > 0 ? '+ ${formatPrice(qa.priceModifier)}' : ''
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
          
          // Text-based questions displayed separately
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
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 9,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (price.isNotEmpty)
            Text(
              price,
              style: GoogleFonts.lato(
                fontSize: 9,
                color: luxuryGold.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  String formatPrice(double price) {
    return '£${(price).toStringAsFixed(2)} ';
  }

  Widget _buildShopAddressForPost() {
    return Consumer<ShopConfigProvider>(
      builder: (context, shopConfig, child) {
        final shopAddress = shopConfig.formattedShopAddress;
        final shopName = shopConfig.shopName.isNotEmpty ? shopConfig.shopName : 'House of Tailors';
        
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: luxuryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: luxuryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: luxuryGold,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Send items to:',
                      style: GoogleFonts.lato(
                        fontSize: 9,
                        color: luxuryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openMaps(shopConfig),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: luxuryGold,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map,
                            size: 10,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Map',
                            style: GoogleFonts.lato(
                              fontSize: 8,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                shopAddress,
                style: GoogleFonts.lato(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMaps(ShopConfigProvider shopConfig) async {
    final address = shopConfig.formattedShopAddress.replaceAll('\n', ', ');
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openShopMaps(ShopConfigProvider shopConfig) async {
    // Use shop address and name from shop config provider
    String address = shopConfig.formattedShopAddress;
    
    // If no address, use shop name
    if (address.isEmpty) {
      address = shopConfig.shopName;
    }
    
    // Only proceed if we have an address
    if (address.isNotEmpty) {
      final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _formatPickupDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }


  Widget _buildStatusIcon(IconData icon, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? color : Colors.white.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Icon(
        icon,
        color: isActive ? color : Colors.white.withOpacity(0.5),
        size: 14,
      ),
    );
  }

  bool _isStepCompleted(OrderStatus status, int step) {
    switch (status) {
      case OrderStatus.pickup:
        return step == 0;
      case OrderStatus.processing:
        return step <= 1;
      case OrderStatus.completed:
        return step <= 2;
    }
  }
} 