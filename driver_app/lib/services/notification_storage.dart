import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationStorage {
  static const String _key = 'app_notifications';
  static const int _maxItems = 100;

  static Future<List<NotificationItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => NotificationItem.decode(e)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> save(NotificationItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.insert(0, item.encode());
    if (list.length > _maxItems) list.removeRange(_maxItems, list.length);
    await prefs.setStringList(_key, list);
  }

  static Future<void> markAsRead(String id) async {
    final items = await loadAll();
    for (final item in items) {
      if (item.id == id) item.isRead = true;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items.map((e) => e.encode()).toList());
  }

  static Future<void> markAllRead() async {
    final items = await loadAll();
    for (final item in items) {
      item.isRead = true;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items.map((e) => e.encode()).toList());
  }

  static Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items.map((e) => e.encode()).toList());
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> removeExpiredImages({Duration ttl = const Duration(hours: 24)}) async {
    final items = await loadAll();
    final now = DateTime.now();
    bool changed = false;
    for (final item in items) {
      if (item.imageUrl != null && now.difference(item.timestamp) > ttl) {
        item.imageUrl = null;
        changed = true;
      }
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, items.map((e) => e.encode()).toList());
    }
  }
}
