import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../product_details_screen.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/favorites_controller.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String imageUrl;
  final Map<String, dynamic> productData;
  final bool isAvailable;
  final bool isDark;
  final bool isStatic;
  final String Function(dynamic) formatPrice;

  const ProductCard({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.productData,
    required this.isAvailable,
    required this.isDark,
    required this.isStatic,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final favController = Get.isRegistered<FavoritesController>()
        ? Get.find<FavoritesController>()
        : Get.put(FavoritesController());
    final cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController());

    return GestureDetector(
      onTap: () {
        if (product['id'].toString().startsWith('static_')) return;
        Get.to(() => ProductDetailsScreen(product: productData),
            transition: Transition.fadeIn);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2B1E) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(22)),
                        child: GestureDetector(
                          onTap: () {
                            if (imageUrl.isNotEmpty) {
                              Get.dialog(Stack(children: [
                                Positioned.fill(
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (c, u) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (c, u, e) => const Center(
                                        child:
                                            Icon(Icons.broken_image, size: 60)),
                                  ),
                                ),
                                Positioned(
                                  top: 40,
                                  right: 20,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white, size: 28),
                                    onPressed: () => Get.back(),
                                  ),
                                ),
                              ]));
                            }
                          },
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : const Color(0xFFF0FDF4),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.shoppingBag,
                                        color: AppTheme.primary,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : const Color(0xFFF0FDF4),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.shoppingBag,
                                      color: AppTheme.primary,
                                      size: 40,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 18,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => favController
                              .toggleFavorite(product['id'].toString()),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Obx(() {
                              final isFav =
                                  favController.isFavorite(product['id'].toString());
                              return Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                size: 14,
                                color: isFav
                                    ? Colors.red
                                    : (isDark
                                        ? Colors.white60
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
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'product_fallback'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildRatingLabel(),
                      const SizedBox(height: 8),
                      _buildPriceRow(),
                    ],
                  ),
                ),
              ],
            ),
            if (!isAvailable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      'product_out_of_stock'.tr,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Cairo',
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

  Widget _buildRatingLabel() {
    return Text(
      'product_no_rating'.tr,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
        fontFamily: 'Cairo',
      ),
    );
  }

  Widget _buildPriceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatPrice(product['price'])}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppTheme.emeraldLight
                        : AppTheme.primaryDark,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'currency_iqd'.tr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            Text(
              'product_per_unit'.trParams({'unit': (product['unit'] ?? 'unit_kg'.tr)}),
              style: TextStyle(
                fontSize: 10,
                color:
                    isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: !isAvailable
              ? null
              : () {
                  if (product['id'].toString().startsWith('static_')) {
                    Get.snackbar(
                      'product_coming_soon'.tr,
                      'product_coming_soon_msg'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppTheme.primary,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                    return;
                  }
                  final cartController = Get.isRegistered<CartController>()
                      ? Get.find<CartController>()
                      : Get.put(CartController());
                  cartController.addToCart(productData);
                },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isAvailable
                  ? const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isAvailable
                  ? null
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              shape: BoxShape.circle,
              boxShadow: isAvailable
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child:
                const Icon(LucideIcons.plus, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
