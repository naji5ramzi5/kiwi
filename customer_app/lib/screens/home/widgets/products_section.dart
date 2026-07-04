import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../product_details_screen.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/favorites_controller.dart';

// Static fallback products
const List<Map<String, dynamic>> _staticProducts = [
  {
    'id': 'static_1',
    'name': 'طماطم طازجة',
    'price': 2500,
    'unit': 'كغ',
    'category': 'خضروات',
    'rating': 4.9,
    'image_url': 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_2',
    'name': 'خيار أخضر',
    'price': 1500,
    'unit': 'كغ',
    'category': 'خضروات',
    'rating': 4.7,
    'image_url': 'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_3',
    'name': 'تفاح أحمر',
    'price': 4500,
    'unit': 'كغ',
    'category': 'فواكه',
    'rating': 4.8,
    'image_url': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_4',
    'name': 'بطاطا',
    'price': 1800,
    'unit': 'كغ',
    'category': 'خضروات',
    'rating': 4.6,
    'image_url': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_5',
    'name': 'برتقال عصير',
    'price': 3500,
    'unit': 'كغ',
    'category': 'فواكه',
    'rating': 4.9,
    'image_url': 'https://images.unsplash.com/photo-1547514701-42782101795e?auto=format&fit=crop&w=400&q=80',
    'isAvailable': true,
  },
  {
    'id': 'static_6',
    'name': 'باذنجان',
    'price': 2000,
    'unit': 'كغ',
    'category': 'خضروات',
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
  final FavoritesController favController = Get.isRegistered<FavoritesController>() ? Get.find<FavoritesController>() : Get.put(FavoritesController());

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is num) return price.toInt().toString();
    final parsed = double.tryParse(price.toString());
    if (parsed != null) return parsed.toInt().toString();
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoadingProducts.value) {
        return _buildShimmerGrid(isDark);
      }

      final dbProducts = controller.products;
      final displayProducts = dbProducts.isNotEmpty ? dbProducts : _staticProducts;
      final isStatic = dbProducts.isEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with curved arc decoration
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'منتجات طازجة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'عرض الكل',
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

          // Products Grid
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

              // Compute availability
              bool isAvailable = true;
              if (isStatic) {
                isAvailable = p['isAvailable'] as bool? ?? true;
              } else {
                int quantity = 0;
                final dynamic biData = p['branch_inventory'] ?? p['inventory'];
                if (biData != null) {
                  if (biData is List && biData.isNotEmpty) {
                    final dynamic first = biData[0];
                    final dynamic stockVal = first['actual_stock'] ?? first['quantity'] ?? 0;
                    quantity = (stockVal is num) ? stockVal.toInt() : 0;
                  } else if (biData is Map) {
                    final dynamic stockVal = biData['actual_stock'] ?? biData['quantity'] ?? 0;
                    quantity = (stockVal is num) ? stockVal.toInt() : 0;
                  }
                }
                isAvailable = quantity > 0;
              }

              final double rating = (p['rating'] as num?)?.toDouble() ?? 4.8;
              int stockQty = 0;
              if (!isStatic) {
                final dynamic biData = p['branch_inventory'] ?? p['inventory'];
                if (biData != null) {
                  if (biData is List && biData.isNotEmpty) {
                    final dynamic first = biData[0];
                    final dynamic stockVal = first['actual_stock'] ?? first['quantity'] ?? 0;
                    stockQty = (stockVal is num) ? stockVal.toInt() : 0;
                  } else if (biData is Map) {
                    final dynamic stockVal = biData['actual_stock'] ?? biData['quantity'] ?? 0;
                    stockQty = (stockVal is num) ? stockVal.toInt() : 0;
                  }
                }
              }
              final productData = {
                'id': p['id'],
                'title': p['name'],
                'price': p['price'],
                'image': imageUrl,
                'category': p['category'],
                'unit': p['unit'] ?? 'حبة',
                'stock': stockQty,
              };

              return _buildProductCard(context, p, imageUrl, productData, isAvailable, rating, isDark);
            },
          ),
        ],
      );
    });
  }

  Widget _buildProductCard(
    BuildContext context,
    Map<String, dynamic> p,
    String imageUrl,
    Map<String, dynamic> productData,
    bool isAvailable,
    double rating,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        if (p['id'].toString().startsWith('static_')) return;
        Get.to(() => ProductDetailsScreen(product: productData), transition: Transition.fadeIn);
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
                // Product Image - rounded corners like categories
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        child: GestureDetector(
                          onTap: () {
                            if (imageUrl.isNotEmpty) {
                              Get.dialog(Stack(children: [
                                Positioned.fill(
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (c, u, e) => const Center(child: Icon(Icons.broken_image, size: 60)),
                                  ),
                                ),
                                Positioned(
                                  top: 40, right: 20,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
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
                                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: isDark ? Colors.grey[800] : const Color(0xFFF0FDF4),
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
                                  color: isDark ? Colors.grey[800] : const Color(0xFFF0FDF4),
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

                    // Favorite button
                    Positioned(
                      top: 18,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => favController.toggleFavorite(p['id'].toString()),
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
                            final isFav = favController.isFavorite(p['id'].toString());
                            return Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: isFav ? Colors.red : (isDark ? Colors.white60 : Colors.grey.shade400),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      p['name'] ?? 'منتج',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Interactive star rating
                    StatefulBuilder(
                      builder: (context, setLocalState) {
                        int localRating = rating.round().clamp(1, 5);
                        return Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: List.generate(5, (i) {
                              final starIndex = i + 1;
                              return GestureDetector(
                                onTap: () {
                                  setLocalState(() => localRating = starIndex);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 1),
                                  child: Icon(
                                    starIndex <= localRating
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 15,
                                    color: Colors.amber,
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${formatPrice(p['price'])}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? const Color(0xFF34D399)
                                        : AppTheme.primaryDark,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'د.ع',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'لـ 1 ${p['unit'] ?? 'كغ'}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: !isAvailable
                              ? null
                              : () {
                                  if (p['id'].toString().startsWith('static_')) {
                                    Get.snackbar(
                                      '🔔 قريباً',
                                      'سيتم إضافة المنتجات من لوحة التحكم',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppTheme.primary,
                                      colorText: Colors.white,
                                      duration: const Duration(seconds: 2),
                                    );
                                    return;
                                  }
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
                                  : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300),
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
                            child: const Icon(LucideIcons.plus,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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
                child: const Center(
                  child: Text(
                    'نفدت الكمية',
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

  Widget _buildShimmerGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}
