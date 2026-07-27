import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/app_theme.dart';

const Map<String, String> _statusLabels = {
  'pending': 'جديد',
  'preparing': 'قيد التحضير',
  'picked_up': 'تم الاستلام من الفرع',
  'shipped': 'في الطريق',
  'delivered': 'تم التوصيل',
  'cancelled': 'ملغي',
  'rejected': 'مرفوض',
};

const Map<String, Color> _statusColors = {
  'pending': AppTheme.accent,
  'preparing': AppTheme.info,
  'picked_up': AppTheme.secondary,
  'shipped': AppTheme.primary,
  'delivered': AppTheme.success,
  'cancelled': AppTheme.error,
  'rejected': AppTheme.error,
};

class DeliveryOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isSelected;
  final VoidCallback onTap;

  const DeliveryOrderCard({
    super.key,
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? '';
    final statusLabel = _statusLabels[status] ?? status;
    final statusColor = _statusColors[status] ?? AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLighter : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (statusColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.receipt,
                        size: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'طلب #${order['id'].toString().substring(0, 5)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('hh:mm a').format(DateTime.parse(order['created_at'])),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(LucideIcons.user, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  order['profiles']['full_name'] ?? 'عميل مجهول',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order['total_amount']} د.ع',
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
