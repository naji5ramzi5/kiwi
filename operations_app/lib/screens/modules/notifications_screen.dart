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

  void _openComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationComposer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'إرسال إشعار',
            onPressed: _openComposer,
            icon: const Icon(Icons.outgoing_mail, color: Color(0xFF10b981)),
          ),
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

/// نموذج إنشاء وإرسال إشعار للمندوبين — بلا broadcast
class NotificationComposer extends StatefulWidget {
  const NotificationComposer({super.key});

  @override
  State<NotificationComposer> createState() => _NotificationComposerState();
}

class _NotificationComposerState extends State<NotificationComposer> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageController = TextEditingController();

  String _target = 'all'; // all | branch | driver
  String? _branchId;
  String? _driverId;
  int? _recipientCount;
  bool _counting = false;
  bool _sending = false;

  List<Map<String, dynamic>>? _branches;
  List<DeliveryEmployeeModel>? _drivers;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        OpsApi.fetchBranches(),
        OpsApi.fetchEmployees(),
      ]);
      if (!mounted) return;
      setState(() {
        _branches = (results[0] as List).cast<Map<String, dynamic>>();
        _drivers = (results[1] as List).cast<DeliveryEmployeeModel>();
      });
    } catch (_) {}
  }

  Future<void> _previewCount() async {
    setState(() => _counting = true);
    try {
      int count = 0;
      if (_target == 'all') {
        final tokens = await OpsApi.fetchDriverFcmTokens();
        count = tokens.length;
      } else if (_target == 'branch') {
        if (_branchId == null) {
          throw const OpsApiException('اختر الفرع أولاً');
        }
        final tokens = await OpsApi.fetchDriverFcmTokens(branchId: _branchId);
        count = tokens.length;
      } else {
        if (_driverId == null) {
          throw const OpsApiException('اختر المندوب أولاً');
        }
        final tokens = await OpsApi.fetchDriverFcmTokens(profileIds: [_driverId!]);
        count = tokens.length;
      }
      if (!mounted) return;
      setState(() {
        _recipientCount = count;
        _counting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _counting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is OpsApiException ? e.message : 'تعذر حساب المستلمين',
            style: GoogleFonts.cairo(fontSize: 12)),
      ));
    }
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) {
      _toast('اكتب عنوان الإشعار');
      return;
    }
    if (body.isEmpty) {
      _toast('اكتب نص الإشعار');
      return;
    }

    setState(() => _sending = true);
    try {
      List<String> tokens;
      if (_target == 'branch') {
        if (_branchId == null) throw const OpsApiException('اختر الفرع أولاً');
        tokens = await OpsApi.fetchDriverFcmTokens(branchId: _branchId);
      } else if (_target == 'driver') {
        if (_driverId == null) throw const OpsApiException('اختر المندوب أولاً');
        tokens = await OpsApi.fetchDriverFcmTokens(profileIds: [_driverId!]);
      } else {
        tokens = await OpsApi.fetchDriverFcmTokens();
      }

      if (tokens.isEmpty) {
        throw const OpsApiException('لا توجد أجهزة مستهدفة لهذا الاختيار');
      }

      final sent = await OpsApi.sendDriverNotification(
        title: title,
        body: body,
        imageUrl: _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
        tokens: tokens,
      );

      // يظهر الإعلان أيضاً في تطبيق الإدارة وبرنامج الفروع (الجرس)
      try {
        String? branchId;
        if (_target == 'branch') branchId = _branchId;
        await OpsApi.broadcastAdminNote(
          title: title,
          message: body,
          targetBranchId: branchId,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() => _sending = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF10b981),
        content: Text('تم الإرسال بنجاح — $sent جهاز',
            style: GoogleFonts.cairo(fontSize: 12)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _toast(e is OpsApiException ? e.message : 'تعذر إرسال الإشعار');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo(fontSize: 12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('إرسال إشعار للمندوبين',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textAlign: TextAlign.right,
              decoration: _fieldDecoration('عنوان الإشعار'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              textAlign: TextAlign.right,
              maxLines: 4,
              decoration: _fieldDecoration('نص الإشعار'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _imageController,
              textAlign: TextAlign.left,
              decoration: _fieldDecoration('رابط صورة (اختياري)'),
            ),
            const SizedBox(height: 16),
            Text('الاستهداف', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _targetChip('الكل', 'all'),
                const SizedBox(width: 8),
                _targetChip('فرع معيّن', 'branch'),
                const SizedBox(width: 8),
                _targetChip('مندوب معيّن', 'driver'),
              ],
            ),
            const SizedBox(height: 12),
            if (_target == 'branch') ...[
              DropdownButtonFormField<String>(
                initialValue: _branchId,
                isExpanded: true,
                decoration: _fieldDecoration('اختر الفرع'),
                items: (_branches ?? [])
                    .map((b) => DropdownMenuItem(
                          value: b['id'].toString(),
                          child: Text(b['name']?.toString() ?? '—',
                              style: GoogleFonts.cairo(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _branchId = v),
              ),
              const SizedBox(height: 10),
            ],
            if (_target == 'driver') ...[
              DropdownButtonFormField<String>(
                initialValue: _driverId,
                isExpanded: true,
                decoration: _fieldDecoration('اختر المندوب'),
                items: (_drivers ?? [])
                    .map((d) => DropdownMenuItem(
                          value: d.userId,
                          child: Text('${d.fullName} — ${d.branchName}',
                              style: GoogleFonts.cairo(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _driverId = v),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _counting ? null : _previewCount,
                    icon: _counting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.people_alt_outlined, size: 16),
                    label: Text('معاينة المستلمين', style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
                if (_recipientCount != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$_recipientCount جهاز',
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10b981))),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10b981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(_sending ? 'جارٍ الإرسال...' : 'إرسال الإشعار',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetChip(String label, String value) {
    final selected = _target == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _target = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF10b981) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? const Color(0xFF10b981) : Colors.transparent),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(fontSize: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}