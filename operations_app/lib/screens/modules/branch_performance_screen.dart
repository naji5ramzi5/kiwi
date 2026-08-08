import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/ops_api.dart';

class BranchPerformanceScreen extends StatefulWidget {
  const BranchPerformanceScreen({super.key});

  @override
  State<BranchPerformanceScreen> createState() => _BranchPerformanceScreenState();
}

class _BranchPerformanceScreenState extends State<BranchPerformanceScreen> {
  List<BranchSummary>? _branches;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await OpsApi.dashboardData();
      if (!mounted) return;
      setState(() {
        _branches = (d['branches'] as List).cast<BranchSummary>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أداء الفروع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null || _branches == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('تعذر تحميل البيانات'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final totalDelivered = _branches!.fold<int>(0, (s, b) => s + b.delivered);
    final totalEarnings = _branches!.fold<double>(0, (s, b) => s + b.earnings);
    final totalEmployees = _branches!.fold<int>(0, (s, b) => s + b.employees);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _sumCard('إجمالي التوصيل', totalDelivered, const Color(0xFF10b981)),
            const SizedBox(width: 10),
            _sumCard('إجمالي الأرباح', NumberFormat('#,##0').format(totalEarnings), const Color(0xFF0ea5e9)),
            const SizedBox(width: 10),
            _sumCard('عدد الموظفين', totalEmployees, const Color(0xFF8b5cf6)),
          ],
        ),
        const SizedBox(height: 20),
        Text('ترتيب الفروع حسب التوصيلات',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final b in _branches!) _branchCard(b),
      ],
    );
  }

  Widget _sumCard(String label, dynamic value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value.toString(),
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _branchCard(BranchSummary b) {
    final maxDelivered = _branches!.isEmpty
        ? 1
        : (_branches!.map((x) => x.delivered).reduce((a, c) => a > c ? a : c) + 0.0);
    final fraction = maxDelivered == 0 ? 0.0 : (b.delivered / maxDelivered).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(b.name,
                      style: GoogleFonts.cairo(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  if (b.status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: b.status == 'نشط'
                            ? const Color(0xFF10b981).withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(b.status!,
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: b.status == 'نشط'
                                  ? const Color(0xFF10b981)
                                  : Colors.red)),
                    ),
                ],
              ),
              Text('${b.delivered} توصيل',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10b981))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF10b981),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${b.employees} موظف',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
              Text(NumberFormat('#,##0 د.ع').format(b.earnings),
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: const Color(0xFF0ea5e9),
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}