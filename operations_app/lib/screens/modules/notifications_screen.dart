import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/notification_storage.dart';
import '../../models/notification_item.dart';
import '../../services/ops_api.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem>? _inbox;
  List<NotificationRow>? _opsRows;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      NotificationStorage.load(),
      OpsApi.fetchNotifications(),
    ]);
    if (!mounted) return;
    setState(() {
      _inbox = (results[0] as List).cast<NotificationItem>();
      _opsRows = (results[1] as List).cast<NotificationRow>();
      _loading = false;
    });
  }

  Future<void> _markRead(NotificationItem n) async {
    if (n.isRead) return;
    n.isRead = true;
    await NotificationStorage.markRead(n.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('مسح الإشعارات',
                      style: GoogleFonts.cairo(fontSize: 16)),
                  content: Text('هل تريد مسح سجل الإشعارات المحلي؟',
                      style: GoogleFonts.cairo(fontSize: 13)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('مسح')),
                  ],
                ),
              );
              if (ok == true) {
                await NotificationStorage.clear();
                _load();
              }
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final local = (_inbox ?? [])
        .where((n) => !n.isExpired)
        .toList();
    final ops = _opsRows ?? [];

    if (local.isEmpty && ops.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Icon(Icons.notifications_off_outlined,
                    size: 44, color: Colors.grey),
                const SizedBox(height: 8),
                Text('لا توجد إشعارات',
                    style: GoogleFonts.cairo(color: Colors.grey)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (ops.isNotEmpty) ...[
          Text('إشعارات النظام',
              style: GoogleFonts.cairo(
                  fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...ops.map(_opsCard),
          const SizedBox(height: 16),
        ],
        if (local.isNotEmpty) ...[
          Text('الجهاز',
              style: GoogleFonts.cairo(
                  fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...local.map(_localCard),
        ],
      ],
    );
  }

  Widget _opsCard(NotificationRow n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0ea5e9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_outlined,
                color: Color(0xFF0ea5e9), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                if (n.message.isNotEmpty)
                  Text(n.message,
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey.shade700)),
                if (n.createdAt != null)
                  Text(
                    DateFormat('d/M HH:mm').format(n.createdAt!.toLocal()),
                    style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _localCard(NotificationItem n) {
    return InkWell(
      onTap: () => _markRead(n),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : const Color(0xFF10b981).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n.isRead
                ? Colors.transparent
                : const Color(0xFF10b981).withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF10b981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  color: Color(0xFF10b981), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: GoogleFonts.cairo(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  if (n.body.isNotEmpty)
                    Text(n.body,
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.grey.shade700)),
                  Text(
                    DateFormat('d/M HH:mm').format(n.timestamp.toLocal()),
                    style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF10b981),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}