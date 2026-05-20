import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';

class CategoriesSection extends StatelessWidget {
  CategoriesSection({super.key});

  final HomeController controller = Get.find<HomeController>();

  // Fallback images if category images are not in DB yet
  final Map<String, String> categoryImages = {
    'خضروات': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=200&q=80',
    'فواكه': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=200&q=80',
    'ورقيات': 'https://images.unsplash.com/photo-1622312693822-4917a14e9124?auto=format&fit=crop&w=200&q=80',
    'تمور': 'https://images.unsplash.com/photo-1596431989042-49764de3d037?auto=format&fit=crop&w=200&q=80',
    'مكسرات': 'https://images.unsplash.com/photo-1599598425947-330026296906?auto=format&fit=crop&w=200&q=80',
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingProducts.value) {
        return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
      }

      final categories = controller.categories;
      
      if (categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('categories'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('see_all'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final image = categoryImages[category] ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=200&q=80';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[100]),
                            errorWidget: (context, url, error) => const Icon(Icons.fastfood, color: AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ],
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
