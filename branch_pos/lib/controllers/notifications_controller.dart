import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/notifications_page.dart';

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime? createdAt;
  final bool isNew;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.createdAt,
    this.isNew = false,
  });

  factory AdminNotification.fromRow(Map<String, dynamic> m, DateTime lastSeen) {
    final createdAt = DateTime.tryParse(m['created_at']?.toString() ?? '');
    return AdminNotification(
      id: m['id']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      message: m['message']?.toString() ?? '',
      type: m['type']?.toString() ?? 'admin_note',
      createdAt: createdAt,
      isNew: createdAt != null && createdAt.isAfter(lastSeen),
    );
  }
}

/// جرس الإشعارات في برنامج الفرع:
/// يستعلم admin_notifications كل 20 ثانية ويظهر العدد + تنبيه للإعلانات الجديدة
class NotificationsController extends GetxController {
  final supabase = Supabase.instance.client;
  static const _prefKey = 'pos_admin_notif_last_seen';

  final notifications = <AdminNotification>[].obs;
  final unreadCount = 0.obs;
  final loading = false.obs;

  DateTime _lastSeen = DateTime.now().subtract(const Duration(days: 30));
  Timer? _timer;
  String? _lastNotifiedId;

  @override
  void onInit() {
    super.onInit();
    _loadLastSeen();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _loadLastSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) _lastSeen = parsed.toLocal();
      }
    } catch (_) {}
    poll();
    startPolling();
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => poll());
  }

  Future<void> poll() async {
    if (loading.value) return;
    loading.value = true;
    try {
      final rows = await supabase
          .from('admin_notifications')
          .select('id,title,message,type,created_at,target_branch_id')
          .order('created_at', ascending: false)
          .limit(100);

      final list = rows.map((m) => AdminNotification.fromRow(m, _lastSeen)).toList();
      final unread = list.where((n) => n.isNew).length;

      // في حالة وجود إعلان جديد نعرض تنبيهاً داخل التطبيق
      if (list.isNotEmpty) {
        final newest = list.first;
        if (newest.isNew && newest.id != _lastNotifiedId) {
          _lastNotifiedId = newest.id;
          Get.snackbar(
            newest.title,
            newest.message,
            duration: const Duration(seconds: 6),
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(12),
            borderRadius: 12,
            shouldIconPulse: true,
            onTap: (_) {
              Get.back();
              Get.to(() => const NotificationsPage());
            },
          );
        }
      }

      notifications.assignAll(list);
      unreadCount.value = unread;
    } catch (_) {
      // لا إنترنت أو إغلاق مؤقت — نتجاهل بهدوء
    } finally {
      loading.value = false;
    }
  }

  Future<void> markAllRead() async {
    _lastSeen = DateTime.now();
    unreadCount.value = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _lastSeen.toIso8601String());
    poll();
  }
}