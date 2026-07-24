import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'].toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      isRead: map['is_read'] == true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  /// Infer an icon + color from the notification title keywords.
  IconData get icon {
    final t = title;
    if (t.contains('طريق') || t.contains('مندوب') || t.contains('توصيل')) return LucideIcons.truck;
    if (t.contains('تأكيد') || t.contains('تم') || t.contains('وصل')) return LucideIcons.checkCircle;
    if (t.contains('عرض') || t.contains('خصم') || t.contains('هدية')) return LucideIcons.tag;
    if (t.contains('قيّم') || t.contains('تقييم') || t.contains('رأيك')) return LucideIcons.star;
    if (t.contains('إلغاء') || t.contains('ملغي') || t.contains('رفض')) return LucideIcons.xCircle;
    return LucideIcons.bell;
  }

  Color get iconColor {
    final t = title;
    if (t.contains('إلغاء') || t.contains('ملغي') || t.contains('رفض')) return Colors.red;
    if (t.contains('عرض') || t.contains('خصم') || t.contains('هدية')) return Colors.orange;
    if (t.contains('قيّم') || t.contains('تقييم')) return Colors.amber;
    return AppTheme.emerald;
  }

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'time_now'.tr;
    if (diff.inMinutes < 60) return 'minutes_ago'.trParams({'minutes': diff.inMinutes.toString()});
    if (diff.inHours < 24) return 'hours_ago'.trParams({'hours': diff.inHours.toString()});
    if (diff.inDays == 1) return 'time_yesterday'.tr;
    if (diff.inDays < 7) return 'days_ago'.trParams({'days': diff.inDays.toString()});
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RxList<NotificationItem> _notifications = <NotificationItem>[].obs;
  final RxBool _isLoading = true.obs;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenToNotifications() {
    final userId = _userId;
    if (userId == null) {
      _isLoading(false);
      return;
    }

    // Realtime stream: keeps the list updated automatically
    _subscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((rows) {
      _notifications.value = rows.map(NotificationItem.fromMap).toList();
      _isLoading(false);
      _markAllAsRead();
    }, onError: (e) {
      debugPrint('Notifications stream error: $e');
      _fetchOnce();
    });
  }

  Future<void> _fetchOnce() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final rows = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      _notifications.value =
          List<Map<String, dynamic>>.from(rows).map(NotificationItem.fromMap).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading(false);
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking notifications read: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _supabase.from('notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  void _clearAll() {
    Get.defaultDialog(
      title: 'clear_notifications'.tr,
      titleStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
      middleText: 'clear_all_confirm'.tr,
      middleTextStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
      textConfirm: 'clear_all'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        final userId = _userId;
        if (userId == null) return;
        _notifications.clear();
        try {
          await _supabase.from('notifications').delete().eq('user_id', userId);
        } catch (e) {
          debugPrint('Error clearing notifications: $e');
        }
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
        title: Text('notifications'.tr, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Obx(() => _notifications.isNotEmpty
              ? TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                  label: Text('clear_all'.tr, style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

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
                  'no_notifications'.tr,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 8),
                Text(
                  'notifications_empty'.tr,
                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary, fontFamily: 'Cairo'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _fetchOnce,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                  final id = item.id;
                  _notifications.removeAt(index);
                  _deleteNotification(id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E291F) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item.isRead
                          ? (isDark ? Colors.white.withOpacity(0.06) : AppTheme.primary.withOpacity(0.06))
                          : AppTheme.primary.withOpacity(0.35),
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
                        item.relativeTime,
                        style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
