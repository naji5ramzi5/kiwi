import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/pos_orders_controller.dart';
import 'package:intl/intl.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
  final POSOrdersController controller = Get.put(POSOrdersController());
  Map<String, dynamic>? selectedOrder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('طلبات التوصيل الجديدة'),
        actions: [
          IconButton(onPressed: () => controller.fetchOrders(), icon: const Icon(LucideIcons.refreshCcw, size: 20)),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Order List
          Container(
            width: 400,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.1))),
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
                  return _buildOrderCard(order, isSelected);
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
                        Icon(LucideIcons.mousePointer2, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('اختر طلباً لعرض التفاصيل', style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ],
                    ),
                  )
                : _buildOrderDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedOrder = order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${order['id'].toString().substring(0, 5)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('hh:mm a').format(DateTime.parse(order['created_at'])),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order['profiles']['full_name'] ?? 'عميل مجهول',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order['total_amount']} د.ع',
                  style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w900),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order['status'] == 'pending' ? 'بانتظار الموافقة' : order['status'],
                    style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    final items = selectedOrder!['order_items'] as List;
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تفاصيل الطلب #${selectedOrder!['id'].toString().substring(0, 8)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('بتاريخ ${DateFormat('dd/MM/yyyy - hh:mm a').format(DateTime.parse(selectedOrder!['created_at']))}',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              Row(
                children: [
                  _buildActionButton('طباعة الفاتورة', LucideIcons.printer, Colors.grey[700]!, () {}),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    'إسناد مندوب', 
                    LucideIcons.userPlus, 
                    Colors.orange, 
                    () => _showDriverAssignmentDialog(context)
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    'تم التحضير / جاهز', 
                    LucideIcons.packageCheck, 
                    AppTheme.secondary, 
                    () => controller.updateStatus(selectedOrder!['id'], 'shipped')
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 64),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Items Table
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الأصناف المطلوبة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(LucideIcons.package, color: AppTheme.textSecondary, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['products']['name'] ?? 'منتج', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('سعر الوحدة: ${item['unit_price']} د.ع', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text('× ${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(width: 32),
                                Text('${item['total_price']} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              
              // Customer & Summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard('بيانات العميل', [
                      _buildInfoRow(LucideIcons.user, selectedOrder!['profiles']['full_name']),
                      _buildInfoRow(LucideIcons.phone, selectedOrder!['profiles']['phone']),
                      _buildInfoRow(LucideIcons.mapPin, selectedOrder!['delivery_address']),
                    ]),
                    const SizedBox(height: 24),
                    _buildInfoCard('ملخص الفاتورة', [
                      _buildSummaryRow('الإجمالي الفرعي', '${selectedOrder!['total_amount'] - selectedOrder!['delivery_fee']} د.ع'),
                      _buildSummaryRow('رسوم التوصيل', '${selectedOrder!['delivery_fee']} د.ع'),
                      const Divider(height: 24),
                      _buildSummaryRow('الإجمالي الكلي', '${selectedOrder!['total_amount']} د.ع', isTotal: true),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDriverAssignmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إسناد الطلب لمندوب'),
        content: SizedBox(
          width: 400,
          child: Obx(() => ListView.builder(
            shrinkWrap: true,
            itemCount: controller.drivers.length,
            itemBuilder: (context, index) {
              final driver = controller.drivers[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(LucideIcons.truck)),
                title: Text(driver['profiles']['full_name'] ?? 'مندوب'),
                subtitle: Text(driver['current_status'] ?? 'متاح'),
                trailing: const Icon(LucideIcons.chevronLeft),
                onTap: () {
                  controller.assignDriver(selectedOrder!['id'], driver['id']);
                  Navigator.pop(context);
                },
              );
            },
          )),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: isTotal ? AppTheme.primary : AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: isTotal ? 18 : 14)),
        ],
      ),
    );
  }
}
