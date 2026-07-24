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
      appBar: AppBar(
        title: const Text('طلبات التوصيل الجديدة'),
        actions: [
          IconButton(
            onPressed: () => controller.fetchOrders(),
            icon: const Icon(LucideIcons.refreshCcw, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Order List
          Container(
            width: 400,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.orders.isEmpty) {
                return const Center(child: Text('لا توجد طلبات حالياً'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
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
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.mousePointer2,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'اختر طلباً لعرض التفاصيل',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
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
    );
  }
}
