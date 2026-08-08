import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/notifications_controller.dart';
import '../theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الإشعارات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديد الكل كمقروء',
            onPressed: () => controller.markAllRead(),
            icon: const Icon(LucideIcons.checkCheck),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => controller.poll(),
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: Obx(() {
        final items = controller.notifications;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.bellOff, size: 48, color: AppTheme.textSecondary.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد إشعارات بعد',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ستظهر هنا إعلانات الإدارة وإشعارات النظام',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final n = items[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: n.isNew ? AppTheme.primary.withOpacity(0.06) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: n.isNew ? AppTheme.primary.withOpacity(0.3) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.megaphone, color: AppTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (n.isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'جديد',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (n.message.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            n.message,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (n.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('d/M/yyyy HH:mm').format(n.createdAt!.toLocal()),
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}