import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationStorage {
  static const _key = 'kiwi_ops_notifications_inbox';

  static Future<List<NotificationItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) {
          try {
            return NotificationItem.decode(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<NotificationItem>()
        .toList();
  }

  static Future<void> save(NotificationItem n) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load()..removeWhere((x) => x.id == n.id);
    list.insert(0, n);
    if (list.length > 100) list.removeRange(100, list.length);
    await prefs.setStringList(_key, list.map((x) => x.encode()).toList());
  }

  static Future<void> markRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    for (final n in list) {
      if (n.id == id) n.isRead = true;
    }
    await prefs.setStringList(_key, list.map((x) => x.encode()).toList());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}