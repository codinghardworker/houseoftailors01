import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';
import '../services/image_service.dart';
import '../services/auth_service.dart';
import '../services/shop_config_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Start image preloading immediately
    _startPreloading();
    
    // Initialize animation controller with 1800ms animation duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2400), // Animation duration
      vsync: this,
    );

    // Configure fade animation (starts immediately)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.0, 1.0,
          curve: Curves.easeInOutCubic,
        ),
      ),
    );

    // Configure zoom animation (more noticeable)
    _scaleAnimation = Tween<double>(
      begin: 0.88, // More visible initial scale
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.0, 1.0,
          curve: Curves.easeOutQuint,
        ),
      ),
    );

    // Start animation after delay so you can see it from beginning
    Future.delayed(const Duration(milliseconds: 600), () {
      _animationController.forward();
    });
    
    // Navigate after total time (delay + animation + hold time)
    Timer(const Duration(milliseconds: 3000), () {
      _navigateToNext();
    });
  }

  void _navigateToNext() async {
    // Check authentication status and navigate accordingly
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Ensure shop config is fully initialized after determining login status
    if (authService.isLoggedIn) {
      print('🔐 Splash: User logged in, ensuring full shop config initialization...');
      ShopConfigService.ensureInitialized();
    }
    
    Widget nextScreen;
    if (authService.isLoggedIn) {
      // User is logged in, go to home screen
      nextScreen = const HomeScreen();
    } else {
      // User is not logged in, show welcome screen
      nextScreen = const WelcomeScreen();
    }
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionDuration: const Duration(milliseconds: 700), // Faster transition
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _startPreloading() {
    // Start preloading after a short delay to ensure context is available
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        ImageService.initializeEarlyPreloading(context);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/tailor.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.93),
                Colors.black.withOpacity(0.96),
              ],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 300.0,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}