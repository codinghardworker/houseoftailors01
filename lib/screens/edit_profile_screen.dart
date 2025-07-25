import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../components/custom_toast.dart';
import '../components/bottom_navigation_component.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color luxuryGold = Color(0xFFE8D26D);
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _selectedImageBase64;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    _fullNameController = TextEditingController(
      text: user?.displayName ?? '',
    );
    _emailController = TextEditingController(
      text: user?.email ?? '',
    );
    _phoneController = TextEditingController();
    
    // Load phone number from Firestore
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final phone = await authService.getUserPhone();
    if (mounted) {
      _phoneController.text = phone;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isUploadingImage = true);
        
        // Read image as bytes and convert to Base64
        final bytes = await image.readAsBytes();
        
        final base64String = base64Encode(bytes);
        final mimeType = image.mimeType ?? 'image/jpeg';
        final base64Image = 'data:$mimeType;base64,$base64String';
        
        // Update profile picture
        final authService = Provider.of<AuthService>(context, listen: false);
        final success = await authService.updateProfilePicture(base64Image);
        
        if (success) {
          setState(() => _selectedImageBase64 = base64Image);
          if (mounted) {
            CustomToast.showSuccess(context, 'Profile picture updated successfully');
          }
        } else {
          if (mounted) {
            final errorMsg = authService.errorMessage ?? 'Failed to update profile picture';
            CustomToast.showError(context, errorMsg);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to pick image: ${e.toString()}');
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _removeImage() async {
    try {
      setState(() => _isUploadingImage = true);
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.removeProfilePicture();
      
      if (success) {
        setState(() => _selectedImageBase64 = null);
        if (mounted) {
          CustomToast.showSuccess(context, 'Profile picture removed successfully');
        }
      } else {
        if (mounted) {
          final errorMsg = authService.errorMessage ?? 'Failed to remove profile picture';
          CustomToast.showError(context, errorMsg);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to remove image: ${e.toString()}');
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      bottomNavigationBar: const BottomNavigationComponent(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const SizedBox(
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
                        ),
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Photo Section with options
                _buildProfilePhotoWithOptions(),
                const SizedBox(height: 32),
                // Form Fields
                _buildInputField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                // Email field with disabled style
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: luxuryGold.withOpacity(0.1),
                      width: 1.5,
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
                  child: TextFormField(
                    controller: _emailController,
                    enabled: false,
                    style: GoogleFonts.lato(
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: GoogleFonts.lato(
                        color: luxuryGold.withOpacity(0.4),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: luxuryGold.withOpacity(0.4),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _phoneController,
                  label: 'Mobile Number',
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 32),
                // Update Button
                _buildUpdateButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoWithOptions() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUser;
        
        return FutureBuilder<String?>(
          future: authService.getUserAvatarUrl(),
          builder: (context, snapshot) {
            // Use selected image if available, otherwise use fetched image
            final String? displayImage = _selectedImageBase64 ?? snapshot.data;
            final hasProfilePhoto = displayImage != null && displayImage.isNotEmpty;

            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        luxuryGold.withOpacity(0.2),
                        luxuryGold.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: luxuryGold.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _isUploadingImage
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(luxuryGold),
                              strokeWidth: 2,
                            ),
                          )
                        : hasProfilePhoto
                            ? Image.memory(
                                base64Decode(displayImage!.split(',')[1]),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildDefaultLogo(),
                              )
                            : _buildDefaultLogo(),
                  ),
                ),
                // Edit/Remove options
                if (!_isUploadingImage)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: luxuryGold,
                            boxShadow: [
                              BoxShadow(
                                color: luxuryGold.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1A1A1A)),
                            onPressed: _pickImage,
                          ),
                        ),
                        // Remove button (only show if has photo)
                        if (hasProfilePhoto)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.shade400,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white),
                              onPressed: _removeImage,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120, // Outer container size
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(
          width: 50, // Very small logo size
          height: 50,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.person_outline,
              size: 20,
              color: Color(0xFFE8D26D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
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
        controller: controller,
        enabled: enabled,
        style: GoogleFonts.lato(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lato(
            color: luxuryGold.withOpacity(0.7),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: luxuryGold.withOpacity(0.7), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return Container(
          width: double.infinity,
          height: 56,
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: authService.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final success = await authService.updateProfile(
                          fullName: _fullNameController.text.trim(),
                          phone: _phoneController.text.trim(),
                        );
                        
                        if (success) {
                          Navigator.pop(context);
                          CustomToast.showSuccess(context, 'Profile updated successfully');
                        } else {
                          CustomToast.showError(context, authService.errorMessage ?? 'Update failed');
                        }
                      }
                    },
              child: Center(
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
                        'Update',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
} 