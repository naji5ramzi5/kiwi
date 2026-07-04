import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';
import '../../product_details_screen.dart';
import '../../../controllers/cart_controller.dart';


class OffersSection extends StatelessWidget {
  OffersSection({super.key});

  final HomeController controller = Get.find<HomeController>();
  final CartController cartController = Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingProducts.value) {
        return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
      }

      // Filter products where cost is greater than price (indicating a discount)
      // or just take the first few products if no cost is defined for demonstration
      final offers = controller.products.where((p) => p['cost'] != null && (p['cost'] as num) > (p['price'] as num)).toList();

      if (offers.isEmpty) {
        // Fallback: Just show some products as "Offers" if none exist yet to keep the UI beautiful
        if (controller.products.length >= 3) {
          offers.addAll(controller.products.take(3));
        } else {
          return const SizedBox.shrink();
        }
      }

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.tag, color: AppTheme.primary, size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text('عروض حصرية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
                      ],
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
                Text('see_all'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Cairo')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150, // Height for the horizontal list
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                final imageUrl = offer['image_url'] ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80';
                final hasDiscount = offer['cost'] != null && (offer['cost'] as num) > (offer['price'] as num);

                return GestureDetector(
                  onTap: () {
                    final detailsData = {
                      'id': offer['id'],
                      'title': offer['name'],
                      'price': offer['price'],
                      'image': imageUrl,
                      'category': offer['category'],
                      'unit': offer['unit'] ?? 'حبة',
                    };
                    Get.to(() => ProductDetailsScreen(product: detailsData), transition: Transition.fadeIn);
                  },
                  child: Container(
                    width: 270,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Row(
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(22)),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 110,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[100]),
                          ),
                        ),
                        
                        // Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  offer['name'] ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, fontFamily: 'Cairo'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                if (hasDiscount)
                                  Text(
                                    '${offer['cost']} د.ع',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${offer['price']} د.ع',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryDark, fontFamily: 'Cairo'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        final productData = {
                                          'id': offer['id'],
                                          'title': offer['name'],
                                          'price': offer['price'],
                                          'image': imageUrl,
                                          'category': offer['category'],
                                          'unit': offer['unit'] ?? 'حبة',
                                          'stock': offer['stock'] ?? 10,
                                        };
                                        if (productData['stock'] == 0) return;
                                        cartController.addToCart(productData);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: (offer['stock'] == 0)
                                              ? null
                                              : const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                                          color: (offer['stock'] == 0) ? Colors.grey.shade300 : null,
                                          shape: BoxShape.circle,
                                          boxShadow: (offer['stock'] != 0)
                                              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]
                                              : [],
                                        ),
                                        child: Icon(
                                          (offer['stock'] == 0) ? LucideIcons.xCircle : LucideIcons.plus,
                                          size: 18,
                                          color: (offer['stock'] == 0) ? Colors.grey : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
