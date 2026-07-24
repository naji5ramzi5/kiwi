import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/main_screen_controller.dart';
import '../../controllers/home_controller.dart';
import '../order_details_screen.dart';
import 'cart_item_widget.dart';
import 'cart_checkout_panel.dart';

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

    final homeController = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;
    if (homeController != null && !homeController.isInDeliveryZone.value) {
      Get.snackbar(
        'outside_delivery_zone'.tr,
        'location_outside_msg'.tr,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final activeId = await cartController.getActiveOrderId();
    if (activeId != null) {
      Get.snackbar(
        'active_order'.tr,
        'finish_current_order'.tr,
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
          child: Text('view_order'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final homeController = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;
    final String address = (homeController != null && homeController.userAddress.value.isNotEmpty)
        ? homeController.userAddress.value
        : (homeController?.selectedBranch.value?['address']?.toString() ?? 'unspecified'.tr);
    final success = await cartController.placeOrder(
      address: address,
      paymentMethod: 'cash_on_delivery'.tr,
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
          'cart'.tr,
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
            'cart_empty'.tr,
            style: TextStyle(fontSize: 24, color: themeTextColor, fontFamily: 'Cairo', fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            'cart_empty_subtitle'.tr,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.shoppingBag, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'shop_now'.tr,
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
                  return CartItemWidget(
                    item: item,
                    isDark: isDark,
                    themeTextColor: themeTextColor,
                    themeTextSecColor: themeTextSecColor,
                    quantity: cartController.cartItems[item['id']]?['quantity'] ?? item['quantity'],
                    onRemoveAll: () => cartController.removeFromCart(item['id'], removeAll: true),
                    onRemove: () => cartController.removeFromCart(item['id']),
                    onAdd: () => cartController.addToCart(item, showPopup: false),
                  );
                },
              ),
            ),
            CartCheckoutPanel(
              isDark: isDark,
              themeTextColor: themeTextColor,
              themeTextSecColor: themeTextSecColor,
              subtotal: '${cartController.subtotal}',
              deliveryFee: '${cartController.deliveryFee}',
              discount: '${cartController.discountAmount.value.toInt()}',
              total: '${cartController.total}',
              isPlacingOrder: cartController.isPlacingOrder.value,
              hasActiveOrder: cartController.hasActiveOrder,
              onStartCountdown: _startCountdown,
              couponController: cartController.couponTextController,
              onApplyCoupon: () async {
                final ok = await cartController.applyCoupon();
                if (!ok && cartController.couponError.value.isNotEmpty) {
                  // error already stored in controller; could surface if needed
                }
              },
              onRemoveCoupon: cartController.removeCoupon,
              hasCoupon: cartController.appliedCoupon.value != null,
              isApplyingCoupon: cartController.isApplyingCoupon.value,
              couponError: cartController.couponError.value,
              couponLabel: cartController.appliedCoupon.value?['code'] ?? '',
              belowMinOrder: cartController.isBelowMinOrder,
              minOrderHint: cartController.minOrderAmount > 0
                  ? 'min_order_amount'.trParams({'amount': cartController.minOrderAmount.toInt().toString()})
                  : '',
            ),
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
                      Text(
                        'order_auto_confirm'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        'order_total'.trParams({'total': cartController.total.toString()}),
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
                              child: Text(
                                'confirm_now'.tr,
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
                              child: Text(
                                'cancel'.tr,
                                style: const TextStyle(
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
              'active_order_banner'.tr,
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
            'items_in_cart'.trParams({'count': cartController.itemCount.toString()}),
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.primaryBright : AppTheme.primaryDark,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
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
                Text(
                  'please_sign_in'.tr,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'sign_in_required'.tr,
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
                  child: Text(
                    'sign_in_or_create'.tr,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'cancel'.tr,
                    style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
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
