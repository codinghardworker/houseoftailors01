import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class NavigationProvider with ChangeNotifier {
  String _currentScreen = 'Home';

  String get currentScreen => _currentScreen;

  void setCurrentScreen(String screen) {
    if (_currentScreen != screen) {
      _currentScreen = screen;
      notifyListeners();
    }
  }

  void handleNavigation(BuildContext context, String screenName) {
    // Update current screen state
    setCurrentScreen(screenName);
    
    // Handle actual navigation
    switch (screenName) {
      case 'Home':
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 'Orders':
        Navigator.pushNamedAndRemoveUntil(context, '/orders', (route) => false);
        break;
      case 'Tailor':
        Navigator.pushNamedAndRemoveUntil(context, '/tailor', (route) => false);
        break;
      case 'Basket':
        Navigator.pushNamedAndRemoveUntil(context, '/basket', (route) => false);
        break;
      case 'Dry Cleaning':
        // Dry cleaning icon only - no navigation
        break;
      case 'Profile':
        // Check authentication status and navigate accordingly
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.isLoggedIn) {
          Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        break;
      default:
        print('Unknown screen: $screenName');
    }
  }
}