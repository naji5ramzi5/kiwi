import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../../controllers/cart_controller.dart';

import '../../controllers/auth_controller.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());
    final AuthController authController = Get.put(AuthController());

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('cart'.tr),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => cartController.clearCart(),
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
          ),
        ],
      ),
      body: Obx(() {
        if (cartController.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.shoppingCart, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text('سلتك فارغة حالياً', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 250), // bottom padding for checkout sheet
              physics: const BouncingScrollPhysics(),
              itemCount: cartController.cartItems.length,
              itemBuilder: (context, index) {
                final item = cartController.cartItems.values.toList()[index];
                final String id = item['id'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: item['image'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[100]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item['price']} د.ع',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                                ),
                                Row(
                                  children: [
                                    _buildQuantityBtn(
                                      LucideIcons.minus,
                                      onTap: () => cartController.removeFromCart(id),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      item['quantity'].toString(),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildQuantityBtn(
                                      LucideIcons.plus,
                                      isPrimary: true,
                                      onTap: () => cartController.addToCart(item),
                                    ),
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
              },
            ),
            
            // Checkout Bottom Sheet
            Positioned(
              bottom: 110, // padding for the floating nav bar
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSummaryRow('المجموع الفرعي', '${cartController.subtotal} د.ع'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('رسوم التوصيل', '${cartController.deliveryFee} د.ع'),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي الكلي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text(
                          '${cartController.total} د.ع',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _OrderConfirmButton(
                      onConfirm: () async {
                        if (!Get.find<AuthController>().isLoggedIn) {
                          _showGuestLoginDialog(context);
                        } else {
                          final success = await cartController.placeOrder(
                            address: 'بغداد - الكرادة',
                            paymentMethod: 'Cash on Delivery',
                          );
                          if (success) {
                            _showOrderSuccessDialog(context);
                          }
                        }
                      },
                      isLoading: cartController.isPlacingOrder.value,
                    ),

                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildQuantityBtn(IconData icon, {bool isPrimary = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: isPrimary ? Colors.white : AppTheme.textPrimary),
      ),
    );
  }

  void _showGuestLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.userX, size: 48, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                const Text(
                  'يرجى تسجيل الدخول',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'يجب عليك إنشاء حساب أو تسجيل الدخول لإتمام عملية الشراء.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
                  ),
                  child: const Text('تسجيل الدخول / إنشاء حساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.checkCircle2, size: 60, color: AppTheme.primary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'شكراً لطلبك!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'تم استلام طلبك بنجاح وهو الآن قيد المراجعة. يمكنك تتبع حالة الطلب من صفحة طلباتي.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Get.back(); // close dialog
                    // We should navigate to tracking or home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('تتبع الطلب الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('الرجوع للرئيسية', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderConfirmButton extends StatefulWidget {
  final VoidCallback onConfirm;
  final bool isLoading;

  const _OrderConfirmButton({required this.onConfirm, required this.isLoading});

  @override
  State<_OrderConfirmButton> createState() => _OrderConfirmButtonState();
}

class _OrderConfirmButtonState extends State<_OrderConfirmButton> with TickerProviderStateMixin {
  bool _isCountingDown = false;
  late AnimationController _progressController;
  int _secondsRemaining = 6;
  late var _timer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _secondsRemaining = 6;
    });
    _progressController.reverse(from: 1.0);
    _timer = Stream.periodic(const Duration(seconds: 1), (i) => 5 - i).take(6).listen((val) {
      setState(() => _secondsRemaining = val);
      if (val == 0) {
        setState(() => _isCountingDown = false);
        widget.onConfirm();
      }
    });
  }

  void _cancelCountdown() {
    _timer.cancel();
    _progressController.stop();
    setState(() {
      _isCountingDown = false;
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(18)),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_isCountingDown) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _cancelCountdown,
              child: Container(
                height: 54,
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.red[100]!)),
                child: const Center(child: Text('إلغاء وتعديل', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  height: 54,
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(18)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) => LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.transparent,
                        color: Colors.white.withOpacity(0.2),
                        minHeight: 54,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      'تأكيد تلقائي خلال $_secondsRemaining ث',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: _startCountdown,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: const Text('تأكيد الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}

