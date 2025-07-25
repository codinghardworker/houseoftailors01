import 'package:flutter/foundation.dart';
import 'cart_provider.dart';
import '../services/order_service.dart';

// Order Status Enum
enum OrderStatus { pickup, processing, completed }

// Order Model
class Order {
  final String orderNumber;
  final String date;
  final OrderStatus status;
  final String pickupTime;
  final String location;
  final List<CartItem> items;
  final double totalPrice;
  final String? completionDate;
  final String? id;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? deliveryMethod; // 'pickup' or 'post'
  final DateTime? pickupDate; // For pickup orders
  final String? pickupTimeSlot; // For pickup orders
  final double? deliveryCharge; // Delivery/pickup charge

  const Order({
    required this.orderNumber,
    required this.date,
    required this.status,
    required this.pickupTime,
    required this.location,
    required this.items,
    required this.totalPrice,
    this.completionDate,
    this.id,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.deliveryMethod,
    this.pickupDate,
    this.pickupTimeSlot,
    this.deliveryCharge,
  });

  int get totalItems => items.length;
  int get totalServices => items.fold(0, (sum, item) => sum + item.serviceDetails.length);

  // Create a copy of the order with updated status
  Order copyWith({
    String? orderNumber,
    String? date,
    OrderStatus? status,
    String? pickupTime,
    String? location,
    List<CartItem>? items,
    double? totalPrice,
    String? completionDate,
    String? id,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? deliveryMethod,
    DateTime? pickupDate,
    String? pickupTimeSlot,
    double? deliveryCharge,
  }) {
    return Order(
      orderNumber: orderNumber ?? this.orderNumber,
      date: date ?? this.date,
      status: status ?? this.status,
      pickupTime: pickupTime ?? this.pickupTime,
      location: location ?? this.location,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      completionDate: completionDate ?? this.completionDate,
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTimeSlot: pickupTimeSlot ?? this.pickupTimeSlot,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
    );
  }

  // Create order from database data
  factory Order.fromDatabase(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('=== ORDER CREATION DEBUG ===');
      print('Full data: $data');
      print('paymentIntentId: ${data['paymentIntentId']}');
      print('id: ${data['id']}');
      print('orderedAt: ${data['orderedAt']}');
      print('status: ${data['status']}');
      print('billingAddress: ${data['billingAddress']}');
      print('totalAmount: ${data['totalAmount']}');
      print('customerName: ${data['customerName']}');
      print('orderItems: ${data['orderItems']}');
    }
    
    final orderItems = data['orderItems'] as List<dynamic>? ?? [];
    if (kDebugMode) {
      print('Order items: $orderItems');
    }
    
    final items = orderItems.map((itemData) {
      if (kDebugMode) {
        print('Creating cart item from: $itemData');
      }
      return CartItem.fromDatabase(itemData);
    }).toList();
    
    // Extract delivery information from first service (all services in an order should have same delivery method)
    String? deliveryMethod;
    DateTime? pickupDate;
    String? pickupTimeSlot;
    double? deliveryCharge;
    
    if (items.isNotEmpty && items.first.serviceDetails.isNotEmpty) {
      final firstService = items.first.serviceDetails.first;
      deliveryMethod = firstService.deliveryMethod;
      pickupDate = firstService.pickupDate;
      pickupTimeSlot = firstService.pickupTime;
      deliveryCharge = firstService.pickupCost;
    }

    final order = Order(
      id: data['id'],
      orderNumber: _generateOrderNumber(data['paymentIntentId'] ?? data['id']),
      date: _formatDate(data['orderedAt']),
      status: _parseOrderStatus(data['status']),
      pickupTime: pickupTimeSlot ?? 'Pickup available', 
      location: _formatAddress(data['billingAddress']),
      items: items,
      totalPrice: ((data['totalAmount'] as num?)?.toDouble() ?? 0.0) / 100.0,
      completionDate: data['status'] == 'completed' ? _formatDate(data['updatedAt']) : null,
      customerName: data['customerName'],
      customerEmail: data['customerEmail'],
      customerPhone: data['customerPhone'],
      deliveryMethod: deliveryMethod,
      pickupDate: pickupDate,
      pickupTimeSlot: pickupTimeSlot,
      deliveryCharge: deliveryCharge,
    );
    
    if (kDebugMode) {
      print('Created order: ${order.orderNumber} with ${order.items.length} items');
    }
    
    return order;
  }

  static String _generateOrderNumber(String? paymentIntentId) {
    if (paymentIntentId == null) return '000000';
    
    // Extract last 6 characters or use hash if shorter
    if (paymentIntentId.length >= 6) {
      return paymentIntentId.substring(paymentIntentId.length - 6).toUpperCase();
    } else {
      // Create a 6-character hash from the ID
      int hash = paymentIntentId.hashCode;
      return (hash.abs() % 1000000).toString().padLeft(6, '0');
    }
  }

  static String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        // Handle Firestore Timestamp
        date = dateValue.toDate();
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pickup':
        return OrderStatus.pickup;
      case 'processing':
        return OrderStatus.processing;
      case 'completed':
        return OrderStatus.completed;
      default:
        return OrderStatus.pickup;
    }
  }

  static String _formatAddress(Map<String, dynamic>? address) {
    if (address == null) return 'Pickup available';
    
    final parts = <String>[];
    if (address['line1'] != null && address['line1'].toString().isNotEmpty) {
      parts.add(address['line1']);
    }
    if (address['line2'] != null && address['line2'].toString().isNotEmpty) {
      parts.add(address['line2']);
    }
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      parts.add(address['city']);
    }
    
    if (parts.isEmpty) return 'Pickup available';
    
    // Format as max 2 lines: line1 + line2 (if exists), then city
    String result = '';
    if (parts.length <= 2) {
      result = parts.join(', ');
    } else {
      // First line: line1 + line2
      String firstLine = parts.take(2).join(', ');
      // Second line: city
      String secondLine = parts.skip(2).join(', ');
      result = '$firstLine\n$secondLine';
    }
    
    return result;
  }
}

// Order Provider for State Management
class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];

  // Constructor - load orders on initialization
  OrderProvider() {
    _loadOrders();
  }

  int _currentTabIndex = 0;
  bool _isLoading = false;
  String _currentScreen = 'Home';

  // Getters
  List<Order> get allOrders => _orders;
  
  List<Order> get ongoingOrders => _orders.where((order) => 
    order.status == OrderStatus.pickup || order.status == OrderStatus.processing
  ).toList();

  List<Order> get completedOrders => _orders.where((order) => 
    order.status == OrderStatus.completed
  ).toList();

  int get currentTabIndex => _currentTabIndex;
  bool get isLoading => _isLoading;
  String get currentScreen => _currentScreen;

  // Tab management
  void setCurrentTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  // Loading state management
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Navigation management
  void setCurrentScreen(String screen) {
    if (_currentScreen != screen) {
      _currentScreen = screen;
      notifyListeners();
    }
  }

  // Order management methods
  void addOrder(Order order) {
    _orders.add(order);
    notifyListeners();
  }

  void updateOrderStatus(String orderNumber, OrderStatus newStatus) {
    final orderIndex = _orders.indexWhere((order) => order.orderNumber == orderNumber);
    if (orderIndex != -1) {
      _orders[orderIndex] = _orders[orderIndex].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void removeOrder(String orderNumber) {
    _orders.removeWhere((order) => order.orderNumber == orderNumber);
    notifyListeners();
  }

  // Load orders from database
  Future<void> _loadOrders() async {
    try {
      setLoading(true);
      if (kDebugMode) {
        print('Loading orders from database...');
        // Run debug to check table status
        await OrderService.debugOrders();
      }
      
      final orderData = await OrderService.getUserOrders();
      
      if (kDebugMode) {
        print('Raw order data: $orderData');
      }
      
      _orders = orderData.map((data) {
        if (kDebugMode) {
          print('Processing order: ${data['id']}');
        }
        return Order.fromDatabase(data);
      }).toList();
      
      if (kDebugMode) {
        print('Loaded ${_orders.length} orders');
        for (var order in _orders) {
          print('Order: ${order.orderNumber}, Status: ${order.status}');
        }
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading orders: $e');
        print('Error stack trace: ${StackTrace.current}');
      }
    } finally {
      setLoading(false);
    }
  }

  // Refresh orders from database
  Future<void> refreshOrders() async {
    await _loadOrders();
  }

  // Get order by number
  Order? getOrderByNumber(String orderNumber) {
    try {
      return _orders.firstWhere((order) => order.orderNumber == orderNumber);
    } catch (e) {
      return null;
    }
  }

  // Get orders count
  int get totalOrdersCount => _orders.length;
  int get ongoingOrdersCount => ongoingOrders.length;
  int get completedOrdersCount => completedOrders.length;
} 