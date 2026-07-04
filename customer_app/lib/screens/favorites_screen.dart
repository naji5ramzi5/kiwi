import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/home_controller.dart';
import 'product_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({super.key});

  final FavoritesController favController = Get.find<FavoritesController>();
  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final HomeController homeController = Get.find<HomeController>();

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
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('المفضلة', style: TextStyle(color: themeTextColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Obx(() {
            if (favController.favoriteProductIds.isEmpty) return const SizedBox();
            return IconButton(
              icon: Icon(LucideIcons.trash2, color: Colors.red.shade400, size: 20),
              onPressed: () {
                Get.defaultDialog(
                  title: 'حذف المفضلة',
                  middleText: 'هل تريد حذف جميع المنتجات من المفضلة؟',
                  textConfirm: 'نعم',
                  textCancel: 'إلغاء',
                  confirmTextColor: Colors.white,
                  onConfirm: () async {
                    for (final id in favController.favoriteProductIds.toList()) {
                      await favController.toggleFavorite(id);
                    }
                    Get.back();
                  },
                );
              },
            );
          }),
        ],
      ),
      body: Obx(() {
        final favIds = favController.favoriteProductIds;
        if (favIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.heart, size: 44, color: Colors.red),
                ),
                const SizedBox(height: 24),
                const Text(
                  'لا توجد منتجات في المفضلة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على أيقونة القلب لإضافة المنتجات',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontFamily: 'Cairo'),
                ),
              ],
            ),
          );
        }

        final allProducts = homeController.allProducts;
        final favProducts = allProducts.where((p) => favIds.contains(p['id'].toString())).toList();

        if (favProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.alertCircle, size: 36, color: Colors.amber),
                ),
                const SizedBox(height: 16),
                const Text('بيانات المفضلة قيد التحميل...', style: TextStyle(fontFamily: 'Cairo')),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.74,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: favProducts.length,
          itemBuilder: (context, index) {
            final p = favProducts[index];
            final imageUrl = (p['image_url'] ?? '').toString();
            int favStock = 0;
            final dynamic favBiData = p['branch_inventory'] ?? p['inventory'];
            if (favBiData != null) {
              if (favBiData is List && favBiData.isNotEmpty) {
                final dynamic first = favBiData[0];
                final dynamic stockVal = first['actual_stock'] ?? first['quantity'] ?? 0;
                favStock = (stockVal is num) ? stockVal.toInt() : 0;
              } else if (favBiData is Map) {
                final dynamic stockVal = favBiData['actual_stock'] ?? favBiData['quantity'] ?? 0;
                favStock = (stockVal is num) ? stockVal.toInt() : 0;
              }
            }
            final productData = {
              'id': p['id'],
              'title': p['name'],
              'price': p['price'],
              'image': imageUrl,
              'category': p['category'],
              'unit': p['unit'] ?? 'حبة',
              'stock': favStock,
            };

            return GestureDetector(
              onTap: () => Get.to(() => ProductDetailsScreen(product: productData), transition: Transition.fadeIn),
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
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.primary.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.green.withOpacity(0.08) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: isDark ? Colors.grey[800] : Colors.grey[100]),
                                      errorWidget: (_, __, ___) => Icon(LucideIcons.shoppingBag, color: AppTheme.primary.withOpacity(0.4), size: 40),
                                    )
                                  : Icon(LucideIcons.shoppingBag, color: AppTheme.primary.withOpacity(0.4), size: 40),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => favController.toggleFavorite(p['id'].toString()),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.92),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                                ),
                                child: const Icon(Icons.favorite, size: 14, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] ?? 'منتج',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: themeTextColor, fontFamily: 'Cairo'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${formatPrice(p['price'])} د.ع',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF34D399) : AppTheme.primaryDark, fontFamily: 'Cairo'),
                                  ),
                                  Text(
                                    '/ ${p['unit'] ?? 'حبة'}',
                                    style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontFamily: 'Cairo'),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: favStock == 0 ? null : () => cartController.addToCart(productData),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: favStock == 0 ? null : const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                                    color: favStock == 0 ? Colors.grey.shade300 : null,
                                    shape: BoxShape.circle,
                                    boxShadow: favStock == 0 ? [] : [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                                  ),
                                  child: Icon(favStock == 0 ? LucideIcons.xCircle : LucideIcons.plus, size: 16, color: favStock == 0 ? Colors.grey : Colors.white),
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
    );
  }
}
