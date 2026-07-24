import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../controllers/pos_orders_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/invoice.dart';
import '../../../services/invoice_service.dart';

class DeliveryOrderDetails extends StatelessWidget {
  final Map<String, dynamic> order;
  final POSOrdersController controller;
  final AuthController authController;
  final VoidCallback onRefresh;

  const DeliveryOrderDetails({
    super.key,
    required this.order,
    required this.controller,
    required this.authController,
    required this.onRefresh,
  });

  DateTime? _parseCreatedAt() {
    final value = order['created_at'];
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  void _printInvoice() {
    final items = (order['order_items'] as List).map((item) {
      return InvoiceItem(
        productId: item['product_id'] ?? '',
        name: item['products']?['name'] ?? 'منتج',
        price: (item['unit_price'] as num).toDouble(),
        quantity: (item['quantity'] as num).toInt(),
        unit: item['products']?['unit'] ?? 'قطعة',
        total: (item['total_price'] as num).toDouble(),
      );
    }).toList();

    final createdAt = _parseCreatedAt() ?? DateTime.now();

    final invoice = Invoice(
      id: order['id'],
      orderId: order['id'],
      branchId: authController.currentBranchId.value,
      branchName: authController.currentBranchName.value,
      items: items,
      subtotal:
          ((order['total_amount'] as num) - (order['delivery_fee'] as num))
              .toDouble(),
      discount: 0,
      tax: 0,
      total: (order['total_amount'] as num).toDouble(),
      paymentMethod: order['payment_method'] ?? 'نقداً',
      createdAt: createdAt,
      customerName: order['profiles']?['full_name'] ?? '',
      cashierName: 'فرع ${authController.currentBranchName.value}',
    );

    InvoiceService().printInvoice(invoice);
  }

  void _showDriverAssignmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إسناد الطلب لمندوب'),
        content: SizedBox(
          width: 400,
          child: Obx(
            () => ListView.builder(
              shrinkWrap: true,
              itemCount: controller.drivers.length,
              itemBuilder: (context, index) {
                final driver = controller.drivers[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(LucideIcons.truck)),
                  title: Text(driver['profiles']?['full_name'] ?? 'مندوب'),
                  subtitle: Text(driver['current_status'] ?? 'متاح'),
                  trailing: const Icon(LucideIcons.chevronLeft),
                  onTap: () {
                    controller.assignDriver(order['id'], driver['id']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = order['order_items'] as List;
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
                  Text(
                    'تفاصيل الطلب #${order['id'].toString().substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'بتاريخ ${DateFormat('dd/MM/yyyy - hh:mm a').format(_parseCreatedAt() ?? DateTime.now())}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  if (order['status'] == 'preparing')
                    _buildActionButton(
                      'طباعة الفاتورة',
                      LucideIcons.printer,
                      Colors.grey[700]!,
                      _printInvoice,
                    ),
                  if (order['status'] == 'pending')
                    _buildActionButton(
                      'قبول / جاري التحضير',
                      LucideIcons.packageCheck,
                      AppTheme.secondary,
                      () async {
                        await controller.updateStatus(order['id'], 'preparing');
                        Get.snackbar(
                          'تم قبول الطلب',
                          'يمكنك الآن طباعة الفاتورة',
                          backgroundColor: AppTheme.primary,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          mainButton: TextButton(
                            onPressed: _printInvoice,
                            child: const Text(
                              'طباعة',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          duration: const Duration(seconds: 6),
                        );
                      },
                    ),
                  const SizedBox(width: 12),
                  if (order['status'] == 'picked_up')
                    _buildActionButton(
                      'تأكيد استلام المندوب',
                      LucideIcons.packageCheck,
                      AppTheme.primary,
                      () async {
                        await controller.updateStatus(order['id'], 'shipped');
                      },
                    ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    'إسناد مندوب',
                    LucideIcons.userPlus,
                    Colors.orange,
                    () => _showDriverAssignmentDialog(context),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 64),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الأصناف المطلوبة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    LucideIcons.package,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['products']['name'] ?? 'منتج',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'سعر الوحدة: ${item['unit_price']} د.ع',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '× ${item['quantity']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Text(
                                  '${item['total_price']} د.ع',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard('بيانات العميل', [
                      _buildInfoRow(
                        LucideIcons.user,
                        order['profiles']['full_name'],
                      ),
                      _buildInfoRow(
                        LucideIcons.phone,
                        order['profiles']['phone'],
                      ),
                      _buildInfoRow(
                        LucideIcons.mapPin,
                        order['delivery_address'],
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildInfoCard('ملخص الفاتورة', [
                      _buildSummaryRow(
                        'الإجمالي الفرعي',
                        '${order['total_amount'] - order['delivery_fee']} د.ع',
                      ),
                      _buildSummaryRow(
                        'رسوم التوصيل',
                        '${order['delivery_fee']} د.ع',
                      ),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        'الإجمالي الكلي',
                        '${order['total_amount']} د.ع',
                        isTotal: true,
                      ),
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
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
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppTheme.primary : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
