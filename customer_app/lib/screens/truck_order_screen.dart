import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class TruckOrderScreen extends StatefulWidget {
  const TruckOrderScreen({super.key});

  @override
  State<TruckOrderScreen> createState() => _TruckOrderScreenState();
}

class _TruckOrderScreenState extends State<TruckOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Get.back();
    
    Get.snackbar(
      'تم إرسال طلبك بنجاح 🎉',
      'تم استلام طلب الشاحنة، سنتواصل معك هاتفياً خلال دقائق لتأكيد تفاصيل الشحن.',
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      icon: const Icon(LucideIcons.checkCircle, color: Colors.white),
    );
  }

  @override
  void dispose() {
    _productsController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final cardBgColor = isDark ? const Color(0xFF1E291F) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'طلب شاحنة جملة',
          style: TextStyle(
            color: themeTextColor,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeTextColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Hero card with delivery truck image
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(isDark ? 0.15 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF0F2D1A), const Color(0xFF1B3D25)]
                                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        // Right-aligned nice graphical elements
                        Positioned(
                          left: -20,
                          bottom: -20,
                          child: CircleAvatar(
                            radius: 90,
                            backgroundColor: AppTheme.primary.withOpacity(isDark ? 0.05 : 0.1),
                          ),
                        ),
                        // Truck image or fallback icon
                        Positioned(
                          left: 10,
                          bottom: 10,
                          top: 10,
                          right: 140, // occupy left area
                          child: Image.asset(
                            'assets/images/delivery_truck.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(LucideIcons.truck, size: 70, color: AppTheme.primary);
                            },
                          ),
                        ),
                        // Title inside card
                        Positioned(
                          right: 24,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'توصيل سريع',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? const Color(0xFF34D399) : AppTheme.primaryDark,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'للطلبات الكبيرة والجملة',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: themeTextColor.withOpacity(0.8),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(isDark ? 0.1 : 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.info, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'احصل على أسعار مخفضة وخدمة شحن متكاملة ومباشرة للكميات الكبيرة من أسواقنا.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF34D399) : AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'بيانات طلب الشحن',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: themeTextColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),

                // Inputs card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildField(
                        label: 'المنتجات المطلوبة والكميات',
                        hint: 'مثال: صندوق طماطم 50كغم، كيس بصل 100كغم',
                        controller: _productsController,
                        icon: LucideIcons.shoppingBag,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال المنتجات المطلوبة' : null,
                      ),
                      const SizedBox(height: 20),

                      _buildField(
                        label: 'رقم الهاتف للتواصل المعزز',
                        hint: '07X XXXX XXXX',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        icon: LucideIcons.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
                          if (v.trim().length < 10) return 'الرجاء إدخال رقم هاتف صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildField(
                        label: 'ملاحظات إضافية أو تفاصيل العنوان',
                        hint: 'موقع المخزن، الوقت المفضل للوصول...',
                        controller: _notesController,
                        icon: LucideIcons.fileText,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Premium Gradient Submit Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryDark],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        height: 54,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.truck, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'إرسال طلب الشاحنة الآن',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: themeTextColor,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: themeTextColor, fontFamily: 'Cairo', fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: themeTextSecColor.withOpacity(0.4), fontFamily: 'Cairo', fontSize: 13),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
            filled: true,
            fillColor: isDark ? const Color(0xFF141F15) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
