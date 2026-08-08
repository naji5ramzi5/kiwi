import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/ops_api.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التقارير', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'التوصيلات'),
            Tab(text: 'سجل النقل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _DeliveredReportTab(),
          _TransferHistoryTab(),
        ],
      ),
    );
  }
}

class _DeliveredReportTab extends StatefulWidget {
  const _DeliveredReportTab();

  @override
  State<_DeliveredReportTab> createState() => _DeliveredReportTabState();
}

class _DeliveredReportTabState extends State<_DeliveredReportTab> {
  List<DeliveredOrder>? _orders;
  bool _loading = true;
  String? _error;
  DateTime? _from;
  DateTime? _to;

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
      final orders = await OpsApi.fetchDeliveredOrders(from: _from, to: _to, limit: 500);
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end.add(const Duration(days: 1));
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _from == null
                        ? 'كل الفترة'
                        : '${DateFormat('d/M').format(_from!)} - ${DateFormat('d/M').format(_to!)}',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Colors.grey),
            const SizedBox(height: 10),
            const Text('تعذر تحميل التقرير'),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    final orders = _orders ?? [];
    final totalAmount = orders.fold<double>(0, (s, o) => s + o.totalAmount);
    final totalFee = orders.fold<double>(0, (s, o) => s + o.deliveryFee);
    final fmt = NumberFormat('#,##0');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(fmt.format(orders.length),
                        style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10b981))),
                    Text('عدد الطلبات',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(fmt.format(totalAmount),
                        style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0ea5e9))),
                    Text('إجمالي المبيعات',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(fmt.format(totalFee),
                        style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8b5cf6))),
                    Text('رسوم التوصيل',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.inbox, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text('لا توجد طلبات في هذه الفترة',
                    style: GoogleFonts.cairo(color: Colors.grey)),
              ],
            ),
          )
        else
          ...orders.map((o) => _orderCard(o)),
      ],
    );
  }

  Widget _orderCard(DeliveredOrder o) {
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
            width: 40,
            height: 40,
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
                Text(o.orderNumber,
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text(o.customerName ?? 'عميل مباشر',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade700)),
                Text(
                  '${o.branchName ?? ''} - ${o.employeeName ?? ''}',
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(NumberFormat('#,##0').format(o.deliveryFee),
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10b981))),
              Text(o.deliveredAt != null
                  ? DateFormat('d/M HH:mm').format(o.deliveredAt!.toLocal())
                  : '—',
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransferHistoryTab extends StatefulWidget {
  const _TransferHistoryTab();

  @override
  State<_TransferHistoryTab> createState() => _TransferHistoryTabState();
}

class _TransferHistoryTabState extends State<_TransferHistoryTab> {
  List<Map<String, dynamic>>? _rows;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await OpsApi.fetchTransferHistory();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final rows = _rows ?? const [];
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz, size: 44, color: Colors.grey),
            const SizedBox(height: 10),
            const Text('لا يوجد سجل نقل'),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _load, child: const Text('تحديث')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final r = rows[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Color(0xFF8b5cf6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['employee_name']?.toString() ?? '—',
                          style: GoogleFonts.cairo(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(
                        '${r['old_branch_name']} ← ${r['new_branch_name']}',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade700),
                      ),
                      if ((r['reason']?.toString() ?? '').isNotEmpty)
                        Text(
                          r['reason'].toString(),
                          style: GoogleFonts.cairo(fontSize: 10, color: Colors.blueGrey),
                        ),
                    ],
                  ),
                ),
                Text(
                  r['transferred_at'] != null
                      ? DateFormat('d/M HH:mm')
                          .format(DateTime.parse(r['transferred_at'].toString()).toLocal())
                      : '—',
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}