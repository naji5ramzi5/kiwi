import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/pos_orders_controller.dart';
import '../widgets/window_controls.dart';
import 'orders/delivery_orders_screen.dart';
import 'inventory/inventory_screen.dart';
import 'cashier_screen.dart';
import 'purchases/purchases_screen.dart';
import 'statistics_screen.dart';
import '../features/settings/settings_page.dart';
import 'stock_entry.dart';
import 'price_checker_screen.dart';
import 'delivery_employees_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _checkFullscreen();
  }

  Future<void> _checkFullscreen() async {
    try {
      final isFull = await windowManager.isFullScreen();
      if (mounted) setState(() => _isFullscreen = isFull);
    } catch (_) {}
  }

  Future<void> _toggleFullscreen() async {
    try {
      if (_isFullscreen) {
        await windowManager.setFullScreen(false);
      } else {
        await windowManager.setFullScreen(true);
      }
      setState(() => _isFullscreen = !_isFullscreen);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.put(DashboardController());
    final AuthController authController = Get.find<AuthController>();
    Get.put(InventoryController());

    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          SingleActivator(LogicalKeyboardKey.f11): _toggleFullscreen,
          SingleActivator(LogicalKeyboardKey.escape): () async {
            if (_isFullscreen) {
              await windowManager.setFullScreen(false);
              setState(() => _isFullscreen = false);
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              const WindowControls(),
              Expanded(
                child: Row(
                  children: [
                    // Sidebar
                    Container(
                      width: 280,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.sidebarGradient,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // Logo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: AppTheme.primary.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        LucideIcons.store,
                                        color: AppTheme.primaryLight,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kiwi-pos',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'نظام إدارة الفرع',
                                        style: TextStyle(
                                          color: AppTheme.primaryLight,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Navigation items
                          _buildNavItem(0, LucideIcons.monitor, 'شاشة الكاشير', controller),
                          _buildNavItem(1, LucideIcons.shoppingBag, 'طلبات التوصيل', controller),
                          _buildNavItem(8, LucideIcons.truck, 'مناديب التوصيل', controller),
                          _buildNavItem(2, LucideIcons.package, 'إدارة المخزون', controller),
                          _buildNavItem(3, LucideIcons.box, 'إدخال المخزون', controller),
                          _buildNavItem(4, LucideIcons.truck, 'المشتريات', controller),
                          _buildNavItem(5, LucideIcons.barChart3, 'الإحصائيات', controller),
                          _buildNavItem(6, LucideIcons.settings, 'إعدادات الأجهزة', controller),
                          _buildNavItem(7, LucideIcons.scan, 'Price Checker', controller),

                          const Spacer(),

                          // Fullscreen toggle
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: _toggleFullscreen,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isFullscreen ? LucideIcons.minimize2 : LucideIcons.maximize2,
                                      color: AppTheme.primaryLight,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isFullscreen ? 'خروج من ملء الشاشة' : 'شاشة كاملة (F11)',
                                      style: const TextStyle(
                                        color: AppTheme.primaryLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Branch info + Delivery count + Logout
                          Obx(() => Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary.withOpacity(0.15),
                                  AppTheme.primary.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        LucideIcons.store,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            authController.currentBranchName.value,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'مسؤول الفرع',
                                            style: TextStyle(
                                              color: AppTheme.primaryLight.withOpacity(0.8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: IconButton(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('تسجيل الخروج'),
                                              content: const Text('هل تريد تسجيل الخروج والانتقال لفرع آخر؟'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red))),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            authController.logout();
                                          }
                                        },
                                        icon: const Icon(
                                          LucideIcons.logOut,
                                          color: AppTheme.primaryLight,
                                          size: 18,
                                        ),
                                        tooltip: 'تسجيل الخروج',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Delivery employees count
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.truck, color: AppTheme.primaryLight, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'مناديب التوصيل',
                                        style: TextStyle(
                                          color: AppTheme.primaryLight.withOpacity(0.9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Obx(() {
                                          final count = Get.find<DashboardController>().deliveryCount.value;
                                          return Text(
                                            '$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // Main content
                    Expanded(
                      child: Obx(() {
                        switch (controller.selectedIndex.value) {
                          case 0:
                            return const CashierScreen();
                          case 1:
                            return const DeliveryOrdersScreen();
                          case 2:
                            return const InventoryScreen();
                          case 3:
                            return const StockEntryScreen();
                          case 4:
                            return const PurchasesScreen();
                          case 5:
                            return const StatisticsScreen();
                          case 6:
                            return const SettingsPage();
                          case 7:
                            return const PriceCheckerScreen();
                          case 8:
                            return const DeliveryEmployeesScreen();
                          default:
                            return const Center(
                              child: Text(
                                'جاري العمل على هذه الشاشة...',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
                              ),
                            );
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, DashboardController controller) {
    return Obx(() {
      final isSelected = controller.selectedIndex.value == index;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.changeTabIndex(index),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? AppTheme.primaryLight : Colors.grey[500],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (index == 1)
                    Obx(() {
                      final count = Get.find<POSOrdersController>().pendingCount.value;
                      if (count == 0) return const SizedBox();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
