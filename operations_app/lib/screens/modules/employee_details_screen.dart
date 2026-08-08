import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/ops_api.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final DeliveryEmployeeModel employee;
  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  List<EmployeeDeliveryRecord>? _history;
  bool _loadingHistory = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final h = await OpsApi.fetchEmployeeDeliveries(employeeId: widget.employee.id);
      if (!mounted) return;
      setState(() {
        _history = h;
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = e is OpsApiException ? e.message : 'تعذر تحميل السجل';
        _loadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.employee;
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل المندوب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _profileCard(e),
            const SizedBox(height: 16),
            _statsGrid(e),
            const SizedBox(height: 16),
            _currentOrderCard(e),
            const SizedBox(height: 16),
            Text('سجل التوصيلات', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _historySection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(DeliveryEmployeeModel e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF10b981).withOpacity(0.12),
            child: Text(
              e.fullName.isEmpty ? '؟' : e.fullName.substring(0, 1),
              style: GoogleFonts.cairo(fontSize: 26, color: const Color(0xFF10b981), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(e.fullName, style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoBadge(e.isOnline ? 'متصل' : 'غير متصل',
                  e.isOnline ? const Color(0xFF10b981) : const Color(0xFF94a3b8)),
              const SizedBox(width: 6),
              _infoBadge(e.accountStatusLabel,
                  !e.isApproved ? const Color(0xFFf59e0b) : (!e.isActive ? const Color(0xFFef4444) : const Color(0xFF10b981))),
            ],
          ),
          const SizedBox(height: 12),
          _row('الهاتف', e.phone.isEmpty ? '—' : e.phone, Icons.phone),
          _row('البريد', e.email.isEmpty ? '—' : e.email, Icons.email_outlined),
          _row('الفرع', e.branchName.isEmpty ? '—' : e.branchName, Icons.store_outlined),
          _row('المركبة', e.vehicleLabel, Icons.delivery_dining),
          _row('تاريخ الانضمام', e.joinedAt != null ? DateFormat('d/M/y').format(e.joinedAt!.toLocal()) : '—', Icons.event_outlined),
          _row('آخر نشاط', _lastActiveText(e), Icons.schedule_outlined),
        ],
      ),
    );
  }

  String _lastActiveText(DeliveryEmployeeModel e) {
    final t = e.lastActiveAt;
    if (t == null) return '—';
    final diff = DateTime.now().difference(t.toLocal());
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return DateFormat('d/M HH:mm').format(t.toLocal());
  }

  Widget _row(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _infoBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: GoogleFonts.cairo(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _statsGrid(DeliveryEmployeeModel e) {
    final items = [
      ('توصيلات اليوم', '${e.todayDeliveries}', const Color(0xFF10b981)),
      ('توصيلات الشهر', '${e.monthDeliveries}', const Color(0xFF0ea5e9)),
      ('إجمالي التوصيلات', '${e.totalDeliveries}', const Color(0xFF8b5cf6)),
      ('أرباح اليوم', NumberFormat('#,##0 د.ع').format(e.todayEarnings), const Color(0xFF10b981)),
      ('أرباح الشهر', NumberFormat('#,##0 د.ع').format(e.monthEarnings), const Color(0xFF0ea5e9)),
      ('إجمالي الأرباح', NumberFormat('#,##0 د.ع').format(e.totalEarnings), const Color(0xFF8b5cf6)),
      ('رصيد المحفظة', NumberFormat('#,##0 د.ع').format(e.walletBalance), const Color(0xFFf59e0b)),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((it) => SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: it.$3.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: it.$3.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.$2, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: it.$3)),
                      const SizedBox(height: 2),
                      Text(it.$1, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _currentOrderCard(DeliveryEmployeeModel e) {
    if (e.currentOrderNo == null || e.currentOrderNo!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.task_alt, color: Color(0xFF10b981)),
            const SizedBox(width: 8),
            Text('لا يوجد طلب نشط حالياً', style: GoogleFonts.cairo(fontSize: 13)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0ea5e9).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, size: 20, color: Color(0xFF0ea5e9)),
              const SizedBox(width: 8),
              Text('الطلب الحالي: ${e.currentOrderNo}',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          if ((e.currentCustomerName ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('العميل: ${e.currentCustomerName}',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade700)),
          ],
          if ((e.currentOrderStatus ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('الحالة: ${e.currentOrderStatus}',
                style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF0ea5e9))),
          ],
        ],
      ),
    );
  }

  Widget _historySection() {
    if (_loadingHistory) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    if (_historyError != null) {
      return Center(
        child: Column(
          children: [
            Text(_historyError!, style: GoogleFonts.cairo(fontSize: 12, color: Colors.redAccent)),
            TextButton(onPressed: _loadHistory, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    final history = _history ?? [];
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Center(child: Text('لا توجد توصيلات مسجلة', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey))),
      );
    }
    return Column(
      children: history.map((h) => _historyCard(h)).toList(),
    );
  }

  Widget _historyCard(EmployeeDeliveryRecord h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, color: Color(0xFF10b981)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.orderNumber,
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(h.customerName.isEmpty ? 'عميل مباشر' : h.customerName,
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade700)),
                Text(
                  '${h.branchName.isEmpty ? '' : h.branchName} ${h.deliveredAt != null ? '• ' + DateFormat('d/M HH:mm').format(h.deliveredAt!.toLocal()) : ''}',
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(NumberFormat('#,##0 د.ع').format(h.earnings),
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10b981))),
              if (h.proofImage != null && h.proofImage!.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                  onPressed: () => _showProof(h.proofImage!),
                  icon: const Icon(Icons.photo_outlined, size: 14),
                  label: Text('الإثبات', style: GoogleFonts.cairo(fontSize: 10)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProof(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('تعذر تحميل الصورة', style: GoogleFonts.cairo(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}