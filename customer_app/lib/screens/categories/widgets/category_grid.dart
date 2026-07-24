import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/home_controller.dart';

class CategoryGrid extends StatelessWidget {
  final HomeController homeController;
  final Map<String, IconData> categoryIcons;
  final TextEditingController searchController;
  final RxString searchQuery;
  final bool isDark;
  final Color themeTextColor;
  final Color themeTextSecColor;
  final Color cardBgColor;
  final Function(String) onCategoryTap;

  const CategoryGrid({
    super.key,
    required this.homeController,
    required this.categoryIcons,
    required this.searchController,
    required this.searchQuery,
    required this.isDark,
    required this.themeTextColor,
    required this.themeTextSecColor,
    required this.cardBgColor,
    required this.onCategoryTap,
  });

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
                hintText: 'search_category'.tr,
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
            List<Map<String, dynamic>> cats = List.from(
              homeController.categories,
            );
            if (searchQuery.value.isNotEmpty) {
              final q = searchQuery.value.toLowerCase();
              cats = cats
                  .where(
                    (c) =>
                        (c['name'] ?? '').toString().toLowerCase().contains(q),
                  )
                  .toList();
            }
            if (cats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.searchX,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'no_categories'.tr,
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
                childAspectRatio: 0.85,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: cats.length,
              itemBuilder: (context, index) {
                final cat = cats[index];
                final name = cat['name'] ?? '';
                final image = cat['image_url'] ?? '';
                return GestureDetector(
                  onTap: () => onCategoryTap(name),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            child: image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (_, __) => Container(
                                      color: isDark
                                          ? Colors.grey[850]
                                          : Colors.grey[100],
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppTheme.primary.withOpacity(0.05),
                                      child: Icon(
                                        categoryIcons[name] ?? LucideIcons.box,
                                        size: 36,
                                        color: AppTheme.primary.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppTheme.primary.withOpacity(0.05),
                                    child: Icon(
                                      categoryIcons[name] ?? LucideIcons.box,
                                      size: 36,
                                      color: AppTheme.primary.withOpacity(0.4),
                                    ),
                                  ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: themeTextColor,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
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
