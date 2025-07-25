import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../components/bottom_navigation_component.dart';
import '../components/custom_toast.dart';
import 'edit_profile_screen.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  static const Color luxuryGold = Color(0xFFE8D26D);
  
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Key _profileKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Image.asset(
              'assets/images/logo-main.png',
              width: 190,
              height: 95,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.business, color: ProfileScreen.luxuryGold, size: 30),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Profile Photo Section
                            _buildProfilePhoto(context),
                            const SizedBox(height: 20),
                            // User Info Section
                            _buildUserInfo(context),
                            const SizedBox(height: 32),
                            // Menu Items - Expanded to take available space
                            Column(
                              children: [
                                _buildMenuItem(
                                  icon: Icons.phone_outlined,
                                  title: 'Contact Us',
                                  onTap: () {
                                    // Handle contact tap
                                  },
                                ),
                                _buildMenuItem(
                                  icon: Icons.privacy_tip_outlined,
                                  title: 'Privacy Policy',
                                  onTap: () {
                                    // Handle privacy policy tap
                                  },
                                ),
                                _buildMenuItem(
                                  icon: Icons.description_outlined,
                                  title: 'Terms And Conditions',
                                  onTap: () {
                                    // Handle terms tap
                                  },
                                ),
                                _buildMenuItem(
                                  icon: Icons.logout,
                                  title: 'Logout',
                                  onTap: () async {
                                    final authService = Provider.of<AuthService>(context, listen: false);
                                    await authService.logout();
                                    if (context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                                      CustomToast.showSuccess(context, 'Logged out successfully');
                                    }
                                  },
                                  isDestructive: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const BottomNavigationComponent(),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUser;
        
        return FutureBuilder<String?>(
          key: _profileKey,
          future: authService.getUserAvatarUrl(),
          builder: (context, snapshot) {
            final String? base64Image = snapshot.data;
            final hasProfilePhoto = base64Image != null && base64Image.isNotEmpty;

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
                        ProfileScreen.luxuryGold.withOpacity(0.2),
                        ProfileScreen.luxuryGold.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: ProfileScreen.luxuryGold.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: hasProfilePhoto
                        ? Image.memory(
                            base64Decode(base64Image!.split(',')[1]),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultLogo(),
                          )
                        : _buildDefaultLogo(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ProfileScreen.luxuryGold,
                      boxShadow: [
                        BoxShadow(
                          color: ProfileScreen.luxuryGold.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1A1A1A)),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        // Refresh the profile after returning from edit
                        setState(() {
                          _profileKey = UniqueKey();
                        });
                      },
                    ),
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

  Widget _buildUserInfo(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUser;
        final fullName = user?.displayName ?? 'Guest User';
        final email = user?.email ?? '';

        return Column(
          children: [
            Text(
              fullName,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                color: ProfileScreen.luxuryGold,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ProfileScreen.luxuryGold.withOpacity(0.2),
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
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: ProfileScreen.luxuryGold.withOpacity(0.7),
          size: 24,
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: ProfileScreen.luxuryGold.withOpacity(0.7),
          size: 24,
        ),
      ),
    );
  }
} 