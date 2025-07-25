import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/bottom_navigation_component.dart';
import '../components/custom_toast.dart';
import '../components/email_input_component.dart';
import '../providers/navigation_provider.dart';
import '../services/auth_service.dart';
import '../services/user_location_service.dart';
import '../utils/validation_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '';
  String email = '';
  String phone = '';
  String password = '';
  String confirmPassword = '';
  bool isObscure = true;
  bool isConfirmObscure = true;
  static const Color luxuryGold = Color(0xFFE8D26D);

  @override
  void initState() {
    super.initState();
    // Set current screen when entering RegisterScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          Provider.of<NavigationProvider>(context, listen: false).setCurrentScreen('Profile');
        } catch (e) {
          // Handle overlay not available error silently
          print('Navigation provider not available: $e');
        }
      }
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
              // Welcome text
              _buildWelcomeText(),
              const SizedBox(height: 24),
              // Register form - takes remaining space
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name field
                        _buildInputField(
                          hintText: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                          onSaved: (value) => fullName = value ?? '',
                        ),
                        const SizedBox(height: 14),
                        // Email field
                        EmailInputComponent(
                          hintText: 'Email Address',
                          onSaved: (value) => email = value ?? '',
                        ),
                        const SizedBox(height: 14),
                        // Phone field
                        _buildInputField(
                          hintText: 'Phone Number',
                          icon: Icons.phone_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                          onSaved: (value) => phone = value ?? '',
                        ),
                        const SizedBox(height: 14),
                        // Password field
                        _buildPasswordField(),
                        const SizedBox(height: 14),
                        // Confirm Password field
                        _buildConfirmPasswordField(),
                        const SizedBox(height: 24),
                        // Register button
                        _buildRegisterButton(),
                        const SizedBox(height: 20),
                        // Login section
                        _buildLoginSection(),
                        const SizedBox(height: 32),
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
                text: 'Create your ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: 'Account',
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
        const SizedBox(height: 8),
        Text(
          'Join House of Tailors for premium services',
          style: GoogleFonts.lato(
            fontSize: 14,
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
      hintText: 'Password',
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
      onSaved: (value) => password = value ?? '',
    );
  }

  Widget _buildConfirmPasswordField() {
    return _buildInputField(
      hintText: 'Confirm Password',
      icon: Icons.lock_outline,
      obscureText: isConfirmObscure,
      suffixIcon: IconButton(
        icon: Icon(
          isConfirmObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: luxuryGold.withOpacity(0.7),
          size: 20,
        ),
        onPressed: () {
          setState(() {
            isConfirmObscure = !isConfirmObscure;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != password) {
          return 'Passwords do not match';
        }
        return null;
      },
      onSaved: (value) => confirmPassword = value ?? '',
    );
  }

  Widget _buildRegisterButton() {
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
                  
          // Validate all fields using ValidationUtils
          final nameError = ValidationUtils.getNameError(fullName);
          if (nameError != null) {
            CustomToast.showError(context, nameError);
            return;
          }
          
          final emailError = ValidationUtils.getEmailError(email);
          if (emailError != null) {
            CustomToast.showError(context, emailError);
            return;
          }
          
          final phoneError = ValidationUtils.getPhoneError(phone);
          if (phoneError != null) {
            CustomToast.showError(context, phoneError);
            return;
          }
          
          final passwordError = ValidationUtils.getPasswordError(password);
          if (passwordError != null) {
            CustomToast.showError(context, passwordError);
            return;
          }
          
          final confirmPasswordError = ValidationUtils.getConfirmPasswordError(password, confirmPassword);
          if (confirmPasswordError != null) {
            CustomToast.showError(context, confirmPasswordError);
            return;
          }
          
          // Perform registration
          final authService = Provider.of<AuthService>(context, listen: false);
          final success = await authService.register(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            // Location will be set later when user selects it
          );

          if (success) {
            CustomToast.showSuccess(context, 'Registration successful! Please login to continue.');
            // Navigate to login screen
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            // Show error message and stay on registration screen
            final errorMsg = authService.errorMessage ?? 'Registration failed';
            CustomToast.showError(context, errorMsg);
            // Do not navigate away - let user try again with different email
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
          'Create Account',
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

  Widget _buildLoginSection() {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Already have an account? ",
              style: GoogleFonts.lato(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  'Sign In',
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