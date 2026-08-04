import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/home_controller.dart';
import 'widgets/category_grid.dart';
import 'category_products_screen.dart';

/// Root-level Categories screen (Bottom Navigation tab).
///
/// Behaves exactly like Home / Cart / Profile:
/// - No Back button (it is a root screen, never navigates backward).
/// - Tapping a category pushes [CategoryProductsScreen] on the stack, so Back
///   returns to this screen naturally.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final HomeController homeController = Get.find<HomeController>();

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  final Map<String, IconData> categoryIcons = {
    'category_fruits'.tr: LucideIcons.apple,
    'category_vegetables'.tr: LucideIcons.leaf,
    'cat_meat_poultry'.tr: LucideIcons.beef,
    'cat_dairy'.tr: LucideIcons.milk,
    'cat_beverages'.tr: LucideIcons.wine,
    'cat_snacks'.tr: LucideIcons.cookie,
    'cat_grocery'.tr: LucideIcons.shoppingBag,
    'cat_oils_spices'.tr: LucideIcons.flaskConical,
    'cat_bakery'.tr: LucideIcons.wheat,
    'cat_cleaning'.tr: LucideIcons.sprayCan,
  };

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final cardBgColor = isDark ? const Color(0xFF1E291F) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        // Root screen: no Back button
        automaticallyImplyLeading: false,
        title: Text(
          'categories_title'.tr,
          style: TextStyle(
            color: themeTextColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            fontFamily: 'Cairo',
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (homeController.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        return CategoryGrid(
          homeController: homeController,
          categoryIcons: categoryIcons,
          searchController: searchController,
          searchQuery: searchQuery,
          isDark: isDark,
          themeTextColor: themeTextColor,
          themeTextSecColor: themeTextSecColor,
          cardBgColor: cardBgColor,
          onCategoryTap: (name) => Get.to(
            () => CategoryProductsScreen(category: name),
            transition: Transition.fadeIn,
          ),
        );
      }),
    );
  }
}
