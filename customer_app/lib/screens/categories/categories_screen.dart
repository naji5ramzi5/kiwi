import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/main_screen_controller.dart';
import 'widgets/category_grid.dart';
import 'widgets/category_product_list.dart';

class CategoriesScreen extends StatefulWidget {
  final String? initialCategory;
  const CategoriesScreen({super.key, this.initialCategory});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final HomeController homeController = Get.find<HomeController>();
  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final FavoritesController favController = Get.isRegistered<FavoritesController>()
      ? Get.find<FavoritesController>()
      : Get.put(FavoritesController());
  final MainScreenController navController = Get.find<MainScreenController>();

  final RxString selectedCategory = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController catSearchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString catSearchQuery = ''.obs;

  late final bool _isPushedRoute;

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

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    final doubleVal = double.tryParse(price.toString());
    if (doubleVal == null) return price.toString();
    if (doubleVal == doubleVal.toInt()) return doubleVal.toInt().toString();
    return doubleVal.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _isPushedRoute = widget.initialCategory != null;
    if (_isPushedRoute && widget.initialCategory!.isNotEmpty) {
      selectedCategory.value = widget.initialCategory!;
    } else {
      final catFromNav = navController.selectedCategory.value;
      if (catFromNav.isNotEmpty) {
        selectedCategory.value = catFromNav;
        navController.selectedCategory.value = '';
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    catSearchController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (selectedCategory.value.isNotEmpty) {
      selectedCategory.value = '';
      catSearchController.clear();
      catSearchQuery.value = '';
    } else if (_isPushedRoute) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        Get.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final cardBgColor = isDark ? const Color(0xFF1E291F) : Colors.white;

    return PopScope(
      canPop: _isPushedRoute ? selectedCategory.value.isEmpty : false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (selectedCategory.value.isNotEmpty) {
          selectedCategory.value = '';
          catSearchController.clear();
          catSearchQuery.value = '';
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Obx(() => Text(
            selectedCategory.value.isEmpty ? 'categories_title'.tr : selectedCategory.value,
            style: TextStyle(
              color: themeTextColor,
              fontWeight: FontWeight.w900,
              fontSize: selectedCategory.value.isEmpty ? 22 : 18,
              fontFamily: 'Cairo',
            ),
          )),
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: _isPushedRoute
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded, color: themeTextColor, size: 20),
                  onPressed: _handleBack,
                )
              : null,
        ),
        body: Obx(() {
          if (homeController.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (selectedCategory.value.isEmpty) {
            return CategoryGrid(
              homeController: homeController,
              categoryIcons: categoryIcons,
              searchController: searchController,
              searchQuery: searchQuery,
              isDark: isDark,
              themeTextColor: themeTextColor,
              themeTextSecColor: themeTextSecColor,
              cardBgColor: cardBgColor,
              onCategoryTap: (name) => selectedCategory.value = name,
            );
          }
          return CategoryProductList(
            homeController: homeController,
            cartController: cartController,
            favController: favController,
            selectedCategory: selectedCategory,
            searchController: catSearchController,
            searchQuery: catSearchQuery,
            isDark: isDark,
            themeTextColor: themeTextColor,
            themeTextSecColor: themeTextSecColor,
            cardBgColor: cardBgColor,
            formatPrice: formatPrice,
          );
        }),
      ),
    );
  }
}
