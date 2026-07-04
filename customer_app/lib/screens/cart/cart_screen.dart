import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/main_screen_controller.dart';
import '../order_details_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartController cartController;
  late final AuthController authController;
  int _countdown = 6;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController());
    authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() async {
    if (!authController.isLoggedIn) {
      _showGuestLoginDialog();
      return;
    }

    final activeId = await cartController.getActiveOrderId();
    if (activeId != null) {
      Get.snackbar(
        'لديك طلب نشط',
        'أنهي الطلب الحالي أولاً قبل إنشاء طلب جديد',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () {
            Get.back();
            Get.to(() => OrderDetailsScreen(orderId: activeId), transition: Transition.fadeIn);
          },
          child: const Text('عرض الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    setState(() => _countdown = 6);
    cartController.isCountingDown(true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        _confirmOrder();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    cartController.isCountingDown(false);
    setState(() => _countdown = 6);
  }

  Future<void> _confirmOrder() async {
    _countdownTimer?.cancel();
    cartController.isCountingDown(false);
    setState(() => _countdown = 6);
    final success = await cartController.placeOrder(
      address: 'بغداد - الكرادة',
      paymentMethod: 'Cash on Delivery',
    );
    if (success) {
      await cartController.refreshActiveOrder();
      Get.to(() => OrderDetailsScreen(orderId: cartController.lastOrderId.value), transition: Transition.fadeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeTextColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final themeTextSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'السلة',
          style: TextStyle(color: themeTextColor, fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
      ),
      body: Obx(() {
        return PopScope(
          canPop: !cartController.isCountingDown.value,
          child: Builder(builder: (context) {
            if (cartController.cartItems.isEmpty) {
              return _buildEmptyState(isDark, themeTextColor, themeTextSecColor);
            }
            return _buildCartWithItems(isDark, themeTextColor, themeTextSecColor);
          }),
        );
      }),
    );
  }

  Widget _buildEmptyState(bool isDark, Color themeTextColor, Color themeTextSecColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(LucideIcons.shoppingBag, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Text(
            'سلتك فارغة حالياً',
            style: TextStyle(fontSize: 24, color: themeTextColor, fontFamily: 'Cairo', fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            'أضف منتجاتك المفضلة واطلب الآن',
            style: TextStyle(fontSize: 14, color: themeTextSecColor, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => Get.find<MainScreenController>().switchTab(0),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
              shadowColor: AppTheme.primary.withOpacity(0.4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.shoppingBag, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'تسوق الآن',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems(bool isDark, Color themeTextColor, Color themeTextSecColor) {
    return Stack(
      children: [
        Column(
          children: [
            if (cartController.hasActiveOrder)
              _buildActiveOrderBanner(isDark),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                physics: const BouncingScrollPhysics(),
                itemCount: cartController.cartItems.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeaderSummary(isDark);
                  }
                  final item = cartController.cartItems.values.toList()[index - 1];
                  return _buildCartItem(item, isDark, themeTextColor, themeTextSecColor);
                },
              ),
            ),
            _buildCheckoutPanel(isDark, themeTextColor, themeTextSecColor),
          ],
        ),
        if (cartController.isCountingDown.value)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E291F) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            '$_countdown',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'سيتم تأكيد الطلب تلقائياً',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        'إجمالي الطلب: ${cartController.total} د.ع',
                        style: TextStyle(
                          fontSize: 13,
                          color: themeTextSecColor,
                          fontFamily: 'Cairo',
                        ),
                      )),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'تأكيد الآن',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelCountdown,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveOrderBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.truck, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'لديك طلب نشط — يمكنك تعديل السلة ولكن لا يمكن إنشاء طلب جديد حالياً',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSummary(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.shoppingCart, size: 20, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(
            '${cartController.itemCount} منتجات في سلتك',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF4ADE80) : AppTheme.primaryDark,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, bool isDark, Color themeTextColor, Color themeTextSecColor) {
    final String id = item['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: item['image'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: isDark ? Colors.grey[850] : Colors.grey[100]),
              errorWidget: (_, __, ___) => const Icon(LucideIcons.image, size: 30, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['title'],
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: themeTextColor, fontFamily: 'Cairo'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => cartController.removeFromCart(id, removeAll: true),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(LucideIcons.x, size: 14, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['unit'] ?? 'كغ'}',
                  style: TextStyle(fontSize: 11, color: themeTextSecColor, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['price']} د.ع',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFF4ADE80) : AppTheme.primaryDark,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Row(
                      children: [
                        _buildQuantityBtn(LucideIcons.minus, onTap: () => cartController.removeFromCart(id)),
                        const SizedBox(width: 12),
                        Obx(() => Text(
                          '${cartController.cartItems[id]?['quantity'] ?? item['quantity']}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: themeTextColor, fontFamily: 'Cairo'),
                        )),
                        const SizedBox(width: 12),
                        _buildQuantityBtn(LucideIcons.plus, isPrimary: true, onTap: () => cartController.addToCart(item, showPopup: false)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBtn(IconData icon, {bool isPrimary = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primary : (isDark ? Colors.grey.shade800 : AppTheme.background),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isPrimary
              ? Colors.white
              : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary),
        ),
      ),
    );
  }

  Widget _buildCheckoutPanel(bool isDark, Color themeTextColor, Color themeTextSecColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow(isDark, themeTextColor, themeTextSecColor, 'المجموع الفرعي', '${cartController.subtotal} د.ع'),
            const SizedBox(height: 10),
            _buildSummaryRow(isDark, themeTextColor, themeTextSecColor, 'رسوم التوصيل', '${cartController.deliveryFee} د.ع'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(LucideIcons.leaf, size: 16, color: AppTheme.primary),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي الكلي',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: themeTextColor, fontFamily: 'Cairo'),
                ),
                Text(
                  '${cartController.total} د.ع',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Cairo'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Obx(() => _OrderConfirmButton(
              onConfirm: _startCountdown,
              isLoading: cartController.isPlacingOrder.value,
              disabled: cartController.hasActiveOrder,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(bool isDark, Color themeTextColor, Color themeTextSecColor, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: themeTextSecColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: themeTextColor, fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  void _showGuestLoginDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.userX, size: 48, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                const Text(
                  'يرجى تسجيل الدخول',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'يجب عليك إنشاء حساب أو تسجيل الدخول لإتمام عملية الشراء.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontFamily: 'Cairo'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.to(() => const LoginScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'تسجيل الدخول / إنشاء حساب',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderConfirmButton extends StatelessWidget {
  final VoidCallback onConfirm;
  final bool isLoading;
  final bool disabled;

  const _OrderConfirmButton({required this.onConfirm, required this.isLoading, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(18)),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return ElevatedButton(
      onPressed: disabled ? null : onConfirm,
      style: ElevatedButton.styleFrom(
        backgroundColor: disabled ? Colors.grey : AppTheme.primary,
        disabledBackgroundColor: Colors.grey.shade300,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: Text(
        disabled ? 'لديك طلب نشط' : 'تأكيد الطلب',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: disabled ? Colors.grey.shade600 : Colors.white, fontFamily: 'Cairo'),
      ),
    );
  }
}
