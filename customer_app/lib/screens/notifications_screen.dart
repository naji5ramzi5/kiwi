import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get_storage/get_storage.dart';
import '../theme/app_theme.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.icon = LucideIcons.bell,
    this.iconColor = AppTheme.primary,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GetStorage _storage = GetStorage();
  final RxList<NotificationItem> _notifications = <NotificationItem>[
    NotificationItem(
      id: '1',
      title: '🛵 طلبك في الطريق!',
      body: 'المندوب على بُعد 5 دقائق منك، تجهز لاستلام طلبك',
      time: 'منذ 5 دقائق',
      icon: LucideIcons.truck,
      iconColor: const Color(0xFF10B981),
    ),
    NotificationItem(
      id: '2',
      title: '✅ تم تأكيد طلبك',
      body: 'طلبك #1032 قيد التجهيز في الفرع وسيتم توصيله قريباً',
      time: 'منذ 20 دقيقة',
      icon: LucideIcons.checkCircle,
      iconColor: const Color(0xFF10B981),
    ),
    NotificationItem(
      id: '3',
      title: '🎁 عرض خاص لك!',
      body: 'خصم 15% على الخضروات الطازجة اليوم فقط، اطلب الآن',
      time: 'أمس',
      icon: LucideIcons.tag,
      iconColor: Colors.orange,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    NotificationItem(
      id: '4',
      title: '⭐ قيّم تجربتك',
      body: 'كيف كانت تجربتك مع طلبك الأخير؟ شاركنا رأيك',
      time: 'أمس',
      icon: LucideIcons.star,
      iconColor: Colors.amber,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
  ].obs;

  @override
  void initState() {
    super.initState();
    _removeOldNotifications();
  }

  void _removeOldNotifications() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _notifications.removeWhere((n) => n.createdAt.isBefore(cutoff));
    final clearedIds = _storage.read<List>('cleared_notification_ids') ?? <String>[];
    if (clearedIds.isNotEmpty) {
      _notifications.removeWhere((n) => clearedIds.contains(n.id));
    }
  }

  void _clearAll() {
    Get.defaultDialog(
      title: 'مسح الإشعارات',
      titleStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
      middleText: 'هل أنت متأكد من مسح جميع الإشعارات؟',
      middleTextStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
      textConfirm: 'مسح الكل',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        final allIds = _notifications.map((n) => n.id).toList();
        final clearedIds = _storage.read<List>('cleared_notification_ids') ?? <String>[];
        clearedIds.addAll(allIds);
        _storage.write('cleared_notification_ids', clearedIds.toSet().toList());
        _notifications.clear();
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('الإشعارات', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
              label: const Text('مسح الكل', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
      body: Obx(() {
        if (_notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.bellOff, size: 36, color: AppTheme.primary.withOpacity(0.4)),
                ),
                const SizedBox(height: 20),
                Text(
                  'لا توجد إشعارات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 8),
                Text(
                  'ستظهر هنا جميع الإشعارات والتحديثات الجديدة',
                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary, fontFamily: 'Cairo'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          physics: const BouncingScrollPhysics(),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final item = _notifications[index];
            return Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
              ),
              onDismissed: (_) {
                final clearedIds = _storage.read<List>('cleared_notification_ids') ?? <String>[];
                clearedIds.add(_notifications[index].id);
                _storage.write('cleared_notification_ids', clearedIds.toSet().toList());
                _notifications.removeAt(index);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E291F) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.primary.withOpacity(0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 20, color: item.iconColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: textColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.body,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.time,
                      style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}