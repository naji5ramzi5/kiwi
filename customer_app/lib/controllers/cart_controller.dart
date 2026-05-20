import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_controller.dart';

class CartController extends GetxController {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();

  // Map of ProductID -> CartItem
  var cartItems = <String, Map<String, dynamic>>{}.obs;
  var isPlacingOrder = false.obs;

  void addToCart(Map<String, dynamic> product) {
    final String id = product['id'].toString();
    if (cartItems.containsKey(id)) {
      cartItems[id]!['quantity'] += 1;
    } else {
      cartItems[id] = {
        'id': id,
        'title': product['title'],
        'price': product['price'],
        'image': product['image'],
        'unit': product['unit'],
        'quantity': 1,
      };
    }
    cartItems.refresh();
  }

  void removeFromCart(String id) {
    if (cartItems.containsKey(id)) {
      if (cartItems[id]!['quantity'] > 1) {
        cartItems[id]!['quantity'] -= 1;
      } else {
        cartItems.remove(id);
      }
    }
    cartItems.refresh();
  }

  void clearCart() {
    cartItems.clear();
  }

  double get subtotal {
    double total = 0;
    cartItems.forEach((key, value) {
      total += (value['price'] as num) * (value['quantity'] as int);
    });
    return total;
  }

  double get deliveryFee => 2500; // Fixed delivery fee for now

  double get total => subtotal + deliveryFee;

  int get itemCount => cartItems.length;

  Future<bool> placeOrder({required String address, String paymentMethod = 'Cash'}) async {
    try {
      if (!authController.isLoggedIn) {
        Get.snackbar('تنبيه', 'يجب تسجيل الدخول أولاً');
        return false;
      }

      isPlacingOrder(true);
      final userId = supabase.auth.currentUser!.id;

      // 1. Create the order
      final orderResponse = await supabase.from('orders').insert({
        'customer_id': userId,
        'total_amount': total,
        'delivery_fee': deliveryFee,
        'status': 'pending',
        'delivery_address': address,
        'payment_method': paymentMethod,
      }).select().single();

      final orderId = orderResponse['id'];

      // 2. Create order items
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

      // 3. Clear cart
      clearCart();
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إرسال الطلب: $e');
      return false;
    } finally {
      isPlacingOrder(false);
    }
  }
}
