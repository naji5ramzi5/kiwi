import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/main_screen_controller.dart';
import '../product_details_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final HomeController homeController = Get.find<HomeController>();
  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final FavoritesController favController = Get.isRegistered<FavoritesController>()
      ? Get.find<FavoritesController>()
      : Get.put(FavoritesController());
  final MainScreenController navController = Get.find<MainScreenController>();

  final RxString selectedCategory = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController catSearchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString catSearchQuery = ''.obs;

  final Map<String, IconData> categoryIcons = {
    'فواكه': LucideIcons.apple,
    'خضروات': LucideIcons.leaf,
    'لحوم ودواجن': LucideIcons.beef,
    'ألبان': LucideIcons.milk,
    'مشروبات': LucideIcons.wine,
    'سناك': LucideIcons.cookie,
    'بقالة': LucideIcons.shoppingBag,
    'زيوت وتوابل': LucideIcons.flaskConical,
    'مخبوزات': LucideIcons.wheat,
    'منظفات': LucideIcons.sprayCan,
  };

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    final doubleVal = double.tryParse(price.toString());
    if (doubleVal == null) return price.toString();
    if (doubleVal == doubleVal.toInt()) return doubleVal.toInt().toString();
    return doubleVal.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    final catFromNav = navController.selectedCategory.value;
    if (catFromNav.isNotEmpty) {
      selectedCategory.value = catFromNav;
      navController.selectedCategory.value = '';
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    catSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final cardBgColor = isDark ? const Color(0xFF1E291F) : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (selectedCategory.value.isNotEmpty) {
          selectedCategory.value = '';
          catSearchController.clear();
          catSearchQuery.value = '';
        }
      },
      child: Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Obx(() => Text(
          selectedCategory.value.isEmpty ? 'الأقسام' : selectedCategory.value,
          style: TextStyle(
            color: themeTextColor,
            fontWeight: FontWeight.w900,
            fontSize: selectedCategory.value.isEmpty ? 22 : 18,
            fontFamily: 'Cairo',
          ),
        )),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: selectedCategory.value.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded, color: themeTextColor, size: 20),
                onPressed: () {
                  selectedCategory.value = '';
                  catSearchController.clear();
                  catSearchQuery.value = '';
                },
              )
            : null,
      ),
      body: Obx(() {
        if (homeController.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (selectedCategory.value.isEmpty) {
          return _buildCategoriesGrid(isDark, themeTextColor, themeTextSecColor, cardBgColor);
        }

        return _buildCategoryProducts(isDark, themeTextColor, themeTextSecColor, cardBgColor);
      }),
    ),
    );
  }

  Widget _buildCategoriesGrid(bool isDark, Color themeTextColor, Color themeTextSecColor, Color cardBgColor) {
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
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) => searchQuery.value = val,
              style: TextStyle(color: themeTextColor, fontFamily: 'Cairo', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ابحث عن قسم...',
                hintStyle: TextStyle(color: themeTextSecColor.withOpacity(0.6), fontFamily: 'Cairo', fontSize: 13),
                prefixIcon: const Icon(LucideIcons.search, color: AppTheme.primary, size: 20),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
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
            List<Map<String, dynamic>> cats = List.from(homeController.categories);
            if (searchQuery.value.isNotEmpty) {
              final q = searchQuery.value.toLowerCase();
              cats = cats.where((c) => (c['name'] ?? '').toString().toLowerCase().contains(q)).toList();
            }

            if (cats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.searchX, size: 50, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('لا توجد أقسام', style: TextStyle(color: themeTextSecColor, fontSize: 14, fontFamily: 'Cairo')),
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
                  onTap: () => selectedCategory.value = name,
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
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                            child: image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (_, __) => Container(color: isDark ? Colors.grey[850] : Colors.grey[100]),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppTheme.primary.withOpacity(0.05),
                                      child: Icon(categoryIcons[name] ?? LucideIcons.box, size: 36, color: AppTheme.primary.withOpacity(0.4)),
                                    ),
                                  )
                                : Container(
                                    color: AppTheme.primary.withOpacity(0.05),
                                    child: Icon(categoryIcons[name] ?? LucideIcons.box, size: 36, color: AppTheme.primary.withOpacity(0.4)),
                                  ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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

  Widget _buildCategoryProducts(bool isDark, Color themeTextColor, Color themeTextSecColor, Color cardBgColor) {
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
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: TextField(
              controller: catSearchController,
              onChanged: (val) => catSearchQuery.value = val,
              style: TextStyle(color: themeTextColor, fontFamily: 'Cairo', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ابحث في هذا القسم...',
                hintStyle: TextStyle(color: themeTextSecColor.withOpacity(0.6), fontFamily: 'Cairo', fontSize: 13),
                prefixIcon: const Icon(LucideIcons.search, color: AppTheme.primary, size: 20),
                suffixIcon: catSearchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () {
                          catSearchController.clear();
                          catSearchQuery.value = '';
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
              return cat.toLowerCase() == selectedCategory.value.toLowerCase();
            }).toList();

            if (catSearchQuery.value.isNotEmpty) {
              final q = catSearchQuery.value.toLowerCase();
              products = products.where((p) {
                return (p['name'] ?? '').toString().toLowerCase().contains(q);
              }).toList();
            }

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.packageOpen, size: 50, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('لا توجد منتجات في هذا القسم', style: TextStyle(color: themeTextSecColor, fontSize: 14, fontFamily: 'Cairo')),
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
                int catStock = 0;
                final dynamic catBiData = p['branch_inventory'] ?? p['inventory'];
                if (catBiData != null) {
                  if (catBiData is List && catBiData.isNotEmpty) {
                    final dynamic first = catBiData[0];
                    final dynamic stockVal = first['actual_stock'] ?? first['quantity'] ?? 0;
                    catStock = (stockVal is num) ? stockVal.toInt() : 0;
                  } else if (catBiData is Map) {
                    final dynamic stockVal = catBiData['actual_stock'] ?? catBiData['quantity'] ?? 0;
                    catStock = (stockVal is num) ? stockVal.toInt() : 0;
                  }
                }
                final productData = {
                  'id': p['id'],
                  'title': p['name'],
                  'price': p['price'],
                  'image': imageUrl,
                  'category': p['category'],
                  'unit': p['unit'] ?? 'حبة',
                  'stock': catStock,
                };

                return GestureDetector(
                  onTap: () => Get.to(() => ProductDetailsScreen(product: productData), transition: Transition.fadeIn),
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
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (_, __) => Container(color: isDark ? Colors.grey[850] : Colors.grey[100]),
                                  errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: Icon(LucideIcons.image, color: AppTheme.primary.withOpacity(0.3), size: 30)),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => favController.toggleFavorite(p['id'].toString()),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.95),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Obx(() {
                                      final isFav = favController.isFavorite(p['id'].toString());
                                      return Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        size: 13,
                                        color: isFav ? Colors.red : (isDark ? Colors.white70 : Colors.grey.shade400),
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
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: themeTextColor, fontFamily: 'Cairo'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${formatPrice(p['price'])} د.ع',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? const Color(0xFF4ADE80) : AppTheme.primaryDark,
                                            fontFamily: 'Cairo',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '/ ${p['unit'] ?? 'حبة'}',
                                          style: TextStyle(fontSize: 9, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontFamily: 'Cairo'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: catStock == 0 ? null : () => cartController.addToCart(productData),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: catStock == 0 ? null : const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                                        color: catStock == 0 ? Colors.grey.shade300 : null,
                                        shape: BoxShape.circle,
                                        boxShadow: catStock == 0 ? [] : [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
                                      ),
                                      child: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
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
