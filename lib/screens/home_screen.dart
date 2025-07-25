import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/app_bar_component.dart';
import '../components/bottom_navigation_component.dart';
import '../components/location_drawer_component.dart';
import '../providers/navigation_provider.dart';
import '../providers/loyalty_provider.dart';
import '../services/responsive_grid.dart';
import '../services/user_location_service.dart';
import '../services/toast_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const luxuryGold = Color(0xFFE8D26D);
  
  String? _pressedCard;
  late AnimationController _scaleAnimationController;
  late Animation<double> _scaleAnimation;
  Timer? _refreshTimer;
  String? _userName;
  String? _userLocation;
  bool _isAuthenticated = false;
  bool _isLoadingUserData = true;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Set up auth state listener
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      // Clear cache when user auth state changes
      UserLocationService.clearCache();
      // Reload user data
      _loadUserData();
    });
    
    // Set current screen when entering HomeScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationProvider>(context, listen: false).setCurrentScreen('Home');
      // Refresh loyalty progress when entering home screen
      _refreshLoyaltyProgress();
      // Load user data
      _loadUserData();
    });
    
    // Set up periodic refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _refreshLoyaltyProgress();
    });
    
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh loyalty progress and user data when app becomes active
    if (state == AppLifecycleState.resumed) {
      _refreshLoyaltyProgress();
      _loadUserData();
    }
  }

  void _refreshLoyaltyProgress() {
    final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
    loyaltyProvider.refreshLoyaltyProgress();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scaleAnimationController.dispose();
    super.dispose();
  }

  void _onCardTapDown(String cardName) {
    setState(() {
      _pressedCard = cardName;
    });
    _scaleAnimationController.forward();
  }

  void _onCardTapUp(String cardName) {
    _scaleAnimationController.reverse();
    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() {
        _pressedCard = null;
      });
      
      if (cardName == 'Tailor') {
        Navigator.pushNamed(context, '/tailor');
      } else if (cardName == 'Dry Cleaning') {
        // TODO: Implement dry cleaning navigation
        print('Navigating to $cardName screen');
      } else {
        print('Navigating to $cardName screen');
      }
    });
  }

  void _onCardTapCancel() {
    _scaleAnimationController.reverse();
    setState(() {
      _pressedCard = null;
    });
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _isLoadingUserData = true;
      });
    }
    
    final isAuth = UserLocationService.isAuthenticated();
    final userName = await UserLocationService.getUserName();
    final locationData = await UserLocationService.getLocation();
    
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
        _userName = userName;
        _userLocation = locationData['location'];
        _isLoadingUserData = false;
      });
    }
  }

  void _showLocationDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => LocationDrawerComponent(
        onLocationSelected: () {
          // Handle location selection and show success toast
          _handleLocationSelection();
        },
      ),
    );
  }
  
  Future<void> _handleLocationSelection() async {
    // Add a small delay to ensure the location has been saved
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Reload user location after selection
    final locationData = await UserLocationService.getLocation();
    
    if (mounted) {
      setState(() {
        _userLocation = locationData['location'];
      });
      
      // Show success toast
      if (_userLocation != null) {
        ToastService.showSuccess(
          context, 
          'Location updated to $_userLocation'
        );
      } else {
        ToastService.showInfo(
          context,
          'Location selection completed'
        );
      }
      
      // Refresh loyalty progress
      _refreshLoyaltyProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshLoyaltyProgress();
            await _loadUserData();
            // Add a small delay to show the refresh indicator
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: luxuryGold,
          backgroundColor: const Color(0xFF1A1A1A),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 15.0),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBarComponent(),
                _buildGreeting(),
                const SizedBox(height: 12),
                _buildTitle(),
                const SizedBox(height: 22),
                _buildLocation(),
                const SizedBox(height: 24),
                _buildRewardSystem(),
                const SizedBox(height: 20),
                _buildFindServices(),
                const SizedBox(height: 20),
              ],
            ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationComponent(),
    );
  }

  Widget _buildGreeting() {
    String greeting = 'Good Morning';
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return RichText(
      text: TextSpan(
        children: [
          if (_isAuthenticated && _userName != null) ...[
            _buildTextSpan('$greeting, ', Colors.white, FontWeight.w500),
            _buildTextSpan(_userName!, luxuryGold, FontWeight.w600),
          ] else ...[
            _buildTextSpan(greeting, Colors.white, FontWeight.w500),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      text: TextSpan(
        children: [
          _buildTitleSpan('Discover premium\n', Colors.white, FontWeight.w400),
          _buildTitleSpan('tailor or dry cleaners', luxuryGold, FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    final displayLocation = _isLoadingUserData 
        ? 'Loading...' 
        : _isAuthenticated 
            ? (_userLocation ?? 'Choose your location')
            : 'Login to set location';
    
    return GestureDetector(
      onTap: _isLoadingUserData 
          ? null 
          : _isAuthenticated 
              ? _showLocationDrawer 
              : () {
                  // Navigate to login page for unauthenticated users
                  Navigator.pushNamed(context, '/login');
                },
      child: Row(
        children: [
          Icon(Icons.location_on, color: luxuryGold, size: 18),
          const SizedBox(width: 6),
          _buildLocationText('Location: ', luxuryGold, 14, FontWeight.w500),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: _isLoadingUserData
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                          ),
                        )
                      : _buildLocationText(
                          displayLocation, 
                          _isAuthenticated 
                              ? (_userLocation != null ? Colors.white : Colors.white.withOpacity(0.7))
                              : Colors.white.withOpacity(0.5), 
                          16, 
                          FontWeight.w600
                        ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down, 
                  color: (_isLoadingUserData || !_isAuthenticated) ? Colors.white.withOpacity(0.3) : Colors.white, 
                  size: 18
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSystem() {
    return Consumer<LoyaltyProvider>(
      builder: (context, loyaltyProvider, child) {
        final currentOrders = loyaltyProvider.completedOrders;
        const totalOrders = 5; // Need 5 orders to get 6th free
        final double progress = currentOrders / totalOrders;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: luxuryGold.withOpacity(0.2),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Reward System',
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                _refreshLoyaltyProgress();
                              },
                              child: Icon(
                                Icons.refresh,
                                size: 16,
                                color: loyaltyProvider.isLoading 
                                  ? luxuryGold.withOpacity(0.5)
                                  : luxuryGold.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Collect orders to earn free service',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: luxuryGold.withOpacity(0.15),
                      border: Border.all(
                        color: luxuryGold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '6th FREE',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: luxuryGold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 18),
              
              // Progress Section
              Row(
                children: [
                  // Progress Bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$currentOrders of $totalOrders orders',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: luxuryGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(luxuryGold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFindServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find services',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildServiceCard('Tailor', Icons.content_cut, false),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildServiceCard('Dry Cleaning', Icons.local_laundry_service, false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(String title, IconData icon, bool isSelected) {
    final bool isPressed = _pressedCard == title;
    final bool showGoldenTouch = isSelected || isPressed;
    
    return GestureDetector(
      onTapDown: (_) => _onCardTapDown(title),
      onTapUp: (_) => _onCardTapUp(title),
      onTapCancel: _onCardTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isPressed ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: showGoldenTouch ? luxuryGold : luxuryGold.withOpacity(0.2),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: showGoldenTouch
                      ? [
                          luxuryGold.withOpacity(0.08),
                          luxuryGold.withOpacity(0.03),
                        ]
                      : [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: showGoldenTouch
                          ? luxuryGold.withOpacity(0.15)
                          : luxuryGold.withOpacity(0.05),
                      border: Border.all(
                        color: showGoldenTouch ? luxuryGold : luxuryGold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: showGoldenTouch ? luxuryGold : luxuryGold.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: showGoldenTouch ? luxuryGold : Colors.white.withOpacity(0.9),
                      letterSpacing: 0.3,
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

  TextSpan _buildTextSpan(String text, Color color, FontWeight weight) {
    return TextSpan(
      text: text,
      style: GoogleFonts.lato(
        fontSize: 18,
        color: color,
        fontWeight: weight,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.5,
      ),
    );
  }

  TextSpan _buildTitleSpan(String text, Color color, FontWeight weight) {
    return TextSpan(
      text: text,
      style: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: weight,
        color: color,
        height: 1.1,
      ),
    );
  }

  Text _buildLocationText(String text, Color color, double size, FontWeight weight) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: size,
        color: color,
        fontWeight: weight,
      ),
    );
  }
} 