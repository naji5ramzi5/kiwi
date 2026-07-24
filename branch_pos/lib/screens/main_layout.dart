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
import 'finance/settlement_screen.dart';
import 'settings/hardware_settings_screen.dart';
import 'stock_entry.dart';

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
                    Container(
                      width: 260,
                      color: AppTheme.sidebar,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        LucideIcons.store,
                                        color: AppTheme.primary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Kiwi Fresh',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          
                          _buildNavItem(0, LucideIcons.monitor, 'شاشة الكاشير', controller),
                          _buildNavItem(1, LucideIcons.shoppingBag, 'طلبات التوصيل', controller),
                          _buildNavItem(2, LucideIcons.package, 'إدارة المخزون', controller),
                          _buildNavItem(3, LucideIcons.box, 'إدخال المخزون', controller),
                          _buildNavItem(4, LucideIcons.truck, 'المشتريات', controller),
                          _buildNavItem(5, LucideIcons.barChart3, 'الإحصائيات', controller),
                          _buildNavItem(6, LucideIcons.settings, 'إعدادات الأجهزة', controller),
                          
                          const Spacer(),
                          
                          // Fullscreen toggle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Colors.white.withOpacity(0.03),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _toggleFullscreen,
                                  icon: Icon(
                                    _isFullscreen ? LucideIcons.minimize2 : LucideIcons.maximize2,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  tooltip: _isFullscreen ? 'إنهاء وضع الشاشة الكاملة' : 'شاشة كاملة (F11)',
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isFullscreen ? 'خروج من ملء الشاشة' : 'شاشة كاملة',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          
                          Obx(() => Container(
                            padding: const EdgeInsets.all(24),
                            color: Colors.white.withOpacity(0.03),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                                  child: const Icon(LucideIcons.store, color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        authController.currentBranchName.value, 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text('مسؤول الفرع', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => authController.logout(),
                                  icon: const Icon(LucideIcons.logOut, color: Colors.grey, size: 18),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    
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
                            return const SettlementScreen();
                          case 6:
                            return const HardwareSettingsScreen();
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
      return GestureDetector(
        onTap: () => controller.changeTabIndex(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primary : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (index == 1) ...[
                const Spacer(),
                Obx(() {
                  final count = Get.find<POSOrdersController>().pendingCount.value;
                  if (count == 0) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  );
                }),
              ],
            ],
          ),
        ),
      );
    });
  }

}
