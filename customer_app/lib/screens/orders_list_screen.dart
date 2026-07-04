import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import 'order_details_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textSecColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    String title;
    if (widget.filterStatus == 'cancelled') {
      title = 'الطلبات الملغية';
    } else if (widget.filterStatus == 'delivered') {
      title = 'الطلبات السابقة';
    } else {
      title = 'طلباتي';
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
                Text('لا توجد طلبات', style: TextStyle(fontSize: 18, color: textSecColor, fontFamily: 'Cairo')),
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
                  statusText = 'تم التسليم';
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  statusText = 'ملغي';
                  break;
                case 'pending':
                  statusColor = Colors.amber;
                  statusText = 'قيد الانتظار';
                  break;
                case 'preparing':
                  statusColor = Colors.orange;
                  statusText = 'جاري التحضير';
                  break;
                case 'shipped':
                  statusColor = Colors.blue;
                  statusText = 'في الطريق';
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
                                Text('$total د.ع', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Cairo')),
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
