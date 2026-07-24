import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';
import '../../../screens/categories/categories_screen.dart';

// Static fallback categories - use function to resolve .tr at build time
List<Map<String, String>> _getStaticCategories() => [
  {
    'name': 'category_vegetables'.tr,
    'image': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=200&q=80',
    'emoji': '🥦',
  },
  {
    'name': 'category_fruits'.tr,
    'image': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=200&q=80',
    'emoji': '🍎',
  },
  {
    'name': 'category_leafy_greens'.tr,
    'image': 'https://images.unsplash.com/photo-1622312693822-4917a14e9124?auto=format&fit=crop&w=200&q=80',
    'emoji': '🥬',
  },
  {
    'name': 'category_dates'.tr,
    'image': 'https://images.unsplash.com/photo-1596431989042-49764de3d037?auto=format&fit=crop&w=200&q=80',
    'emoji': '🌴',
  },
  {
    'name': 'category_nuts'.tr,
    'image': 'https://images.unsplash.com/photo-1599598425947-330026296906?auto=format&fit=crop&w=200&q=80',
    'emoji': '🥜',
  },
  {
    'name': 'category_legumes'.tr,
    'image': 'https://images.unsplash.com/photo-1535914254981-b5012eebbd15?auto=format&fit=crop&w=200&q=80',
    'emoji': '🫘',
  },
];

class CategoriesSection extends StatelessWidget {
  CategoriesSection({super.key});

  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;

    return Obx(() {
      final dbCategories = controller.categories;
      final displayCategories = dbCategories.isNotEmpty
          ? dbCategories
              .map((c) => {
                    'name': c['name'] ?? '',
                    'image': c['image_url'] ?? '',
                    'emoji': '',
                  })
              .toList()
          : _getStaticCategories();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'section_categories'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => CategoriesScreen(),
                        transition: Transition.fadeIn,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Categories Horizontal List
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: displayCategories.length,
              itemBuilder: (context, index) {
                final cat = displayCategories[index];
                final name = cat['name'] ?? '';
                final image = cat['image'] ?? '';
                final emoji = cat['emoji'] ?? '';

                return GestureDetector(
                  onTap: () {
                    Get.to(
                      () => CategoriesScreen(initialCategory: name),
                      transition: Transition.fadeIn,
                    );
                  },
                  child: Container(
                    width: 85,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        // Category Image Circle
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : AppTheme.primary.withOpacity(0.08),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.25),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Cairo',
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
