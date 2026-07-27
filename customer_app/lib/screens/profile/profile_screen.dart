import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import '../../theme/app_theme.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/main_screen_controller.dart';
import '../order_tracking_map_screen.dart';
import '../order_details_screen.dart';
import '../auth/login_screen.dart';
import '../favorites_screen.dart';
import '../orders_list_screen.dart';
import 'support_screen.dart';
import 'legal_pages.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use find with fallback to avoid crash if not registered yet
    final ThemeController themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController());
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final surfaceColor = isDark ? AppTheme.surfaceDark : Colors.white;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('profile'.tr, style: TextStyle(color: textColor)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              
              // Premium User Info Card
              Obx(() {
                final isLoggedIn = authController.currentUser.value != null;
                final profile = authController.userProfile();
                final name = isLoggedIn
                    ? (profile['full_name']?.toString() ?? 'default_user_name'.tr)
                    : 'default_user_name'.tr;
                final phone = isLoggedIn
                    ? (profile['phone']?.toString() ?? '')
                    : 'login_to_enjoy'.tr;
                final avatarInit =
                    name.isNotEmpty ? name[0].toUpperCase() : 'F';

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLoggedIn
                          ? [AppTheme.primary, AppTheme.primaryVeryLight]
                          : [AppTheme.primaryDark, AppTheme.primaryBright],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            avatarInit,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'Cairo'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLoggedIn ? phone : 'login_to_enjoy'.tr,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                      if (!isLoggedIn)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                            onPressed: () => Get.to(() => const LoginScreen()),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(LucideIcons.settings, color: Colors.white.withOpacity(0.8), size: 20),
                            onPressed: () => Get.to(() => const EditProfileScreen(), transition: Transition.fadeIn),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),

              // Quick Stats Row
              Obx(() {
                if (authController.currentUser.value == null) return const SizedBox.shrink();
                final FavoritesController favController = Get.find<FavoritesController>();
                return FutureBuilder<int>(
                  future: _getOrderCount(),
                  builder: (context, snapshot) {
                    final orderCount = snapshot.data ?? 0;
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('stat_orders'.tr, orderCount.toString(), LucideIcons.shoppingBag, textColor, textSecColor, surfaceColor, isDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('stat_favorites'.tr, favController.favoriteProductIds.length.toString(), LucideIcons.heart, textColor, textSecColor, surfaceColor, isDark),
                        ),
                      ],
                    );
                  },
                );
              }),
              if (authController.currentUser.value != null) const SizedBox(height: 28),

              // Section: My Orders
              _buildSectionHeader('my_orders'.tr, LucideIcons.truck, textColor),
              const SizedBox(height: 12),
              _buildMenuCard([
                _menuItem(LucideIcons.mapPin, 'track_order'.tr, () => _openActiveOrderTracking(context), iconBg: bgColor, iconFg: textColor, txtColor: textColor, arrowColor: textSecColor),
                _menuItem(LucideIcons.clock, 'active_orders'.tr, () => Get.to(() => OrdersListScreen(), transition: Transition.fadeIn), iconBg: bgColor, iconFg: textColor, txtColor: textColor, arrowColor: textSecColor),
                _menuItem(LucideIcons.packageCheck, 'previous_orders'.tr, () => Get.to(() => OrdersListScreen(filterStatus: 'delivered'), transition: Transition.fadeIn), iconBg: bgColor, iconFg: textColor, txtColor: textColor, arrowColor: textSecColor),
                _menuItem(LucideIcons.xCircle, 'cancelled_orders'.tr, () => Get.to(() => OrdersListScreen(filterStatus: 'cancelled'), transition: Transition.fadeIn), iconBg: bgColor, iconFg: textColor, txtColor: textColor, arrowColor: textSecColor),
              ], surfaceColor, textColor, textSecColor, bgColor, isDark),
              const SizedBox(height: 24),

              // Section: Settings
              _buildSectionHeader('settings'.tr, LucideIcons.settings, textColor),
              const SizedBox(height: 12),
              _buildMenuCard([
                _menuItem(LucideIcons.heart, 'favorites'.tr, () => Get.to(() => FavoritesScreen(), transition: Transition.fadeIn), iconBg: bgColor, iconFg: textColor, txtColor: textColor, arrowColor: textSecColor),
                _menuItemWithWidget(LucideIcons.moon, 'dark_mode'.tr, 
                  Switch(value: themeController.isDarkMode.value, onChanged: (v) => themeController.toggleTheme(), activeColor: AppTheme.primary),
                  () {}
                ),
                _buildLanguageToggle(textColor, textSecColor, isDark),
              ], surfaceColor, textColor, textSecColor, bgColor, isDark),
              const SizedBox(height: 24),

              // Section: Support
              _buildSectionHeader('support'.tr, LucideIcons.headphones, textColor),
              const SizedBox(height: 12),
              _buildMenuCard([
                _menuItem(LucideIcons.headphones, 'support'.tr, () => Get.to(() => const SupportScreen(), transition: Transition.fadeIn), iconBg: bgColor, iconFg: textColor, txtColor: textColor, arrowColor: textSecColor),
                _menuItem(LucideIcons.info, 'about_app'.tr, () => Get.to(() => const AboutAppScreen(), transition: Transition.fadeIn), iconBg: bgColor, iconFg: textColor, txtColor: textColor, arrowColor: textSecColor),
                _menuItem(LucideIcons.shield, 'privacy'.tr, () => Get.to(() => const PrivacyPolicyScreen(), transition: Transition.fadeIn), iconBg: bgColor, iconFg: textColor, txtColor: textColor, arrowColor: textSecColor),
              ], surfaceColor, textColor, textSecColor, bgColor, isDark),
              const SizedBox(height: 24),

              // Logout
              Obx(() {
                if (authController.currentUser.value == null) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => authController.logout(),
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
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Hidden Delete Account
              Center(
                child: GestureDetector(
                  onTap: () => _showDeleteAccountDialog(context, authController),
                  child: Text(
                    'delete_account'.tr,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color textColor, Color textSecColor, Color surfaceColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppTheme.primary),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: textSecColor, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildMenuCard(List<Widget> items, Color surfaceColor, Color textColor, Color textSecColor, Color bgColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback? onTap, {Widget? trailing, Color? iconBg, Color? iconFg, Color? txtColor, Color? arrowColor}) {
    final bg = iconBg ?? (Get.isDarkMode ? AppTheme.surfaceDark : Colors.grey.shade50);
    final fg = iconFg ?? (Get.isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary);
    final tc = txtColor ?? (Get.isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary);
    final ac = arrowColor ?? (Get.isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: fg),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tc, fontFamily: 'Cairo')),
      trailing: trailing ?? Icon(LucideIcons.chevronLeft, size: 18, color: ac),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<int> _getOrderCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 0;
      final data = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('customer_id', userId);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  void _openActiveOrderTracking(BuildContext context) async {
    final cartController = Get.find<CartController>();
    await cartController.refreshActiveOrder();
    final activeId = cartController.activeOrderId.value;
    if (activeId != null) {
      Get.to(() => OrderTrackingMapScreen(orderId: activeId), transition: Transition.fadeIn);
    } else {
      Get.snackbar('no_active_order'.tr, 'no_order_in_delivery'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Widget _menuItemWithWidget(IconData icon, String title, Widget trailing, VoidCallback? onTap) {
    final isDark = Get.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E291F) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(Color textColor, Color textSecColor, bool isDark) {
    return _menuItemWithWidget(
      LucideIcons.globe,
      'language'.tr,
      Obx(() {
        final isArabic = Get.locale?.languageCode != 'en';
        return SizedBox(
          width: 110,
          height: 36,
          child: GestureDetector(
            onTap: () => _toggleLanguage(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isArabic ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'عربي',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isArabic ? Colors.white : textSecColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: !isArabic ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'EN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: !isArabic ? Colors.white : textSecColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      null,
    );
  }

  void _toggleLanguage() {
    final isArabic = Get.locale?.languageCode != 'en';
    if (isArabic) {
      Get.updateLocale(const Locale('en', 'US'));
      GetStorage().write('app_locale', 'en');
    } else {
      Get.updateLocale(const Locale('ar', 'IQ'));
      GetStorage().write('app_locale', 'ar');
    }
    if (Get.isRegistered<MainScreenController>()) {
      Get.find<MainScreenController>().refreshLocale();
    }
  }

  void _showDeleteAccountDialog(BuildContext context, AuthController authController) {
    Get.defaultDialog(
      title: 'delete_account'.tr,
      middleText: 'delete_account_msg'.tr,
      textConfirm: 'agree'.tr,
      textCancel: 'go_back'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          await authController.deleteAccount();
          Get.snackbar(
            'account_deletion_request'.tr,
            'logged_out_contact_support'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
          Get.offAll(() => const LoginScreen());
        } catch (e) {
          Get.snackbar(
            'error'.tr,
            'logout_failed'.trParams({'error': e.toString()}),
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        }
      },
    );
  }
}
