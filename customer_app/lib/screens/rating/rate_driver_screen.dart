import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class RateDriverScreen extends StatefulWidget {
  final String orderId;
  final String driverId;
  final String driverName;
  final String? driverImage;

  const RateDriverScreen({
    super.key,
    required this.orderId,
    required this.driverId,
    required this.driverName,
    this.driverImage,
  });

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int _rating = 0;
  int _hoverRating = 0;
  int _branchRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  // product_id -> rating
  final Map<String, int> _productRatings = {};
  List<Map<String, dynamic>> _orderProducts = [];
  String? _branchId;

  @override
  void initState() {
    super.initState();
    _loadOrderProducts();
  }

  Future<void> _loadOrderProducts() async {
    try {
      final order = await Supabase.instance.client
          .from('orders')
          .select('branch_id, order_items(product_id, product_name, image_url, products(id, name, image, unit))')
          .eq('id', widget.orderId)
          .single();
      _branchId = order['branch_id']?.toString();
      final items = (order['order_items'] as List? ?? []);
      final products = <Map<String, dynamic>>[];
      for (final item in items) {
        final p = item['products'] is Map ? item['products'] as Map<String, dynamic> : null;
        final productId = (p?['id'] ?? item['product_id'])?.toString() ?? '';
        if (productId.isEmpty) continue;
        products.add({
          'product_id': productId,
          'name': (p?['name'] ?? item['product_name'] ?? 'product_fallback'.tr).toString(),
          'image': (p?['image'] ?? item['image_url'] ?? '').toString(),
        });
      }
      if (mounted) setState(() => _orderProducts = products);
    } catch (e) {
      // non-fatal: product rating is optional
      print('Error loading order products: $e');
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) return;
    setState(() => _isSubmitting = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Driver rating
      await client.from('driver_ratings').insert({
        'order_id': widget.orderId,
        'driver_id': widget.driverId,
        'customer_id': user.id,
        'rating': _rating,
        'review': _commentController.text.trim(),
      });

      // Product ratings
      for (final p in _orderProducts) {
        final r = _productRatings[p['product_id']];
        if (r != null && r > 0) {
          try {
            await client.from('product_ratings').insert({
              'order_id': widget.orderId,
              'product_id': p['product_id'],
              'user_id': user.id,
              if (_branchId != null) 'branch_id': _branchId,
              'rating': r,
            });
          } catch (e) {
            print('Product rating insert failed: $e');
          }
        }
      }

      // Branch rating
      if (_branchRating > 0 && _branchId != null) {
        try {
          await client.from('branch_ratings').insert({
            'order_id': widget.orderId,
            'branch_id': _branchId,
            'user_id': user.id,
            'rating': _branchRating,
          });
        } catch (e) {
          print('Branch rating insert failed: $e');
        }
      }

      if (mounted) {
        Get.snackbar(
          'thank_you'.tr,
          'rating_helps'.tr,
          backgroundColor: AppTheme.primary,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        Get.back(result: true);
      }
    } catch (e) {
      Get.snackbar(
        'error_occurred_short'.tr,
        'rating_save_failed'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Checkmark illustration
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.emerald,
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'delivery_successful'.tr,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'driver_experience'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'Cairo',
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Driver avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.emerald.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: widget.driverImage != null
                            ? NetworkImage(widget.driverImage!)
                            : null,
                        child: widget.driverImage == null
                            ? Text(
                                widget.driverName.isNotEmpty
                                    ? widget.driverName[0]
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      widget.driverName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: AppTheme.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'delivery_driver'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontFamily: 'Cairo',
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isFilled = starIndex <= (_hoverRating > 0 ? _hoverRating : _rating);
                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoverRating = starIndex),
                          onExit: (_) => setState(() => _hoverRating = 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _rating = starIndex),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 150),
                                scale: isFilled ? 1.1 : 1.0,
                                child: Icon(
                                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 44,
                                  color: isFilled ? Colors.amber : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _rating == 0 ? 'tap_star_rate'.tr :
                      _rating == 1 ? 'rating_bad'.tr :
                      _rating == 2 ? 'rating_acceptable'.tr :
                      _rating == 3 ? 'rating_good'.tr :
                      _rating == 4 ? 'rating_very_good'.tr :
                      'rating_excellent'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _rating >= 4
                            ? AppTheme.emerald
                            : _rating >= 2
                                ? Colors.amber.shade700
                                : Colors.red.shade400,
                        fontFamily: 'Cairo',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Comment
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: TextField(
                        controller: _commentController,
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'add_comment'.tr,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontFamily: 'Cairo',
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Branch rating
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceDark : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'branch_rating'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final star = index + 1;
                              final filled = star <= _branchRating;
                              return GestureDetector(
                                onTap: () => setState(() => _branchRating = star),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 36,
                                    color: filled ? Colors.amber : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Product ratings
                    if (_orderProducts.isNotEmpty) ...[
                      Text(
                        'product_ratings'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._orderProducts.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.surfaceDark : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            if ((p['image'] as String).isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  p['image'] as String,
                                  width: 44, height: 44, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 44, height: 44,
                                    color: AppTheme.primary.withOpacity(0.1),
                                    child: const Icon(LucideIcons.image, size: 18, color: AppTheme.primary),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.package, size: 18, color: AppTheme.primary),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p['name'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: List.generate(5, (index) {
                                final star = index + 1;
                                final current = _productRatings[p['product_id']] ?? 0;
                                final filled = star <= current;
                                return GestureDetector(
                                  onTap: () => setState(() => _productRatings[p['product_id']] = star),
                                  child: Icon(
                                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 24,
                                    color: filled ? Colors.amber : Colors.grey.shade300,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      )),
                    ],

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _rating > 0 && !_isSubmitting
                            ? _submitRating
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.emerald.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'submit_rating'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Skip button
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: Text(
                        'skip'.tr,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontFamily: 'Cairo',
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

