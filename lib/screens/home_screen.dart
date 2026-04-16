import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';
import 'package:travel_pass/features/profile/screens/profile_screen.dart';
import 'package:travel_pass/main.dart';

class HomeScreen extends ConsumerWidget {
  final Map<String, dynamic>? userData;

  const HomeScreen({super.key, this.userData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);

    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Travel Pass',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Language Toggle Button
          PopupMenuButton<String>(
            onSelected: (language) {
              ref.read(languageProvider.notifier).setLanguage(language);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'en',
                      // ignore: deprecated_member_use
                      groupValue: locale,
                      // ignore: deprecated_member_use
                      onChanged: (_) {},
                    ),
                    const Text(
                      'English',
                      style: TextStyle(fontFamily: AppFonts.english),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'bn',
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'bn',
                      // ignore: deprecated_member_use
                      groupValue: locale,
                      // ignore: deprecated_member_use
                      onChanged: (_) {},
                    ),
                    const Text(
                      'বাংলা',
                      style: TextStyle(fontFamily: AppFonts.bengali),
                    ),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.language, color: Colors.white),
          ),
          // Profile Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              child: Tooltip(
                message: 'Profile',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Travel Pass!',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your account has been successfully verified. Enjoy exploring amazing travel destinations!',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        color: AppColors.textGrey,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Action Cards
              _buildActionCard(
                icon: Icons.map,
                title: 'Explore Destinations',
                subtitle: 'Browse amazing travel locations',
                font: font,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.bookmark,
                title: 'My Bookings',
                subtitle: 'View and manage your trips',
                font: font,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Edit your travel preferences',
                font: font,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // User Data Display (if available)
              if (userData != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Account',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Full Name: ${userData?['fullName'] ?? 'N/A'}',
                        style: TextStyle(fontFamily: font),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${userData?['email'] ?? 'N/A'}',
                        style: TextStyle(fontFamily: font),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tourist Type: ${userData?['touristType'] ?? 'N/A'}',
                        style: TextStyle(fontFamily: font),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(verificationStatusProvider.notifier)
                        .logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String font,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textGrey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
