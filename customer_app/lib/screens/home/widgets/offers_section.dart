import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';
import '../../product_details_screen.dart';

class OffersSection extends StatelessWidget {
  OffersSection({super.key});

  final HomeController controller = Get.find<HomeController>();

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
                Row(
                  children: [
                    const Icon(LucideIcons.tag, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('عروض حصرية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ],
                ),
                Text('see_all'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140, // Height for the horizontal list
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
                    width: 260,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 100,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[100]),
                          ),
                        ),
                        
                        // Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  offer['name'] ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (hasDiscount)
                                  Text(
                                    '${offer['cost']} د.ع',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${offer['price']} د.ع',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(LucideIcons.shoppingCart, size: 16, color: AppTheme.primaryDark),
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
