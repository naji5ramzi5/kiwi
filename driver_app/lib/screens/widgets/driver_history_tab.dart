import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

String orderShort(String id) => id.length >= 5 ? id.substring(0, 5) : id;

class DriverHistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> historyOrders;

  const DriverHistoryTab({super.key, required this.historyOrders});

  @override
  Widget build(BuildContext context) {
    if (historyOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.package, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا يوجد طلبات مكتملة بعد', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: historyOrders.length,
      itemBuilder: (context, index) {
        final order = historyOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.checkCircle, color: Color(0xFF10b981), size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب #${orderShort(order['id'].toString()).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(_timeAgo(order['updated_at']), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Text('${order['delivery_fee'] ?? 0} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10b981))),
            ],
          ),
        );
      },
    );
  }

  static String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return 'الآن';
    try {
      DateTime date = createdAt is String ? DateTime.parse(createdAt) : DateTime.parse(createdAt.toString());
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return '${date.month}/${date.day}';
    } catch (e) {
      return 'الآن';
    }
  }
}
