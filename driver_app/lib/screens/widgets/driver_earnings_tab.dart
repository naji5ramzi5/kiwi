import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DriverEarningsTab extends StatelessWidget {
  final double totalEarnings;
  final int deliveryCount;
  final String avgRating;
  final int totalRatings;

  const DriverEarningsTab({
    super.key,
    required this.totalEarnings,
    required this.deliveryCount,
    required this.avgRating,
    required this.totalRatings,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF059669)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF10b981).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              const Text('إجمالي الأرباح', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('${totalEarnings.toStringAsFixed(0)} د.ع', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('$deliveryCount طلبات مكتملة', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(LucideIcons.star, color: Color(0xFFF59E0B), size: 28)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('التقييم', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$avgRating / 5 ($totalRatings تقييم)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
