import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../controllers/home_controller.dart';
import '../controllers/cart_controller.dart';
import 'product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final HomeController homeController = Get.find<HomeController>();
  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());

  final TextEditingController searchController = TextEditingController();
  final RxString query = ''.obs;
  final RxString selectedCategory = ''.obs;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      query.value = searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is num) {
      return price.toInt().toString();
    }
    final parsed = double.tryParse(price.toString());
    if (parsed != null) {
      return parsed.toInt().toString();
    }
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'البحث عن منتجات',
          style: TextStyle(
            color: themeTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Cairo',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search Input Field ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                ),
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                style: TextStyle(color: themeTextColor, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  hintText: 'ابحث عن طماطم، تفاح، خضار...',
                  hintStyle: TextStyle(
                    color: themeTextSecColor.withOpacity(0.6),
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(LucideIcons.search, color: AppTheme.primary, size: 20),
                  suffixIcon: Obx(() => query.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                          onPressed: () {
                            searchController.clear();
                          },
                        )
                      : const SizedBox.shrink()),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),

          // ── Categories Filters Row ──
          Obx(() {
            if (homeController.categories.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: homeController.categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = selectedCategory.value.isEmpty;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: const Text('الكل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                        selected: isSelected,
                        onSelected: (selected) {
                          selectedCategory.value = '';
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.textPrimary),
                        ),
                        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        showCheckmark: false,
                      ),
                    );
                  }

                  final cat = homeController.categories[index - 1];
                  final catName = cat['name'] ?? '';
                  final isSelected = selectedCategory.value == catName;

                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(catName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      onSelected: (selected) {
                        selectedCategory.value = selected ? catName : '';
                      },
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.textPrimary),
                      ),
                      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            );
          }),

          // ── Results List ──
          Expanded(
            child: Obx(() {
              final activeQuery = query.value;
              final activeCategory = selectedCategory.value;

              var filtered = homeController.allProducts.where((p) {
                final name = (p['name'] ?? '').toString().toLowerCase();
                final category = (p['category'] ?? '').toString().toLowerCase();
                
                final matchesQuery = name.contains(activeQuery);
                final matchesCategory = activeCategory.isEmpty || category == activeCategory.toLowerCase();

                return matchesQuery && matchesCategory;
              }).toList();

              // Sort by rating descending when no active query
              if (activeQuery.isEmpty) {
                filtered.sort((a, b) {
                  final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
                  final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
                  return ratingB.compareTo(ratingA);
                });
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.search, size: 64, color: themeTextSecColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد نتائج مطابقة لبحثك',
                        style: TextStyle(
                          color: themeTextSecColor,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'جرّب البحث بكلمات أخرى أو تصفح الأقسام',
                        style: TextStyle(
                          color: themeTextSecColor.withOpacity(0.6),
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final p = filtered[index];
                  final imageUrl = p['image_url'] ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80';

                  final productData = {
                    'id': p['id'],
                    'title': p['name'],
                    'price': p['price'],
                    'image': imageUrl,
                    'category': p['category'],
                    'unit': p['unit'] ?? 'حبة',
                  };

                  int quantity = 0;
                  final dynamic biData = p['branch_inventory'] ?? p['inventory'];
                  if (biData != null) {
                    if (biData is List && biData.isNotEmpty) {
                      final dynamic first = biData[0];
                      final dynamic stockVal = first['actual_stock'] ?? first['quantity'] ?? first['stock'] ?? 0;
                      quantity = (stockVal is num) ? stockVal.toInt() : (double.tryParse(stockVal.toString())?.toInt() ?? 0);
                    } else if (biData is Map) {
                      final dynamic stockVal = biData['actual_stock'] ?? biData['quantity'] ?? biData['stock'] ?? 0;
                      quantity = (stockVal is num) ? stockVal.toInt() : (double.tryParse(stockVal.toString())?.toInt() ?? 0);
                    }
                  }

                  final bool isAvailable = quantity > 0;
                  final double rating = p['rating']?.toDouble() ?? 4.8;

                  return Container(
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
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: isDark ? Colors.grey[800] : Colors.grey[100]),
                                      errorWidget: (context, url, error) => Container(
                                        color: isDark ? Colors.grey[800] : const Color(0xFFF0FDF4),
                                        child: const Center(
                                          child: Icon(LucideIcons.shoppingBag, color: AppTheme.primary, size: 40),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!isAvailable)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.45),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'نفذت الكمية',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'] ?? 'منتج',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: themeTextColor,
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Colors.orange),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$rating  |  ${p['category'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${formatPrice(p['price'])} د.ع',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? const Color(0xFF34D399) : AppTheme.primaryDark,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          Text(
                                            ' /${p['unit']}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: !isAvailable ? null : () {
                                        cartController.addToCart(productData);
                                        Get.snackbar(
                                          'تمت الإضافة',
                                          'تم إضافة ${p['name']} إلى السلة 🛒',
                                          snackPosition: SnackPosition.TOP,
                                          backgroundColor: Colors.green.shade600,
                                          colorText: Colors.white,
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 1),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: isAvailable
                                              ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark])
                                              : null,
                                          color: isAvailable ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                                          shape: BoxShape.circle,
                                          boxShadow: isAvailable ? [
                                            BoxShadow(
                                              color: AppTheme.primary.withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            )
                                          ] : [],
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
            }),
          ),
        ],
      ),
    );
  }
}
