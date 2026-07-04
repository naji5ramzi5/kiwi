import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/favorites_controller.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  final CartController cartController = Get.find<CartController>();
  final HomeController homeController = Get.find<HomeController>();
  bool _isLiked = false;

  Widget _buildQtyButton(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.green : const Color(0xFFE8E8E8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: isPrimary ? Colors.white : Colors.black54),
      ),
    );
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double overlap = 25;
    final double curveRadius = 45;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;
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
                  // Product Image with curved bottom
                  ClipPath(
                    clipper: _CurvedBottomClipper(curveHeight: curveRadius, overlap: overlap),
                    child: Container(
                      height: screenHeight * 0.50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Container(
                            color: isDark ? const Color(0xFF0F2D1A) : const Color(0xFFF0FDF4),
                            child: Hero(
                              tag: widget.product['id'],
                              child: CachedNetworkImage(
                                imageUrl: widget.product['image'],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: isDark ? const Color(0xFF1C2B1E) : const Color(0xFFF0FDF4),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 40, height: 40,
                                      child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Gradient overlay for readability
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          // Back Button - RIGHT SIDE (RTL)
                          Positioned(
                            top: 50,
                            right: 20,
                            child: GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.surfaceDark.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppTheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Curved overlapping white content container
                  Transform.translate(
                    offset: Offset(0, -overlap),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(curveRadius)),
                      ),
                      padding: EdgeInsets.fromLTRB(24, overlap + 20, 24, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Heart
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product['title'],
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: themeTextColor,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      // Share product using system share
                                      final text = 'تسوق ${widget.product['title']} من Kiwi!';
                                      try {
                                        await Share.share(text);
                                      } catch (_) {
                                        Get.snackbar('مشاركة', 'تم نسخ الرابط', backgroundColor: AppTheme.primary, colorText: Colors.white, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16));
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.surfaceDark : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                                      ),
                                      child: Icon(LucideIcons.share2, color: AppTheme.primary, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _isLiked = !_isLiked);
                                      // Toggle favorite via FavoritesController
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
                                          )
                                        ],
                                      ),
                                      child: Obx(() {
                                        final favController = Get.find<FavoritesController>();
                                        final isFav = favController.isFavorite(widget.product['id'].toString());
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
                          ),
                          const SizedBox(height: 20),

                          // Price and Qty controller
                          Row(
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
                                          color: isDark ? const Color(0xFF34D399) : AppTheme.primaryDark,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'د.ع',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: themeTextSecColor.withOpacity(0.6),
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'لـ 1 ${widget.product['unit'] ?? 'كغ'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: themeTextSecColor.withOpacity(0.6),
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    _buildQtyButton(LucideIcons.minus, () {
                                      if (_quantity > 1) setState(() => _quantity--);
                                    }),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Text(
                                        '$_quantity',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: themeTextColor,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                    _buildQtyButton(LucideIcons.plus, () {
                                      setState(() => _quantity++);
                                    }, isPrimary: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'التفاصيل',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeTextColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            widget.product['title'] != null
                                ? 'منتج ${widget.product['title']} طازج ومختار بعناية فائقة، غني بالمواد الغذائية والفيتامينات الهامة، يصلك طازجاً من المزرعة مباشرة.'
                                : 'خضروات طازجة ومختارة بعناية فائقة من المزرعة مباشرة إلى مطبخك. غنية بالمواد الغذائية والفيتامينات الهامة لصحة عائلتك.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: themeTextSecColor,
                              height: 1.6,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),

                          // Fresh products header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'منتجات طازجة أخرى',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: themeTextColor,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Get.back(),
                                child: const Text(
                                  'عرض الكل',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildHorizontalProductList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Bottom Bar
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

  Widget _buildHorizontalProductList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;

    final related = homeController.allProducts.where((p) => p['id'] != widget.product['id']).take(4).toList();
    
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
            'unit': item['unit'] ?? 'حبة',
          };

          return GestureDetector(
            onTap: () {
              Get.off(() => ProductDetailsScreen(product: productData), preventDuplicates: false);
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green.withOpacity(0.1) : const Color(0xFFF0FDF4),
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
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeTextColor, fontFamily: 'Cairo'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${formatPrice(item['price'])} د.ع',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF34D399) : AppTheme.primaryDark, fontFamily: 'Cairo'),
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
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

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
          )
        ],
        border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Add to cart (on the right in RTL, which is first child)
          GestureDetector(
            onTap: () {
              int stock = widget.product['stock'] ?? 10;
              if (stock == 0) return;
              cartController.addToCart(widget.product, qty: _quantity);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: (widget.product['stock'] == 0) ? Colors.grey : AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (widget.product['stock'] != 0)
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    (widget.product['stock'] == 0) ? LucideIcons.xCircle : LucideIcons.shoppingBag, 
                    color: Colors.white, 
                    size: 18
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (widget.product['stock'] == 0) ? 'نفدت الكمية' : 'إضافة إلى السلة',
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
                'السعر الإجمالي',
                style: TextStyle(fontSize: 12, color: themeTextSecColor, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              ),
              Text(
                '${formatPrice(totalPrice)} د.ع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF34D399) : Colors.green, fontFamily: 'Cairo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  final double curveHeight;
  final double overlap;

  _CurvedBottomClipper({this.curveHeight = 45, this.overlap = 25});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - curveHeight)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height - curveHeight + overlap,
        size.width,
        size.height - curveHeight,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
