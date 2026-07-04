import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../controllers/cart_controller.dart';
import '../controllers/main_screen_controller.dart';
import 'home_screen.dart';
import 'profile/profile_screen.dart';
import 'cart/cart_screen.dart';
import 'categories/categories_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MainScreenController nav = Get.put(MainScreenController());

  final List<Widget> _pages = [
    HomeScreen(),
    const CategoriesScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Obx(() => Scaffold(
      extendBody: true,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: IndexedStack(
              index: nav.currentIndex.value,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildFloatingIslandNavBar(),
    ));
  }

  Widget _buildSidebar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.leaf, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text('Kiwi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(0, LucideIcons.home, 'home'.tr),
          _buildSidebarItem(1, LucideIcons.layoutGrid, 'categories'.tr),
          _buildSidebarItem(2, LucideIcons.shoppingCart, 'cart'.tr, isCart: true),
          _buildSidebarItem(3, LucideIcons.user, 'profile'.tr),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, {bool isCart = false}) {
    final isSelected = nav.currentIndex.value == index;
    final CartController cartController = Get.find<CartController>();
    return GestureDetector(
      onTap: () => nav.switchTab(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Obx(() {
              final count = cartController.itemCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: isSelected ? const Color(0xFF047857) : Colors.grey[400], size: 22),
                  if (isCart && count > 0)
                    Positioned(
                      top: -6, right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: isSelected ? const Color(0xFF064E3B) : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIslandNavBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.fromLTRB(width * 0.05, 0, width * 0.05, width * 0.06),
      height: width * 0.18,
      padding: EdgeInsets.symmetric(horizontal: width * 0.02),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(width * 0.09),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
            blurRadius: width * 0.05,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'الرئيسية', width),
          _buildNavItem(1, Icons.category_rounded, 'الأقسام', width),
          _buildNavItem(2, Icons.shopping_cart_rounded, 'السلة', width, isCart: true),
          _buildNavItem(3, Icons.person_rounded, 'حسابي', width),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, double screenWidth, {bool isCart = false}) {
    final isSelected = nav.currentIndex.value == index;
    final CartController cartController = Get.find<CartController>();

    return GestureDetector(
      onTap: () => nav.switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutBack,
        width: isSelected ? screenWidth * 0.28 : screenWidth * 0.12,
        height: screenWidth * 0.11,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(screenWidth * 0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() {
              final count = cartController.itemCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.green : Colors.grey.withOpacity(0.6),
                    size: isSelected ? screenWidth * 0.06 : screenWidth * 0.055,
                  ),
                  if (isCart && count > 0)
                    Positioned(
                      top: -6, right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).cardColor, width: 2),
                        ),
                        constraints: BoxConstraints(
                          minWidth: screenWidth * 0.04,
                          minHeight: screenWidth * 0.04,
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.022,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            }),
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 400),
                alignment: Alignment.centerLeft,
                widthFactor: isSelected ? 1.0 : 0.0,
                child: Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.015),
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.03,
                    ),
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
