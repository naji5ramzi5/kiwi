import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/favorites_controller.dart';
import 'widgets/category_product_list.dart';

/// Standalone category products screen.
///
/// Opened via Get.to() from Home or from the Categories tab. Because it is a
/// real route on the navigation stack, pressing Back always returns to the
/// screen that opened it (Home or Categories) — no manual bookkeeping needed.
class CategoryProductsScreen extends StatefulWidget {
  final String category;
  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final HomeController homeController = Get.find<HomeController>();
  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final FavoritesController favController = Get.isRegistered<FavoritesController>()
      ? Get.find<FavoritesController>()
      : Get.put(FavoritesController());

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    final doubleVal = double.tryParse(price.toString());
    if (doubleVal == null) return price.toString();
    if (doubleVal == doubleVal.toInt()) return doubleVal.toInt().toString();
    return doubleVal.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;
    final cardBgColor = isDark ? const Color(0xFF1E291F) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.category,
          style: TextStyle(
            color: themeTextColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            fontFamily: 'Cairo',
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: CategoryProductList(
        homeController: homeController,
        cartController: cartController,
        favController: favController,
        category: widget.category,
        searchController: searchController,
        searchQuery: searchQuery,
        isDark: isDark,
        themeTextColor: themeTextColor,
        themeTextSecColor: themeTextSecColor,
        cardBgColor: cardBgColor,
        formatPrice: formatPrice,
      ),
    );
  }
}
