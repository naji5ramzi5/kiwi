import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../controllers/cart_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/favorites_controller.dart';
import 'widgets/product_image_hero.dart';
import 'widgets/product_quantity_selector.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late num _quantity;
  final CartController cartController = Get.find<CartController>();
  final HomeController homeController = Get.find<HomeController>();
  bool _isLiked = false;

  String get _unitType => widget.product['unit_type']?.toString() ?? 'kilogram';
  bool get _isDecimalUnit => ['kilogram', 'kg', 'gram', 'g', 'liter', 'l', 'milliliter', 'ml'].contains(_unitType.toLowerCase());
  num get _qtyStep => _isDecimalUnit ? 0.5 : 1;

  @override
  void initState() {
    super.initState();
    _quantity = _qtyStep;
  }

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is num) return price.toInt().toString();
    final parsed = double.tryParse(price.toString());
    if (parsed != null) return parsed.toInt().toString();
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    const double overlap = 25;
    const double curveRadius = 45;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimary;
    final themeTextSecColor = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondary;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ProductImageHero(
                    image: widget.product['image'],
                    heroTag: widget.product['id'],
                    screenHeight: screenHeight,
                    overlap: overlap,
                    curveRadius: curveRadius,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -overlap),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(curveRadius),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        overlap + 20,
                        24,
                        120,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleRow(context, isDark, themeTextColor),
                          const SizedBox(height: 20),
                          _buildPriceRow(
                            context,
                            isDark,
                            themeTextColor,
                            themeTextSecColor,
                          ),
                          const SizedBox(height: 24),
                          _buildDescription(
                            context,
                            isDark,
                            themeTextColor,
                            themeTextSecColor,
                          ),
                          const SizedBox(height: 20),
                          _buildRelatedHeader(context, isDark, themeTextColor),
                          const SizedBox(height: 12),
                          _buildHorizontalProductList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomCheckoutBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(
    BuildContext context,
    bool isDark,
    Color themeTextColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.product['title'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: themeTextColor,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final text = 'share_product'.trParams({'product': widget.product['title']?.toString() ?? ''});
                try {
                  await Share.share(text);
                } catch (_) {
                  Get.snackbar(
                    'share'.tr,
                    'link_copied'.tr,
                    backgroundColor: AppTheme.primary,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    margin: const EdgeInsets.all(16),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.share2,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() => _isLiked = !_isLiked);
                final favController = Get.find<FavoritesController>();
                favController.toggleFavorite(widget.product['id'].toString());
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() {
                  final favController = Get.find<FavoritesController>();
                  final isFav = favController.isFavorite(
                    widget.product['id'].toString(),
                  );
                  return Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.grey.shade400,
                    size: 22,
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    bool isDark,
    Color themeTextColor,
    Color themeTextSecColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatPrice(widget.product['price'])}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppTheme.emeraldLight
                        : AppTheme.primaryDark,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'currency_iqd'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: themeTextSecColor.withOpacity(0.6),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'per_unit'.trParams({'unit': (widget.product['unit'] ?? 'unit_kg'.tr)}),
                  style: TextStyle(
                    fontSize: 11,
                    color: themeTextSecColor.withOpacity(0.6),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isDecimalUnit ? Colors.blue.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.product['unit']?.toString() ?? (_isDecimalUnit ? 'unit_kg'.tr : 'unit_piece'.tr),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isDecimalUnit ? Colors.blue : Colors.amber.shade800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ProductQuantitySelector(
          quantity: _quantity,
          maxStock: (widget.product['stock'] as num?) ?? 0,
          onDecrement: () {
            if (_quantity > _qtyStep) setState(() => _quantity -= _qtyStep);
          },
          onIncrement: () {
            final num stock = (widget.product['stock'] as num?) ?? 0;
            if (_quantity >= stock) {
              Get.snackbar(
                'quantity_not_available'.tr,
                'available_quantity_stock'.trParams({'stock': stock.toString()}),
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange.shade700,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
              );
              return;
            }
            setState(() => _quantity += _qtyStep);
          },
        ),
      ],
    );
  }

  Widget _buildDescription(
    BuildContext context,
    bool isDark,
    Color themeTextColor,
    Color themeTextSecColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'description'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeTextColor,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          (widget.product['description']?.toString().isNotEmpty == true)
              ? widget.product['description'].toString()
              : 'no_description'.tr,
          style: TextStyle(
            fontSize: 13.5,
            color: themeTextSecColor,
            height: 1.6,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedHeader(
    BuildContext context,
    bool isDark,
    Color themeTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'other_fresh_products'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: themeTextColor,
            fontFamily: 'Cairo',
          ),
        ),
        GestureDetector(
          onTap: () => Get.back(),
          child: Text(
            'see_all'.tr,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProductList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimary;
    final related = homeController.allProducts
        .where((p) => p['id'] != widget.product['id'])
        .take(4)
        .toList();

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: related.length,
        itemBuilder: (context, index) {
          final item = related[index];
          final productData = {
            'id': item['id'],
            'title': item['name'],
            'price': item['price'],
            'image': item['image_url'],
            'category': item['category'],
            'unit': item['unit'] ?? 'unit_piece'.tr,
            'unit_type': item['unit_type']?.toString() ?? 'kilogram',
          };
          return GestureDetector(
            onTap: () => Get.off(
              () => ProductDetailsScreen(product: productData),
              preventDuplicates: false,
            ),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade100,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green.withOpacity(0.1)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: item['image_url'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: themeTextColor,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${formatPrice(item['price'])} ${'currency_iqd'.tr}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppTheme.emeraldLight
                          : AppTheme.primaryDark,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomCheckoutBar() {
    final double totalPrice = widget.product['price'] * _quantity;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextSecColor = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              final int stock = (widget.product['stock'] as num?)?.toInt() ?? 0;
              if (stock == 0) return;
              if (_quantity > stock) {
                Get.snackbar(
                  'quantity_not_available'.tr,
                  'available_quantity_stock'.trParams({'stock': stock.toString()}),
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.orange.shade700,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
                return;
              }
              cartController.addToCart(widget.product, qty: _quantity);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: (widget.product['stock'] == 0)
                    ? Colors.grey
                    : AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (widget.product['stock'] != 0)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    (widget.product['stock'] == 0)
                        ? LucideIcons.xCircle
                        : LucideIcons.shoppingBag,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (widget.product['stock'] == 0)
                        ? 'out_of_stock_button'.tr
                        : 'add_to_cart'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'total_price'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: themeTextSecColor,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${formatPrice(totalPrice)} ${'currency_iqd'.tr}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppTheme.emeraldLight : AppTheme.primaryDark,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
