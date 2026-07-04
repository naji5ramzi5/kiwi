import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_controller.dart';
import '../theme/app_theme.dart';
import 'main_screen_controller.dart';


class CartController extends GetxController {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();
  final _box = GetStorage();

  var cartItems = <String, Map<String, dynamic>>{}.obs;
  var isPlacingOrder = false.obs;
  var isCountingDown = false.obs;
  var lastOrderId = ''.obs;
  var activeOrderId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    _loadCart();
    refreshActiveOrder();
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
      cartItems.refresh();
    }
  }

  void _saveCart() {
    _box.write('cart_items', cartItems.values.toList());
  }

  void addToCart(Map<String, dynamic> product, {int qty = 1, bool showPopup = true}) {
    final String id = product['id'].toString();
    final int? stock = product['stock'] != null ? (product['stock'] as num).toInt() : null;

    final int currentQty = cartItems.containsKey(id) ? (cartItems[id]!['quantity'] as int? ?? 0) : 0;
    if (stock != null && currentQty + qty > stock) {
      final int allowed = stock - currentQty;
      if (allowed <= 0) {
        Get.snackbar(
          'الكمية غير متوفرة',
          'لا يمكن إضافة المزيد، الكمية المتاحة من هذا المنتج هي $stock فقط',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }
      qty = allowed;
      Get.snackbar(
        'تنبيه',
        'تمت إضافة الكمية المتاحة فقط ($stock)',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }

    if (cartItems.containsKey(id)) {
      cartItems[id]!['quantity'] = (cartItems[id]!['quantity'] as int? ?? 0) + qty;
      if (stock != null) cartItems[id]!['stock'] = stock;
    } else {
      cartItems[id] = {
        'id': id,
        'title': product['title']?.toString() ?? '',
        'price': product['price'] ?? 0,
        'image': product['image']?.toString() ?? '',
        'unit': product['unit']?.toString() ?? 'كغ',
        'quantity': qty,
        if (stock != null) 'stock': stock,
      };
    }
    cartItems.refresh();
    _saveCart();

    if (showPopup) {
      final totalPrice = (product['price'] as num? ?? 0) * qty;
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Get.isDarkMode ? const Color(0xFF1C2B1E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تمت الإضافة إلى السلة',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.network(
                            product['image'] ?? '',
                            fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.primary.withOpacity(0.1),
                            child: Icon(Icons.shopping_bag, color: AppTheme.primary, size: 28),
                          ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['title'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Get.isDarkMode ? Colors.white : const Color(0xFF1F2937),
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'الكمية: $qty',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Get.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${formatPrice(totalPrice)} د.ع',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF047857),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Get.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'متابعة التسوق',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF047857),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Get.back();
                            Get.find<MainScreenController>().switchTab(2);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF064E3B), Color(0xFF047857)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF047857).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'الانتقال إلى السلة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is num) return price.toInt().toString();
    final parsed = double.tryParse(price.toString());
    if (parsed != null) return parsed.toInt().toString();
    return price.toString();
  }

  void removeFromCart(String id, {bool removeAll = false}) {
    if (!cartItems.containsKey(id)) return;
    if (removeAll || (cartItems[id]!['quantity'] as int? ?? 0) <= 1) {
      cartItems.remove(id);
    } else {
      cartItems[id]!['quantity'] = (cartItems[id]!['quantity'] as int? ?? 0) - 1;
    }
    cartItems.refresh();
    _saveCart();
  }

  void clearCart() {
    cartItems.clear();
    cartItems.refresh();
    _saveCart();
  }

  double get subtotal {
    double total = 0;
    cartItems.forEach((key, value) {
      total += ((value['price'] as num?)?.toDouble() ?? 0) * ((value['quantity'] as int?) ?? 0);
    });
    return total;
  }

  double get deliveryFee => 2500;

  double get total => subtotal + deliveryFee;

  int get itemCount {
    int count = 0;
    for (final item in cartItems.values) {
      count += (item['quantity'] as int?) ?? 0;
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

  Future<bool> placeOrder({required String address, String paymentMethod = 'Cash'}) async {
    if (!authController.isLoggedIn) {
      Get.snackbar('تنبيه', 'يجب تسجيل الدخول أولاً');
      return false;
    }

    final hasActive = await getActiveOrderId();
    if (hasActive != null) {
      Get.snackbar(
        'لديك طلب نشط',
        'لا يمكنك إنشاء طلب جديد حتى يتم إنهاء الطلب الحالي',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    isPlacingOrder(true);
    final userId = supabase.auth.currentUser!.id;

    Future<bool> tryPlaceOrder() async {
      try {
        final orderResponse = await supabase.from('orders').insert({
          'customer_id': userId,
          'total_amount': total,
          'delivery_fee': deliveryFee,
          'status': 'pending',
          'delivery_address': address,
          'payment_method': paymentMethod,
        }).select().single();

        final orderId = orderResponse['id'];

        final List<Map<String, dynamic>> itemsToInsert = [];
        cartItems.forEach((key, item) {
          itemsToInsert.add({
            'order_id': orderId,
            'product_id': item['id'],
            'quantity': item['quantity'],
            'unit_price': item['price'],
            'total_price': (item['price'] as num) * (item['quantity'] as int),
          });
        });

        await supabase.from('order_items').insert(itemsToInsert);

        clearCart();
        lastOrderId(orderId.toString());
        await refreshActiveOrder();
        Get.snackbar('نجاح', 'تم إرسال طلبك بنجاح', backgroundColor: AppTheme.primary, colorText: Colors.white, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16));
        return true;
      } on SocketException {
        throw Exception('network');
      } on PostgrestException catch (e) {
        throw Exception('server: ${e.message}');
      } catch (e) {
        throw Exception('unknown: $e');
      }
    }

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        return await tryPlaceOrder();
      } catch (e) {
        if (attempt == 3) {
          final errorStr = e.toString();
          if (errorStr.contains('network')) {
            Get.snackbar(
              'خطأ في الاتصال',
              'لا يوجد اتصال بالإنترنت. تأكد من اتصالك وحاول مرة أخرى.',
              backgroundColor: Colors.red.shade700,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () => placeOrder(address: address, paymentMethod: paymentMethod),
                child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
              ),
            );
          } else if (errorStr.contains('server')) {
            Get.snackbar(
              'خطأ في الطلب',
              'فشل في إرسال الطلب. حاول مرة أخرى.',
              backgroundColor: Colors.red.shade700,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () => placeOrder(address: address, paymentMethod: paymentMethod),
                child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
              ),
            );
          } else {
            Get.snackbar(
              'خطأ',
              'فشل في إرسال الطلب: $e',
              backgroundColor: Colors.red.shade700,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () => placeOrder(address: address, paymentMethod: paymentMethod),
                child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
              ),
            );
          }
          return false;
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return false;
  }
}
