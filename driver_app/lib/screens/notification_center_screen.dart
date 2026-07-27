import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/notification_item.dart';
import '../services/notification_storage.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await NotificationStorage.removeExpiredImages();
    final items = await NotificationStorage.loadAll();
    setState(() {
      _notifications = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A1A12) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F2D1A) : Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'الإشعارات',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontFamily: 'Cairo',
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white70 : Colors.grey.shade600, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_notifications.isNotEmpty)
              IconButton(
                icon: Icon(Icons.done_all, color: const Color(0xFF10B981), size: 22),
                onPressed: () async {
                  await NotificationStorage.markAllRead();
                  _loadNotifications();
                },
                tooltip: 'قراءة الكل',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : _notifications.isEmpty
                ? _buildEmptyState(isDark)
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: const Color(0xFF10B981),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) => _buildNotificationCard(_notifications[index], isDark),
                    ),
                    ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, bool isDark) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await NotificationStorage.delete(item.id);
        setState(() => _notifications.removeWhere((n) => n.id == item.id));
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () async {
          await NotificationStorage.markAsRead(item.id);
          setState(() => item.isRead = true);
          if (item.imageUrl != null) {
            _showFullImage(item, isDark);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? (item.isRead ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.08))
                : (item.isRead ? Colors.white : const Color(0xFFEDFCF2)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? Colors.transparent
                  : const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active, color: Color(0xFF10B981), size: 20),
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
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTimestamp(item.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              if (item.imageUrl != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 50, height: 50, fit: BoxFit.cover,
                    placeholder: (c, u) => Container(width: 50, height: 50, color: Colors.grey.shade200),
                    errorWidget: (c, u, e) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 20)),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  await NotificationStorage.delete(item.id);
                  setState(() => _notifications.removeWhere((n) => n.id == item.id));
                },
                child: Icon(Icons.done_all, size: 20, color: const Color(0xFF10B981).withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(NotificationItem item, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder: (c, u) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (c, u, e) => const Icon(Icons.broken_image, color: Colors.white, size: 48),
                ),
              ),
            const SizedBox(height: 12),
            Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(item.body, style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo'), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('dd/MM/yyyy HH:mm', 'ar').format(dt);
  }
}
