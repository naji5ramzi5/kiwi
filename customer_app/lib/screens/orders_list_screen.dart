import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/home_controller.dart';
import 'order_details_screen.dart';
import 'cart/cart_screen.dart';

class OrdersListScreen extends StatefulWidget {
  final String? filterStatus;
  const OrdersListScreen({super.key, this.filterStatus});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final supabase = Supabase.instance.client;
  final auth = Get.find<AuthController>();
  var orders = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      isLoading(true);
      if (!auth.isLoggedIn) return;
      final userId = supabase.auth.currentUser!.id;
      var query = supabase
          .from('orders')
          .select('id, status, total_amount, delivery_fee, created_at')
          .eq('customer_id', userId);
      if (widget.filterStatus != null) {
        query = query.eq('status', widget.filterStatus!);
      } else {
        query = query.not('status', 'in', '("delivered","cancelled","rejected")');
      }
      final data = await query.order('created_at', ascending: false);
      orders.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> _reorder(String orderId) async {
    try {
      final items = await supabase
          .from('order_items')
          .select('product_id, quantity, unit_price, product_name, unit, unit_type')
          .eq('order_id', orderId);

      if (items.isEmpty) {
        Get.snackbar('none'.tr, 'no_products_to_reorder'.tr,
          backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16));
        return;
      }

      // Ensure a branch is selected so stock checks work
      final home = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;
      if (home != null && home.selectedBranch.value == null) {
        try {
          final branch = await supabase
              .from('branches')
              .select()
              .eq('status', 'نشط')
              .limit(1)
              .maybeSingle();
          if (branch != null) home.selectedBranch.value = branch;
        } catch (_) {}
      }

      final cart = Get.isRegistered<CartController>()
          ? Get.find<CartController>()
          : Get.put(CartController());

      int added = 0;
      for (final item in List<Map<String, dynamic>>.from(items)) {
        final productId = item['product_id']?.toString() ?? '';
        if (productId.isEmpty) continue;
        cart.addToCart({
          'id': productId,
          'title': item['product_name']?.toString() ?? '',
          'price': item['unit_price'] ?? 0,
          'image': '',
            'unit': item['unit']?.toString() ?? 'unit_piece'.tr,
            'unit_type': item['unit_type']?.toString() ?? 'kilogram',
        }, qty: (item['quantity'] as num? ?? 1), showPopup: false);
        added++;
      }

      if (added > 0) {
        Get.snackbar('added'.tr, 'products_added_to_cart'.trParams({'count': added.toString()}),
          backgroundColor: AppTheme.primary, colorText: Colors.white, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16));
        Get.to(() => const CartScreen(), transition: Transition.fadeIn);
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'reorder_failed'.tr,
        backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    String title;
    if (widget.filterStatus == 'cancelled') {
      title = 'cancelled_orders'.tr;
    } else if (widget.filterStatus == 'delivered') {
      title = 'previous_orders'.tr;
    } else {
      title = 'my_orders'.tr;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'Cairo')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.packageX, size: 64, color: textSecColor.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('no_orders'.tr, style: TextStyle(fontSize: 18, color: textSecColor, fontFamily: 'Cairo')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: fetchOrders,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            physics: const BouncingScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final status = order['status']?.toString() ?? '';
              final total = order['total_amount'] ?? 0;
              final createdAt = order['created_at']?.toString() ?? '';
              final dateText = createdAt.isNotEmpty && createdAt.length >= 10
                  ? createdAt.substring(0, 10)
                  : '';

              Color statusColor;
              String statusText;
              switch (status) {
                case 'delivered':
                  statusColor = AppTheme.primary;
                  statusText = 'delivered'.tr;
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  statusText = 'cancelled'.tr;
                  break;
                case 'pending':
                  statusColor = Colors.amber;
                  statusText = 'pending'.tr;
                  break;
                case 'preparing':
                  statusColor = Colors.orange;
                  statusText = 'preparing'.tr;
                  break;
                case 'shipped':
                  statusColor = Colors.blue;
                  statusText = 'on_the_way'.tr;
                  break;
                default:
                  statusColor = Colors.grey;
                  statusText = status;
              }

              return GestureDetector(
                onTap: () => Get.to(() => OrderDetailsScreen(orderId: order['id'].toString()), transition: Transition.fadeIn),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(LucideIcons.receipt, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor, fontFamily: 'Cairo'),
                                  ),
                                ),
                                const Spacer(),
                                Text('$total ${'currency_iqd'.tr}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
                              ],
                            ),
                            if (dateText.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(LucideIcons.calendar, size: 12, color: textSecColor),
                                  const SizedBox(width: 4),
                                  Text(dateText, style: TextStyle(fontSize: 11, color: textSecColor, fontFamily: 'Cairo')),
                                ],
                              ),
                            ],
                            if (status == 'delivered') ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _reorder(order['id'].toString()),
                                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                                  label: Text('reorder'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: const BorderSide(color: AppTheme.primary),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronLeft, size: 18, color: textSecColor),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
