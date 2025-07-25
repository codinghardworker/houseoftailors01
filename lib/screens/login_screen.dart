import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/bottom_navigation_component.dart';
import '../components/custom_toast.dart';
import '../components/email_input_component.dart';
import '../providers/navigation_provider.dart';
import '../services/auth_service.dart';
import '../services/shop_config_service.dart';
import '../utils/validation_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  bool isObscure = true;
  static const Color luxuryGold = Color(0xFFE8D26D);

  @override
  void initState() {
    super.initState();
    // Set current screen when entering LoginScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationProvider>(context, listen: false).setCurrentScreen('Profile');
    });
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      bottomNavigationBar: const BottomNavigationComponent(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo at the top
              Image.asset(
                'assets/images/logo-main.png',
                width: 190,
                height: 95,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.business, color: luxuryGold, size: 30),
              ),
              const SizedBox(height: 40),
              // Welcome text
              _buildWelcomeText(),
              const SizedBox(height: 40),
              // Login form - takes remaining space
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username/Email field
                        EmailInputComponent(
                          hintText: 'Enter Email',
                          onSaved: (value) => username = value ?? '',
                        ),
                        const SizedBox(height: 18),
                        // Password field
                        _buildPasswordField(),
                        const SizedBox(height: 12),
                        const SizedBox(height: 32),
                        // Login button
                        _buildLoginButton(),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        // Register Now
                        _buildRegisterSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Welcome back to\n',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: 'House of Tailors',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  color: luxuryGold,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in to continue your premium experience',
          style: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

    Widget _buildInputField({
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
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
      child: TextFormField(
        style: GoogleFonts.lato(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: luxuryGold.withOpacity(0.7), size: 20),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: GoogleFonts.lato(
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w400,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          errorStyle: const TextStyle(height: 0, fontSize: 0, color: Colors.transparent),
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorMaxLines: 1,
          helperStyle: const TextStyle(height: 0, fontSize: 0),
          errorText: null,
        ),
        autovalidateMode: AutovalidateMode.disabled,
        obscureText: obscureText,
        validator: null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildPasswordField() {
    return _buildInputField(
      hintText: 'Enter Password',
      icon: Icons.lock_outline,
      obscureText: isObscure,
                              suffixIcon: IconButton(
                                icon: Icon(
          isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: luxuryGold.withOpacity(0.7),
          size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isObscure = !isObscure;
                                  });
                                },
                              ),
                            validator: (value) => null,
                            onSaved: (value) => password = value ?? '',
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            luxuryGold,
            luxuryGold.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: luxuryGold.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
                            ),
                          ),
            onPressed: authService.isLoading 
                ? null 
                : () async {
          _formKey.currentState?.save();
          
          // Validate inputs
          final emailError = ValidationUtils.getEmailError(username);
          if (emailError != null) {
            CustomToast.showError(context, emailError);
            return;
          }
          
          final passwordError = ValidationUtils.getPasswordError(password);
          if (passwordError != null) {
            CustomToast.showError(context, passwordError);
            return;
          }
          
          // Perform login using AuthService
          final authService = Provider.of<AuthService>(context, listen: false);
          final success = await authService.login(
            email: username,
            password: password,
          );
          
          if (success) {
            CustomToast.showSuccess(context, 'Login successful!');
            // Ensure shop config is fully initialized after successful login
            print('✅ Login: Successful login, ensuring full shop config initialization...');
            ShopConfigService.ensureInitialized();
            
            // Navigate to home screen
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else {
            final errorMsg = authService.errorMessage ?? 'Login failed';
            print('Login error message: "$errorMsg"'); // Debug log
            
            CustomToast.showError(context, errorMsg);
          }
        },
            child: authService.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                    ),
                  )
                : Text(
          'Sign In',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
            letterSpacing: 0.5,
                        ),
                      ),
                    ),
        );
      },
    );
  }


  Widget _buildRegisterSection() {
    return Center(
      child: RichText(
        text: TextSpan(
                      children: [
            TextSpan(
              text: "Don't have an account? ",
                          style: GoogleFonts.lato(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            WidgetSpan(
                            child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/register');
                },
                child: Text(
                  'Register Now',
                  style: GoogleFonts.lato(
                    color: luxuryGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: luxuryGold,
                  ),
                ),
              ),
            ),
          ],
          ),
      ),
    );
  }
} 