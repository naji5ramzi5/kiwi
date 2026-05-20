import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../order_tracking_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('profile'.tr),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // User Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryLight,
                      ),
                      child: const Center(
                        child: Text(
                          'أ',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'أحمد محمود',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '+964 770 123 4567',
                            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.edit2, size: 18, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Orders & Tracking Section
              Text(
                'my_orders'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListTile(LucideIcons.mapPin, 'track_order'.tr, onTap: () {}),
                    _buildDivider(),
                    _buildListTile(LucideIcons.clock, 'previous_orders'.tr, onTap: () {}),
                    _buildDivider(),
                    _buildListTile(LucideIcons.xCircle, 'cancelled_orders'.tr, onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Section
              Text(
                'الإعدادات والتفضيلات',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListTile(LucideIcons.heart, 'favorites'.tr, onTap: () {}),
                    _buildDivider(),
                    _buildListTile(LucideIcons.moon, 'dark_mode'.tr, trailing: Switch(value: false, onChanged: (v){}, activeColor: AppTheme.primary)),
                    _buildDivider(),
                    _buildListTile(LucideIcons.globe, 'language'.tr, trailing: const Text('العربية', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Support & About Section
              Text(
                'الدعم والمعلومات',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListTile(LucideIcons.headphones, 'support'.tr, onTap: () {}),
                    _buildDivider(),
                    _buildListTile(LucideIcons.info, 'about_app'.tr, onTap: () {}),
                    _buildDivider(),
                    _buildListTile(LucideIcons.shield, 'privacy'.tr, onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.logOut, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'logout'.tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Hidden/Discreet Delete Account (App Store requirement)
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Text(
                    'delete_account'.tr,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, decoration: TextDecoration.underline),
                  ),
                ),
              ),
              
              const SizedBox(height: 120), // Padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      ),
      trailing: trailing ?? const Icon(LucideIcons.chevronLeft, size: 18, color: AppTheme.textSecondary),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade100, indent: 64);
  }
}
