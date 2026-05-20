import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'profile/profile_screen.dart';
import 'cart/cart_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    const Center(child: Text('الأقسام')),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      extendBody: true,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildFloatingIslandNavBar(),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
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
                const Text('FRESH', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(0, LucideIcons.home, 'home'.tr),
          _buildSidebarItem(1, LucideIcons.layoutGrid, 'categories'.tr),
          _buildSidebarItem(2, LucideIcons.shoppingCart, 'cart'.tr),
          _buildSidebarItem(3, LucideIcons.user, 'profile'.tr),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF047857) : Colors.grey[400], size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: isSelected ? const Color(0xFF064E3B) : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIslandNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: const Color(0xFFF2FDF5).withOpacity(0.95), // White slightly greenish (Mint off-white)
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF10B981).withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, LucideIcons.home, 'الرئيسية'),
                _buildNavItem(1, LucideIcons.layoutGrid, 'الأقسام'),
                _buildNavItem(2, LucideIcons.shoppingCart, 'السلة'),
                _buildNavItem(3, LucideIcons.user, 'حسابي'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF064E3B).withOpacity(0.4), size: 22),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ]
          ],
        ),
      ),
    );
  }
}
