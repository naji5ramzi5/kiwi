import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';

class OrderTimelineWidget extends StatelessWidget {
  final String status;
  final bool isDark;

  const OrderTimelineWidget({
    super.key,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'label': 'order_received'.tr, 'key': 'pending', 'icon': LucideIcons.checkCircle2},
      {'label': 'preparing_order'.tr, 'key': 'preparing', 'icon': LucideIcons.clock},
      {'label': 'status_prepared'.tr, 'key': 'prepared', 'icon': LucideIcons.packageCheck},
      {'label': 'on_the_way'.tr, 'key': 'shipped', 'icon': LucideIcons.truck},
      {'label': 'order_delivered'.tr, 'key': 'delivered', 'icon': LucideIcons.packageCheck},
    ];

    // Map driver-assignment / pick-up states onto the nearest visible step.
    final mappedStatus = switch (status) {
      'picked_up' || 'ready' => 'prepared',
      _ => status,
    };

    final currentIndex = steps.indexWhere((s) => s['key'] == mappedStatus);
    final activeIndex = currentIndex >= 0 ? currentIndex : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.listChecks, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text('track_order'.tr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isCompleted = i <= activeIndex;
            final isCurrent = i == activeIndex;
            final isLast = i == steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: isCurrent ? 28 : 24,
                          height: isCurrent ? 28 : 24,
                          decoration: BoxDecoration(
                            color: isCompleted ? AppTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            shape: BoxShape.circle,
                            boxShadow: isCurrent ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8)] : null,
                          ),
                          child: Center(
                            child: isCompleted
                              ? Icon(LucideIcons.check, size: isCurrent ? 16 : 14, color: Colors.white)
                              : Icon(step['icon'] as IconData, size: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: i < activeIndex ? AppTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['label'] as String,
                            style: TextStyle(
                              fontSize: isCurrent ? 14 : 13,
                              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                              color: isCompleted ? AppTheme.primary : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (isCurrent)
                            Text(
                              'current_stage'.tr,
                              style: TextStyle(fontSize: 10, color: AppTheme.primary, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
