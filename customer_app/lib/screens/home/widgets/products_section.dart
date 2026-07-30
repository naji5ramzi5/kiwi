import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/favorites_controller.dart';
import 'product_card.dart';
import 'products_shimmer_grid.dart';

// Static fallback products - use function to resolve .tr at build time
List<Map<String, dynamic>> _getStaticProducts() => [
  {
    'id': 'static_1',
    'name': 'product_fresh_tomatoes'.tr,
    'price': 2500,
    'unit': 'unit_kg'.tr,
    'category': 'category_vegetables'.tr,
    'rating': 4.9,
    'image_url': 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_2',
    'name': 'product_green_cucumber'.tr,
    'price': 1500,
    'unit': 'unit_kg'.tr,
    'category': 'category_vegetables'.tr,
    'rating': 4.7,
    'image_url': 'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_3',
    'name': 'product_red_apple'.tr,
    'price': 4500,
    'unit': 'unit_kg'.tr,
    'category': 'category_fruits'.tr,
    'rating': 4.8,
    'image_url': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_4',
    'name': 'product_potato'.tr,
    'price': 1800,
    'unit': 'unit_kg'.tr,
    'category': 'category_vegetables'.tr,
    'rating': 4.6,
    'image_url': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_5',
    'name': 'product_juice_orange'.tr,
    'price': 3500,
    'unit': 'unit_kg'.tr,
    'category': 'category_fruits'.tr,
    'rating': 4.9,
    'image_url': 'https://images.unsplash.com/photo-1547514701-42782101795e?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_6',
    'name': 'product_eggplant'.tr,
    'price': 2000,
    'unit': 'unit_kg'.tr,
    'category': 'category_vegetables'.tr,
    'rating': 4.5,
    'image_url': 'https://images.unsplash.com/photo-1635400041897-2a79f7da7e16?auto=format&fit=crop&w=400&q=80',
    'isAvailable': false,
  },
];

class ProductsSection extends StatelessWidget {
  ProductsSection({super.key});

  final HomeController controller = Get.find<HomeController>();
  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final FavoritesController favController =
      Get.isRegistered<FavoritesController>()
          ? Get.find<FavoritesController>()
          : Get.put(FavoritesController());

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is num) return price.toInt().toString();
    final parsed = double.tryParse(price.toString());
    if (parsed != null) return parsed.toInt().toString();
    return price.toString();
  }

  int _getStock(Map<String, dynamic> p) {
    final dynamic biData = p['branch_inventory'] ?? p['inventory'];
    if (biData != null) {
      if (biData is List && biData.isNotEmpty) {
        final dynamic first = biData[0];
        final dynamic stockVal =
            first['actual_stock'] ?? first['quantity'] ?? 0;
        return (stockVal is num) ? stockVal.toInt() : 0;
      } else if (biData is Map) {
        final dynamic stockVal =
            biData['actual_stock'] ?? biData['quantity'] ?? 0;
        return (stockVal is num) ? stockVal.toInt() : 0;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoadingProducts.value) {
        return ProductsShimmerGrid(isDark: isDark);
      }

      final dbProducts = controller.products;
      final displayProducts =
          dbProducts.isNotEmpty ? dbProducts : _getStaticProducts();
      final isStatic = dbProducts.isEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'section_fresh_products'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 42,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isStatic)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'see_all'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.64,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: displayProducts.length,
            itemBuilder: (context, index) {
              final p = displayProducts[index];
              final imageUrl = (p['image_url'] ?? '').toString();

              bool isAvailable = true;
              int stockQty = 0;
              if (isStatic) {
                isAvailable = p['isAvailable'] as bool? ?? true;
              } else {
                stockQty = _getStock(p);
                isAvailable = stockQty > 0;
              }

              final productData = {
                'id': p['id'],
                'title': p['name'],
                'price': p['price'],
                'image': imageUrl,
                'category': p['category'],
                'unit': p['unit'] ?? 'unit_piece'.tr,
                'unit_type': p['unit_type']?.toString() ?? 'kilogram',
                'stock': stockQty,
              };

              return ProductCard(
                product: p,
                imageUrl: imageUrl,
                productData: productData,
                isAvailable: isAvailable,
                isDark: isDark,
                isStatic: isStatic,
                formatPrice: formatPrice,
              );
            },
          ),
        ],
      );
    });
  }
}
