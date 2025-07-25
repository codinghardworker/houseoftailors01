import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/order_screen.dart';
import 'screens/tailor_screen.dart';
import 'screens/basket_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/service_selection_screen.dart';

import 'providers/order_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/tailor_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/service_selection_provider.dart';
import 'providers/loyalty_provider.dart';
import 'providers/shop_config_provider.dart';
import 'services/auth_service.dart';
import 'services/shop_config_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue with app initialization even if Firebase fails
  }
  
  // Initialize Google Fonts
  await GoogleFonts.pendingFonts([
    GoogleFonts.playfairDisplay(),
    GoogleFonts.lato(),
  ]);
  
  // Initialize AuthService
  await AuthService().initialize();
  
  // Initialize ShopConfigService
  print('📡 Main: Starting shop configuration...');
  ShopConfigService.initializeAsync(); // Don't await - immediate refresh on demand
  print('✅ Main: Shop configuration ready');
  
  // Initialize CartProvider and load cart data
  final cartProvider = CartProvider();
  await cartProvider.loadCartFromStorage();
  
  runApp(MyApp(cartProvider: cartProvider));
}

class MyApp extends StatefulWidget {
  final CartProvider cartProvider;
  
  const MyApp({super.key, required this.cartProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDynamicLinks();
  }

  void _initDynamicLinks() async {
    // Handle incoming dynamic links when app is in background/terminated
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      _handleDynamicLink(dynamicLinkData);
    }).onError((error) {
      print('Dynamic link error: $error');
    });

    // Handle dynamic link when app is launched from terminated state
    final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
    if (data != null) {
      _handleDynamicLink(data);
    }
  }

  void _handleDynamicLink(PendingDynamicLinkData data) {
    final Uri uri = data.link;
    print('Dynamic link received: $uri');
    
    // Handle deep links if needed in the future
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Save cart when app is paused or closed
      widget.cartProvider.saveCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => TailorProvider()),
        ChangeNotifierProvider.value(value: widget.cartProvider),
        ChangeNotifierProvider(create: (context) => ServiceSelectionProvider()),
        ChangeNotifierProvider.value(value: AuthService()),
        ChangeNotifierProvider(create: (context) => LoyaltyProvider(context.read<AuthService>())),
        ChangeNotifierProvider(create: (context) => ShopConfigProvider()),
      ],
      child: MaterialApp(
        title: 'House of Tailors',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/orders': (context) => const OrderScreen(),
          '/tailor': (context) => const TailorScreen(),
          '/basket': (context) => const BasketScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/service_selection': (context) => const ServiceSelectionScreen(),
        },
      ),
    );
  }
} 