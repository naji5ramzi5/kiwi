import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
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
import 'location_picker_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'order_details_screen.dart';

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

  // Notification badge (simulated — connect to Supabase later)
  final RxBool hasNewNotification = true.obs;
  final RxInt notificationCount = 2.obs;

  void _showNotifications(BuildContext context) {
    hasNewNotification.value = false;
    notificationCount.value = 0;
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
          Get.snackbar('خروج', 'اضغط مرتين للخروج', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 1));
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
                  Get.to(() => const SearchScreen(), transition: Transition.fadeIn);
                },
              ),
              // Location bar moved to body for scrollability
              actions: [
                GestureDetector(
                  onTap: () => _showNotifications(context),
                  child: Obx(() => Stack(
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
                      )),
                )
              ],
            ),
          ],
          body: SingleChildScrollView(
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
    );
  }

  // ── Kiwi Title with curved arc ──
  Widget _buildKiwiTitle(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Kiwi',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF22C55E),
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
              colors: [Color(0xFF22C55E), Colors.transparent],
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
        onTap: () => Get.to(() => OrderDetailsScreen(orderId: activeId), transition: Transition.fadeIn),
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withOpacity(0.4),
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
                child: const Icon(LucideIcons.truck, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لديك طلب نشط',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900,
                        color: Colors.white, fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'اضغط لتتبع طلبك',
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
                child: const Icon(LucideIcons.arrowLeft, size: 16, color: Colors.white),
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
            : (controller.selectedBranch.value?['name']?.toString() ?? 'الموقع الحالي');
        final bool inZone = controller.isInDeliveryZone.value;

        return GestureDetector(
          onTap: () => _showLocationBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B5E20).withOpacity(0.25) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.green.shade100,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(LucideIcons.mapPin, size: 16, color: AppTheme.primary),
                    if (!inZone)
                      Positioned(
                        top: -2, right: -2,
                        child: Container(
                          width: 7, height: 7,
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
                      color: inZone ? (isDark ? const Color(0xFF4ADE80) : AppTheme.primaryDark) : Colors.red.shade400,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(LucideIcons.chevronDown, size: 14, color: inZone ? AppTheme.primary : Colors.red.shade400),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showLocationBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;
    final surfaceColor = isDark ? AppTheme.surfaceDark : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Obx(() {
            final String userLocation = controller.userAddress.value.isNotEmpty
                ? controller.userAddress.value
                : (controller.selectedBranch.value?['address'] ?? 'توصيل إلى موقعك');
            final bool inZone = controller.isInDeliveryZone.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'موقع التوصيل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: themeTextColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Current location card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: const Icon(LucideIcons.mapPin, size: 20, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الموقع الحالي', style: TextStyle(fontSize: 11, color: themeTextSecColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(userLocation, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: themeTextColor, fontFamily: 'Cairo'),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: inZone ? AppTheme.primary.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(inZone ? LucideIcons.checkCircle : LucideIcons.xCircle,
                          size: 16, color: inZone ? AppTheme.primary : Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Delivery status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: inZone ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(inZone ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                          size: 16, color: inZone ? AppTheme.primary : Colors.red.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            inZone ? 'التوصيل متاح في منطقتك' : 'التوصيل غير متاح في منطقتك حالياً',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: inZone ? AppTheme.primaryDark : Colors.red.shade700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final result = await Get.to(() => const LocationPickerScreen(), transition: Transition.fadeIn);
                            if (result != null && result is Map<String, dynamic>) {
                              await controller.updateUserLocation(result['latitude'], result['longitude'], result['address']);
                            }
                          },
                          icon: const Icon(LucideIcons.map, size: 16),
                          label: const Text('اختيار من الخريطة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await controller.findBestBranchByLocation();
                          },
                          icon: const Icon(LucideIcons.navigation, size: 16),
                          label: const Text('استخدام الموقع الحالي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildTruckOrderBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => Get.to(() => TruckOrderScreen()),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF388E3C)])
                : const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.12),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/delivery_truck.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(LucideIcons.truck, color: isDark ? Colors.green.shade300 : AppTheme.primaryDark, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اطلب شاحنة توصيل',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.green.shade200 : AppTheme.primaryDark,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'توصيل مباشر للطلبات الكبيرة',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.green.shade200.withOpacity(0.7) : AppTheme.primaryDark.withOpacity(0.7),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.green.shade300 : AppTheme.primaryDark, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

