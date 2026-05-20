import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_viewer.dart';
import '../../controllers/cart_controller.dart';
import 'dart:ui';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  final CartController cartController = Get.find<CartController>();
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge and Category
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'طازج يومياً',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.product['category'] ?? 'خضروات وفواكه',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Title and Heart
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.product['title'],
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
                            ),
                          ),
                          _buildGlassIconButton(
                            icon: _isLiked ? LucideIcons.heart : LucideIcons.heart,
                            color: _isLiked ? Colors.red : AppTheme.textSecondary,
                            onPressed: () => setState(() => _isLiked = !_isLiked),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${widget.product['price']}',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                          ),
                          const SizedBox(width: 4),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text('د.ع', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              '/ ${widget.product['unit']}',
                              style: TextStyle(fontSize: 16, color: Colors.grey[400], fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Section Tabs (Apple Style)
                      const Text(
                        'وصف المنتج',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'هذا المنتج يأتيكم مباشرة من مزارع "فرش" المختارة بعناية. يتم الفحص والتعبئة تحت إشراف خبرائنا لضمان وصولها لمطبخكم بأفضل جودة وقيمة غذائية. مثالي لتحضير الوجبات الصحية واللذيذة.',
                        style: TextStyle(fontSize: 15, height: 1.8, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Features
                      Row(
                        children: [
                          _buildFeatureCard(LucideIcons.leaf, 'عضوي 100%'),
                          const SizedBox(width: 12),
                          _buildFeatureCard(LucideIcons.truck, 'توصيل سريع'),
                          const SizedBox(width: 12),
                          _buildFeatureCard(LucideIcons.shieldCheck, 'ضمان الجودة'),
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      
                      const Text(
                        'قد يعجبك أيضاً',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 20),
                      _buildSimilarProducts(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Fixed Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildAppleBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 20),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildGlassIconButton(
          icon: LucideIcons.arrowRight,
          color: AppTheme.textPrimary,
          onPressed: () => Get.back(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Get.to(() => ImageViewer(imageUrl: widget.product['image'], tag: widget.product['id'])),
              child: Hero(
                tag: widget.product['id'],
                child: CachedNetworkImage(
                  imageUrl: widget.product['image'],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.white,
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
            ),
            // Shadow overlay for the title when scrolled
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white.withOpacity(0.8), Colors.white],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleBottomBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border(top: BorderSide(color: Colors.grey[100]!)),
          ),
          child: Row(
            children: [
              // Quantity Selector
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildQtyBtn(LucideIcons.minus, () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1)),
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text('$_quantity', key: ValueKey(_quantity), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    _buildQtyBtn(LucideIcons.plus, () => setState(() => _quantity++)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Add to Cart Button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    for (int i = 0; i < _quantity; i++) cartController.addToCart(widget.product);
                    _showSuccessDialog();
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'إضافة للسلة',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }

  void _showSuccessDialog() {
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, size: 40, color: AppTheme.primary),
                ),
                const SizedBox(height: 24),
                const Text('تمت الإضافة!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text('تمت إضافة ${widget.product['title']} إلى سلة مشترياتك بنجاح', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], height: 1.5)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text('متابعة التسوق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarProducts() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[50]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: CachedNetworkImage(
                      imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=300&q=80',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('منتج مشابه', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1),
                      const SizedBox(height: 4),
                      Text('1,250 د.ع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryDark)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
