import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/favorites_controller.dart';
import '../../product_details_screen.dart';

class CategoryProductList extends StatelessWidget {
  final HomeController homeController;
  final CartController cartController;
  final FavoritesController favController;
  final String category;
  final TextEditingController searchController;
  final RxString searchQuery;
  final bool isDark;
  final Color themeTextColor;
  final Color themeTextSecColor;
  final Color cardBgColor;
  final String Function(dynamic) formatPrice;

  const CategoryProductList({
    super.key,
    required this.homeController,
    required this.cartController,
    required this.favController,
    required this.category,
    required this.searchController,
    required this.searchQuery,
    required this.isDark,
    required this.themeTextColor,
    required this.themeTextSecColor,
    required this.cardBgColor,
    required this.formatPrice,
  });

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E291F) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) => searchQuery.value = val,
              style: TextStyle(
                color: themeTextColor,
                fontFamily: 'Cairo',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'search_in_section'.tr,
                hintStyle: TextStyle(
                  color: themeTextSecColor.withOpacity(0.6),
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: AppTheme.primary,
                  size: 20,
                ),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            List<dynamic> products = homeController.allProducts.where((p) {
              final cat = (p['category'] ?? '').toString();
              return cat.toLowerCase() == category.toLowerCase();
            }).toList();

            if (searchQuery.value.isNotEmpty) {
              final q = searchQuery.value.toLowerCase();
              products = products.where((p) {
                return (p['name'] ?? '').toString().toLowerCase().contains(q);
              }).toList();
            }

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.packageOpen,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'no_products_in_section'.tr,
                      style: TextStyle(
                        color: themeTextSecColor,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                final imageUrl = p['image_url'] ?? '';
                final stockQty = _getStock(p);
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

                return GestureDetector(
                  onTap: () => Get.to(
                    () => ProductDetailsScreen(product: productData),
                    transition: Transition.fadeIn,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (_, __) => Container(
                                    color: isDark
                                        ? Colors.grey[850]
                                        : Colors.grey[100],
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      LucideIcons.image,
                                      color: AppTheme.primary.withOpacity(0.3),
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => favController.toggleFavorite(
                                    p['id'].toString(),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.6)
                                          : Colors.white.withOpacity(0.95),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Obx(() {
                                      final isFav = favController.isFavorite(
                                        p['id'].toString(),
                                      );
                                      return Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 13,
                                        color: isFav
                                            ? Colors.red
                                            : (isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade400),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: themeTextColor,
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${formatPrice(p['price'])} ${'currency_iqd'.tr}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? AppTheme.primaryBright
                                                : AppTheme.primaryDark,
                                            fontFamily: 'Cairo',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '/ ${p['unit'] ?? 'unit_piece'.tr}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isDark
                                                ? Colors.grey.shade500
                                                : Colors.grey.shade400,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: stockQty == 0
                                        ? null
                                        : () => cartController.addToCart(
                                            productData,
                                          ),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: stockQty == 0
                                            ? null
                                            : const LinearGradient(
                                                colors: [
                                                  AppTheme.primary,
                                                  AppTheme.primaryDark,
                                                ],
                                              ),
                                        color: stockQty == 0
                                            ? Colors.grey.shade300
                                            : null,
                                        shape: BoxShape.circle,
                                        boxShadow: stockQty == 0
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: AppTheme.primary
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                      ),
                                      child: const Icon(
                                        LucideIcons.plus,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
