import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/pos_orders_controller.dart';
import '../../controllers/auth_controller.dart';
import 'widgets/delivery_order_card.dart';
import 'widgets/delivery_order_details.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
  final POSOrdersController controller = Get.find<POSOrdersController>();
  final AuthController authController = Get.find<AuthController>();
  Map<String, dynamic>? selectedOrder;

  @override
  void initState() {
    super.initState();
    controller.orders.listen((orders) {
      if (selectedOrder != null && orders.isNotEmpty) {
        final updated = orders.firstWhereOrNull(
          (o) => o['id'] == selectedOrder!['id'],
        );
        if (updated != null && mounted) {
          setState(() => selectedOrder = updated);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.shoppingBag, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('طلبات التوصيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => controller.fetchOrders(),
                    icon: const Icon(LucideIcons.refreshCcw, size: 20, color: AppTheme.primary),
                    tooltip: 'تحديث الطلبات',
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),

          // Body
          Expanded(
            child: Row(
              children: [
                // Order List
                Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.inbox, size: 64, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            Text('لا توجد طلبات حالياً', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: controller.orders.length,
                      itemBuilder: (context, index) {
                        final order = controller.orders[index];
                        final isSelected = selectedOrder?['id'] == order['id'];
                        return DeliveryOrderCard(
                          order: order,
                          isSelected: isSelected,
                          onTap: () => setState(() => selectedOrder = order),
                        );
                      },
                    );
                  }),
                ),

                // Order Details
                Expanded(
                  child: selectedOrder == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLighter,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  LucideIcons.mousePointer2,
                                  size: 48,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'اختر طلباً لعرض التفاصيل',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'من القائمة على اليمين',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : DeliveryOrderDetails(
                          order: selectedOrder!,
                          controller: controller,
                          authController: authController,
                          onRefresh: () => setState(() {}),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
