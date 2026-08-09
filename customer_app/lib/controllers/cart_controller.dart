import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_controller.dart';
import 'home_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/added_to_cart_dialog.dart';

class CartController extends GetxController {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();
  final _box = GetStorage();

  final TextEditingController couponTextController = TextEditingController();

  var cartItems = <String, Map<String, dynamic>>{}.obs;
  var cartVersion = 0.obs;
  var isPlacingOrder = false.obs;
  var isCountingDown = false.obs;
  var lastOrderId = ''.obs;
  var activeOrderId = Rxn<String>();

  // Coupon / discount
  var couponCode = ''.obs;
  var discountAmount = 0.0.obs;
  var appliedCoupon = Rxn<Map<String, dynamic>>();
  var isApplyingCoupon = false.obs;
  var couponError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    couponTextController.addListener(() {
      couponCode.value = couponTextController.text;
    });
    _loadCart();
    refreshActiveOrder();
    _subscribeToOrderUpdates();
  }

  @override
  void onClose() {
    couponTextController.dispose();
    super.onClose();
  }

  /// Subscribe to realtime updates for the customer's orders
  void _subscribeToOrderUpdates() {
    final userId = authController.currentUser.value?.id;
    if (userId == null) return;

    supabase
        .channel('customer-orders-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: (payload) {
            // Refresh active order when any of customer's orders change
            refreshActiveOrder();
          },
        )
        .subscribe();
  }

  Future<void> refreshActiveOrder() async {
    try {
      final id = await getActiveOrderId();
      activeOrderId.value = id;
    } catch (_) {
      activeOrderId.value = null;
    }
  }

  void _loadCart() {
    final stored = _box.read<List>('cart_items');
    if (stored != null) {
      final map = <String, Map<String, dynamic>>{};
      for (final item in stored) {
        if (item is Map) {
          final id = item['id'].toString();
          map[id] = Map<String, dynamic>.from(item);
        }
      }
      cartItems.value = map;
    }
    cartItems.refresh();
    cartVersion.value++;
  }

  void _saveCart() {
    _box.write('cart_items', cartItems.values.toList());
  }

  void addToCart(
    Map<String, dynamic> product, {
    num qty = 1,
    bool showPopup = true,
  }) {
    final String id = product['id'].toString();
    final num? stock = product['stock'] != null
        ? (product['stock'] as num)
        : null;

    final num currentQty = cartItems.containsKey(id)
        ? (cartItems[id]!['quantity'] as num? ?? 0)
        : 0;
    if (stock != null && currentQty + qty > stock) {
      final num allowed = stock - currentQty;
      if (allowed <= 0) {
        Get.snackbar(
          'stock_not_available'.tr,
          'cannot_add_more_stock'.trParams({'stock': stock.toString()}),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }
      qty = allowed;
      Get.snackbar(
        'warning'.tr,
        'added_available_quantity'.trParams({'stock': stock.toString()}),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }

    if (cartItems.containsKey(id)) {
      cartItems[id]!['quantity'] =
          (cartItems[id]!['quantity'] as num? ?? 0) + qty;
      if (stock != null) cartItems[id]!['stock'] = stock;
    } else {
      final unitType = product['unit_type']?.toString() ?? 'kilogram';
      cartItems[id] = {
        'id': id,
        'title': product['title']?.toString() ?? '',
        'price': product['price'] ?? 0,
        'image': product['image']?.toString() ?? '',
        'unit': product['unit']?.toString() ?? 'unit_kg'.tr,
        'unit_type': unitType,
        'quantity': qty,
        if (stock != null) 'stock': stock,
      };
    }
    cartItems.refresh();
    _saveCart();
    cartVersion.value++;

    if (showPopup) {
      final totalPrice = (product['price'] as num? ?? 0) * qty;
      showAddedToCartDialog(product, qty, formatPrice(totalPrice));
    }
  }

  bool _isDecimalUnit(String unitType) => ['kilogram', 'kg', 'gram', 'g', 'liter', 'l', 'milliliter', 'ml'].contains(unitType.toLowerCase());

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is num) return price.toInt().toString();
    final parsed = double.tryParse(price.toString());
    if (parsed != null) return parsed.toInt().toString();
    return price.toString();
  }

  void removeFromCart(String id, {bool removeAll = false}) {
    if (!cartItems.containsKey(id)) return;
    final unitType = cartItems[id]!['unit_type']?.toString() ?? 'kilogram';
    final num step = _isDecimalUnit(unitType) ? 0.5 : 1;
    if (removeAll || (cartItems[id]!['quantity'] as num? ?? 0) <= step) {
      cartItems.remove(id);
    } else {
      cartItems[id]!['quantity'] =
          (cartItems[id]!['quantity'] as num? ?? 0) - step;
    }
    cartItems.refresh();
    _saveCart();
    cartVersion.value++;
  }

  void clearCart() {
    cartItems.clear();
    cartItems.refresh();
    _saveCart();
    cartVersion.value++;
  }

  double get subtotal {
    double total = 0;
    cartItems.forEach((key, value) {
      total +=
          ((value['price'] as num?)?.toDouble() ?? 0) *
          ((value['quantity'] as num?)?.toDouble() ?? 0);
    });
    return total;
  }

  double get deliveryFee {
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      return homeController.deliveryFee.value;
    }
    return 2500;
  }

  double get minOrderAmount {
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      return homeController.minOrderAmount.value;
    }
    return 0;
  }

  bool get isBelowMinOrder =>
      minOrderAmount > 0 && subtotal < minOrderAmount;

  double get total => subtotal + deliveryFee - discountAmount.value;

  /// Validates and applies a discount coupon from the `discount_codes` table.
  Future<bool> applyCoupon() async {
    final code = couponCode.value.trim();
    if (code.isEmpty) {
      couponError.value = 'please_enter_coupon'.tr;
      return false;
    }

    isApplyingCoupon(true);
    couponError.value = '';
    try {
      final response = await supabase
          .from('discount_codes')
          .select()
          .eq('code', code)
          .limit(1);

      if (response.isEmpty) {
        _resetCoupon();
        couponError.value = 'invalid_coupon'.tr;
        return false;
      }

      final coupon = response.first as Map<String, dynamic>;

      final isActive = coupon['is_active'] == true;
      final expiresAt = coupon['expires_at'];
      final maxUses = (coupon['max_uses'] as num?)?.toInt() ?? 0;
      final usedCount = (coupon['used_count'] as num?)?.toInt() ?? 0;

      final isExpired = expiresAt != null &&
          DateTime.tryParse(expiresAt.toString())?.isBefore(DateTime.now()) ==
              true;
      final usageExceeded = maxUses > 0 && usedCount >= maxUses;

      if (!isActive || isExpired || usageExceeded) {
        _resetCoupon();
        couponError.value = !isActive
            ? 'coupon_inactive'.tr
            : isExpired
                ? 'coupon_expired'.tr
                : 'coupon_fully_used'.tr;
        return false;
      }

      final minOrder = (coupon['min_order_amount'] as num?)?.toDouble() ?? 0;
      if (minOrder > 0 && subtotal < minOrder) {
        _resetCoupon();
        couponError.value = 'coupon_min_order'.trParams({'minOrder': minOrder.toInt().toString()});
        return false;
      }

      final type = coupon['type']?.toString() ?? 'percent';
      final rawAmount =
          (coupon['discount_amount'] as num?)?.toDouble() ?? 0;

      double computed;
      if (type == 'fixed') {
        computed = rawAmount;
      } else {
        computed = subtotal * (rawAmount / 100);
      }
      // Never discount below zero
      computed = computed.clamp(0, subtotal);

      appliedCoupon.value = coupon;
      discountAmount.value = computed;
      return true;
    } catch (e) {
      _resetCoupon();
      couponError.value = 'coupon_verify_failed'.tr;
      return false;
    } finally {
      isApplyingCoupon(false);
    }
  }

  void removeCoupon() {
    _resetCoupon();
  }

  void _resetCoupon() {
    appliedCoupon.value = null;
    discountAmount.value = 0;
  }

  int get itemCount {
    int count = 0;
    for (final item in cartItems.values) {
      count += ((item['quantity'] as num?) ?? 0).ceil();
    }
    return count;
  }

  bool get hasActiveOrder => activeOrderId.value != null;

  Future<String?> getActiveOrderId() async {
    try {
      if (!authController.isLoggedIn) return null;
      final userId = supabase.auth.currentUser!.id;
      final active = await supabase
          .from('orders')
          .select('id')
          .eq('customer_id', userId)
          .not('status', 'in', '("delivered","cancelled","rejected")')
          .maybeSingle();
      if (active != null) return active['id'].toString();
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> placeOrder({
    required String address,
    String paymentMethod = 'Cash',
  }) async {
    if (!authController.isLoggedIn) {
      Get.snackbar('warning'.tr, 'must_login_first'.tr);
      return false;
    }

    if (isPlacingOrder.value) return false;

    // Lock immediately to prevent concurrent submissions — must be
    // set BEFORE any async gap so a second call cannot race past.
    isPlacingOrder(true);

    if (isBelowMinOrder) {
      isPlacingOrder(false);
      Get.snackbar(
        'minimum_order'.tr,
        'minimum_order_not_met'.trParams({'minOrder': minOrderAmount.toInt().toString(), 'subtotal': subtotal.toInt().toString()}),
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    final hasActive = await getActiveOrderId();
    if (hasActive != null) {
      isPlacingOrder(false);
      Get.snackbar(
        'active_order_exists'.tr,
        'active_order_exists_msg'.tr,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
      return false;
    }
    final userId = supabase.auth.currentUser!.id;

    String? branchId;
    double? customerLat;
    double? customerLng;
    String? userArea;
    String? userStreet;
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      branchId = homeController.selectedBranch.value?['id']?.toString();
      if (homeController.userLat.value != 0.0 || homeController.userLng.value != 0.0) {
        customerLat = homeController.userLat.value;
        customerLng = homeController.userLng.value;
      }
      if (homeController.userArea.value.isNotEmpty) userArea = homeController.userArea.value;
      if (homeController.userStreet.value.isNotEmpty) userStreet = homeController.userStreet.value;
    }

    try {
      final orderData = <String, dynamic>{
        'customer_id': userId,
        'total_amount': total,
        'delivery_fee': deliveryFee,
        'discount_amount': discountAmount.value,
        'discount_code': appliedCoupon.value?['code'],
        'status': 'pending',
        'delivery_address': address,
        'payment_method': paymentMethod,
      };
      if (userArea != null) orderData['area'] = userArea;
      if (userStreet != null) orderData['street'] = userStreet;
      if (customerLat != null && customerLng != null) {
        orderData['customer_lat'] = customerLat;
        orderData['customer_lng'] = customerLng;
      }
      if (branchId != null && branchId.isNotEmpty) {
        orderData['branch_id'] = branchId;
      }
      final orderResponse = await supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'];

      if (appliedCoupon.value != null) {
        try {
          final couponId = appliedCoupon.value!['id'];
          final currentUsed =
              (appliedCoupon.value!['used_count'] as num?)?.toInt() ?? 0;
          await supabase
              .from('discount_codes')
              .update({'used_count': currentUsed + 1})
              .eq('id', couponId);
        } catch (couponErr) {
          debugPrint('Warning: coupon usage increment failed: $couponErr');
        }
      }

      final List<Map<String, dynamic>> itemsToInsert = [];
      cartItems.forEach((key, item) {
        itemsToInsert.add({
          'order_id': orderId,
          'product_id': item['id'],
          'quantity': item['quantity'],
          'unit_price': item['price'],
          'unit': item['unit']?.toString() ?? 'unit_kg'.tr,
          'unit_type': item['unit_type']?.toString() ?? 'kilogram',
          'total_price': (item['price'] as num) * (item['quantity'] as num),
        });
      });

      await supabase.from('order_items').insert(itemsToInsert);

      if (branchId != null && branchId.isNotEmpty) {
        try {
          for (final item in itemsToInsert) {
            final productId = item['product_id'];
            final qty = (item['quantity'] as num).toDouble();
            await supabase.rpc(
              'decrement_branch_inventory',
              params: {
                'p_branch_id': branchId,
                'p_product_id': productId,
                'p_quantity': qty,
              },
            );
          }
        } catch (stockErr) {
          debugPrint('Warning: stock decrement failed: $stockErr');
        }
      }

      clearCart();
      _resetCoupon();
      couponCode.value = '';
      lastOrderId(orderId.toString());
      await refreshActiveOrder();
      Get.snackbar(
        'success'.tr,
        'order_sent_success'.tr,
        backgroundColor: AppTheme.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (e) {
      final errStr = e.toString();
      debugPrint('[Cart] placeOrder failed: $errStr');
      Get.snackbar(
        'order_error'.tr,
        errStr.contains('network') ? 'no_internet'.tr : 'order_send_failed'.tr,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        mainButton: TextButton(
          onPressed: () =>
              placeOrder(address: address, paymentMethod: paymentMethod),
          child: Text(
            'retry'.tr,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return false;
    } finally {
      isPlacingOrder(false);
    }
  }
}
