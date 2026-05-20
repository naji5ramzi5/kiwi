import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../product_details_screen.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/cart_controller.dart';

class ProductsSection extends StatelessWidget {
  ProductsSection({super.key});

  final HomeController controller = Get.find<HomeController>();
  final CartController cartController = Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingProducts.value) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ));
      }

      if (controller.products.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('لا توجد منتجات حالياً', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: controller.products.length,
        itemBuilder: (context, index) {
          final p = controller.products[index];
          final imageUrl = p['image_url'] ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80';
          
          final productData = {
            'id': p['id'],
            'title': p['name'],
            'price': p['price'],
            'image': imageUrl,
            'category': p['category'],
            'unit': p['unit'] ?? 'حبة',
          };

          final inv = p['inventory'] as List;
          final int quantity = inv.isNotEmpty ? inv[0]['quantity'] : 0;
          final bool isAvailable = quantity > 0;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))
              ],
            ),
            child: Opacity(
              opacity: isAvailable ? 1.0 : 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.to(() => ProductDetailsScreen(product: productData), transition: Transition.fadeIn);
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: const Color(0xFFF9FAFB)),
                            ),
                          ),
                          if (!isAvailable)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: const Center(
                                child: Text(
                                  'غير متوفر',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                              child: const Icon(LucideIcons.heart, size: 16, color: Colors.grey),
                            ),
                          ),
                          if (p['unit'] != null)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                                ),
                                child: Text(
                                  p['unit'],
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name'] ?? 'منتج',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p['category'] ?? '',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${p['price']} د.ع',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                            ),
                            GestureDetector(
                              onTap: !isAvailable ? null : () {
                                cartController.addToCart(productData);
                                Get.snackbar(
                                  'نجاح',
                                  'تم إضافة ${p['name']} إلى السلة 🛒',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: const Color(0xFF10B981),
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isAvailable ? AppTheme.primary : Colors.grey, 
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isAvailable ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                ),
                                child: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
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
    });
  }
}
