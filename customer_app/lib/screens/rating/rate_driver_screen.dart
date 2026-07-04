import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  Future<void> _submitRating() async {
    if (_rating == 0) return;
    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('driver_ratings').insert({
        'order_id': widget.orderId,
        'driver_id': widget.driverId,
        'user_id': user.id,
        'rating': _rating,
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        Get.snackbar(
          'شكراً لك!',
          'تقييمك يساعدنا في تحسين الخدمة',
          backgroundColor: AppTheme.primary,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        Get.back(result: true);
      }
    } catch (e) {
      Get.snackbar(
        'حدث خطأ',
        'لم نتمكن من حفظ تقييمك',
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
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'تم التوصيل بنجاح!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'كيف كانت تجربتك مع المندوب؟',
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
                          color: const Color(0xFF10B981).withOpacity(0.3),
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
                      'مندوب توصيل',
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
                      _rating == 0 ? 'اضغط على نجمة للتقييم' :
                      _rating == 1 ? 'سيء' :
                      _rating == 2 ? 'مقبول' :
                      _rating == 3 ? 'جيد' :
                      _rating == 4 ? 'جيد جداً' :
                      'ممتاز',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _rating >= 4
                            ? const Color(0xFF10B981)
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
                          hintText: 'أضف تعليقاً (اختياري)',
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

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _rating > 0 && !_isSubmitting
                            ? _submitRating
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF10B981).withOpacity(0.4),
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
                            : const Text(
                                'إرسال التقييم',
                                style: TextStyle(
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
                        'تخطي',
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
