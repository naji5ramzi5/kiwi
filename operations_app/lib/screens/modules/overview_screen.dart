import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/ops_api.dart';
import '../../services/auth_service.dart';
import 'branch_performance_screen.dart';
import 'reports_screen.dart';
import 'map_screen.dart';

class OverviewScreen extends StatefulWidget {
  final AuthState auth;
  const OverviewScreen({super.key, required this.auth});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  Map<String, dynamic>? _data;
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
      final data = await OpsApi.dashboardData();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = OpsApi.friendlyError(e, fallback: 'تعذر تحميل البيانات');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لوحة التشغيل',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            Text(
              widget.auth.role.label,
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => AuthService.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('تعذر تحميل البيانات',
                style: GoogleFonts.cairo(fontSize: 16)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final d = _data!['dashboard'] as OpsDashboard;
    final branches = (_data!['branches'] as List).cast<BranchSummary>();
    final employees = _data!['employees'] as List;
    final pending = _data!['pending'] as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _kpiRow(d),
        const SizedBox(height: 16),
        _sectionTitle('الروابط السريعة'),
        const SizedBox(height: 8),
        _quickLinks(branches),
        const SizedBox(height: 20),
        _sectionTitle('أداء الفروع (اليوم)'),
        const SizedBox(height: 8),
        _branchList(branches),
        const SizedBox(height: 20),
        _sectionTitle('الطلبات المعلقة'),
        const SizedBox(height: 8),
        _pendingList(pending),
        const SizedBox(height: 20),
        _sectionTitle('المندوبون ($employees.length)'),
        const SizedBox(height: 8),
        _employeeSummary(employees),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
      );

  Widget _kpiRow(OpsDashboard d) {
    final cards = [
      ('منجزة اليوم', d.deliveredToday, Icons.task_alt, const Color(0xFF10b981)),
      ('أرباح اليوم', NumberFormat('#,##0').format(d.totalEarningsToday), Icons.payments, const Color(0xFF0ea5e9)),
      ('أرباح التوصيل', NumberFormat('#,##0').format(d.avgDeliveryFee), Icons.local_shipping, const Color(0xFF8b5cf6)),
      ('معلق', d.pendingOrders, Icons.hourglass_top, const Color(0xFFf59e0b)),
      ('مناديب نشطين', d.activeEmployees, Icons.person_pin, const Color(0xFFef4444)),
      ('متصل الآن', d.onlineEmployees, Icons.wifi, const Color(0xFF14b8a6)),
      ('بانتظار الموافقة', d.pendingApprovals, Icons.how_to_reg, const Color(0xFF6366f1)),
      ('الفروع', d.totalBranches, Icons.store, const Color(0xFFec4899)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: cards
          .map((c) => _kpiCard(c.$1, c.$2.toString(), c.$3, c.$4))
          .toList(),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(
                    value,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                FittedBox(
                  child: Text(
                    label,
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickLinks(List<BranchSummary> branches) {
    return Row(
      children: [
        _quickLink(Icons.emoji_events, 'أداء الفروع', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BranchPerformanceScreen()));
        }),
        const SizedBox(width: 10),
        _quickLink(Icons.insert_chart_outlined, 'التقارير', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()));
        }),
        const SizedBox(width: 10),
        _quickLink(Icons.map_outlined, 'الخريطة', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MapScreen()));
        }),
      ],
    );
  }

  Widget _quickLink(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF10b981), size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _branchList(List<BranchSummary> branches) {
    final sorted = [...branches]..sort((a, b) => b.delivered.compareTo(a.delivered));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: sorted
            .map((b) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.store, color: Color(0xFF10b981)),
                  title: Text(b.name,
                      style: GoogleFonts.cairo(fontSize: 14)),
                  subtitle: Text(
                    b.status ?? '',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${b.delivered} طلب',
                          style: GoogleFonts.cairo(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(
                        NumberFormat('#,##0').format(b.earnings),
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: const Color(0xFF10b981)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _pendingList(List pending) {
    if (pending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10b981)),
            const SizedBox(width: 8),
            Text('لا توجد طلبات معلقة حالياً',
                style: GoogleFonts.cairo(fontSize: 13)),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: pending
            .take(5)
            .map((p) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.hourglass_top,
                      color: Color(0xFFf59e0b)),
                  title: Text(
                    '#${LiveOrder.shortId(p['id']?.toString() ?? '')}',
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                  subtitle: Text(
                    p['status']?.toString() ?? '',
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.grey),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _employeeSummary(List employees) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: employees
            .take(6)
            .map((e) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF10b981).withOpacity(0.1),
                    child: Icon(
                      e['is_online'] == true
                          ? Icons.wifi
                          : Icons.person_outline,
                      size: 18,
                      color: e['is_online'] == true
                          ? const Color(0xFF10b981)
                          : Colors.grey,
                    ),
                  ),
                  title: Text(e['full_name']?.toString() ?? '—',
                      style: GoogleFonts.cairo(fontSize: 13)),
                  subtitle: Text(
                    '${e['total_deliveries']?.toString() ?? '0'} توصيل',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: Text(
                    NumberFormat('#,##0').format(
                        double.tryParse(e['wallet_balance']?.toString() ?? '0') ??
                            0),
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10b981)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}