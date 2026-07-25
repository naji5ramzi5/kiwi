import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../controllers/home_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/auth_controller.dart';
import 'home/widgets/stories_section.dart';
import 'home/widgets/banners_section.dart';
import 'home/widgets/categories_section.dart';
import 'home/widgets/products_section.dart';
import 'home/widgets/offers_section.dart';
import 'truck_order_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'order_details_screen.dart';
import 'widgets/location_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _lastBackPress;
  final HomeController controller = Get.find<HomeController>();
  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final RxBool hasNewNotification = false.obs;
  final RxInt notificationCount = 0.obs;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      final int unreadCount = (data as List).length;

      final prefs = await SharedPreferences.getInstance();
      final int lastSeenCount = prefs.getInt('last_seen_notification_count') ?? 0;

      notificationCount.value = unreadCount;
      hasNewNotification.value = unreadCount > 0 && unreadCount != lastSeenCount;
    } catch (_) {
      notificationCount.value = 0;
      hasNewNotification.value = false;
    }
  }

  void _showNotifications(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_seen_notification_count', notificationCount.value);
    hasNewNotification.value = false;
    Get.to(() => const NotificationsScreen(), transition: Transition.fadeIn);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (_lastBackPress == null || now - _lastBackPress! > 2000) {
          _lastBackPress = now;
          Get.snackbar(
            'exit_title'.tr,
            'exit_message'.tr,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 1),
          );
          return;
        }
        Get.closeAllSnackbars();
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        } else {
          Get.close(1);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: isDark
                  ? AppTheme.backgroundDark
                  : AppTheme.background,
              elevation: 0,
              titleSpacing: 0,
              toolbarHeight: 56,
              title: _buildKiwiTitle(isDark),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(LucideIcons.search, color: AppTheme.primary),
                onPressed: () {
                  Get.to(
                    () => const SearchScreen(),
                    transition: Transition.fadeIn,
                  );
                },
              ),
              // Location bar moved to body for scrollability
              actions: [
                GestureDetector(
                  onTap: () => _showNotifications(context),
                  child: Obx(
                    () => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.bell,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        if (hasNewNotification.value)
                          Positioned(
                            top: 0,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${notificationCount.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          body: RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
            onRefresh: () async {
              await controller.refreshAll();
              await _loadNotificationCount();
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationBar(context, isDark),
                  _buildActiveOrderBanner(context, isDark),
                  StoriesSection(),
                  const SizedBox(height: 12),
                  BannersSection(),
                  const SizedBox(height: 16),
                  _buildTruckOrderBanner(context, isDark),
                  const SizedBox(height: 16),
                  CategoriesSection(),
                  const SizedBox(height: 4),
                  OffersSection(),
                  const SizedBox(height: 16),
                  ProductsSection(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€ Kiwi Title with curved arc â”€â”€
  Widget _buildKiwiTitle(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Kiwi',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: isDark ? AppTheme.primaryBright : AppTheme.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 2),
        // Curved arc decoration
        Container(
          width: 42,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Colors.transparent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveOrderBanner(BuildContext context, bool isDark) {
    return Obx(() {
      final activeId = cartController.activeOrderId.value;
      if (activeId == null) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () => Get.to(
          () => OrderDetailsScreen(orderId: activeId),
          transition: Transition.fadeIn,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.truck,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'active_order_title'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'active_order_track'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLocationBar(BuildContext context, bool isDark) {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Obx(() {
        final String area = controller.userAddress.value.isNotEmpty
            ? controller.userAddress.value.split('،').first
            : (controller.selectedBranch.value?['name']?.toString() ??
                  'current_location_fallback'.tr);
        final bool inZone = controller.isInDeliveryZone.value;

        return GestureDetector(
          onTap: () => showLocationBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1B5E20).withOpacity(0.25)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.green.shade100,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    if (!inZone)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    area,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: inZone
                          ? (isDark
                                ? AppTheme.primaryBright
                                : AppTheme.primaryDark)
                          : Colors.red.shade400,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: inZone ? AppTheme.primary : Colors.red.shade400,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTruckOrderBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => Get.to(() => TruckOrderScreen()),
        child: Container(
          height: 130,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/kiwivr.png',
                  height: 130,
                  width: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 130,
                    height: 130,
                    color: AppTheme.primary.withOpacity(0.1),
                    child: Icon(LucideIcons.truck, color: AppTheme.primary, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'truck_order_title'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? Colors.green.shade200
                            : AppTheme.primaryDark,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'truck_order_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.green.shade200.withOpacity(0.7)
                            : AppTheme.primaryDark.withOpacity(0.7),
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: isDark
                      ? Colors.green.shade300
                      : AppTheme.primaryDark,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
