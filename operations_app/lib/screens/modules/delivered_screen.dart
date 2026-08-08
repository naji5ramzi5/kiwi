import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ops_api.dart';

class DeliveredScreen extends StatefulWidget {
  const DeliveredScreen({super.key});

  @override
  State<DeliveredScreen> createState() => _DeliveredScreenState();
}

class _DeliveredScreenState extends State<DeliveredScreen> {
  List<DeliveredOrder>? _orders;
  bool _loading = true;
  String? _error;
  DateTime? _from;
  DateTime? _to;
  String? _branchFilter;
  List<Map<String, dynamic>>? _branches;

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
      final results = await Future.wait([
        OpsApi.fetchDeliveredOrders(from: _from, to: _to, limit: 200),
        _fetchBranches(),
      ]);
      if (!mounted) return;
      setState(() {
        _orders = (results[0] as List).cast<DeliveredOrder>();
        _branches = results[1] as List<Map<String, dynamic>>;
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

  Future<List<Map<String, dynamic>>> _fetchBranches() async {
    return await Supabase.instance.client.from('branches').select('id,name');
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!.subtract(const Duration(days: 1)))
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
    return Scaffold(
      appBar: AppBar(
        title: Text('الطلبات المنجزة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
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
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Colors.grey),
            const SizedBox(height: 10),
            const Text('تعذر تحميل البيانات'),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final orders = (_orders ?? []);
    var filtered = orders;
    if (_branchFilter != null) {
      filtered = orders.where((o) => o.branchName == _branchFilter).toList();
    }

    final totalFee = filtered.fold<double>(0, (s, o) => s + o.deliveryFee);
    final totalAmount = filtered.fold<double>(0, (s, o) => s + o.totalAmount);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _from == null
                        ? 'كل الفترة'
                        : '${DateFormat('d/M').format(_from!)} - ${DateFormat('d/M').format(_to!)}',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_branches != null && _branches!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text('الفرع'),
                      value: _branchFilter,
                      isDense: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('الكل')),
                        ..._branches!
                            .map((b) => DropdownMenuItem(
                                  value: b['name']?.toString(),
                                  child: Text(b['name']?.toString() ?? '',
                                      style: GoogleFonts.cairo(fontSize: 12)),
                                ))
                            .toList(),
                      ],
                      onChanged: (v) => setState(() => _branchFilter = v),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              _statCard('عدد الطلبات', filtered.length.toString(),
                  const Color(0xFF10b981)),
              const SizedBox(width: 8),
              _statCard('إجمالي المبيعات',
                  NumberFormat('#,##0').format(totalAmount),
                  const Color(0xFF0ea5e9)),
              const SizedBox(width: 8),
              _statCard('رسوم التوصيل',
                  NumberFormat('#,##0').format(totalFee),
                  const Color(0xFF8b5cf6)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.inbox, size: 44, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('لا توجد طلبات',
                              style: GoogleFonts.cairo(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _orderCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.orderNumber,
                  style: GoogleFonts.cairo(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              Text(
                o.deliveredAt != null
                    ? DateFormat('d/M HH:mm').format(o.deliveredAt!.toLocal())
                    : '—',
                style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(o.customerName ?? 'عميل مباشر',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade800)),
          Text(
            '${o.branchName ?? ''} ${o.employeeName != null ? '• ${o.employeeName}' : ''}',
            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 15, color: const Color(0xFF10b981)),
              const SizedBox(width: 4),
              Text(
                NumberFormat('#,##0').format(o.deliveryFee),
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10b981)),
              ),
              const Spacer(),
              if (o.proofImage != null && o.proofImage!.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _showProof(o.proofImage!),
                  icon: const Icon(Icons.photo_outlined, size: 16),
                  label: Text('إثبات التسليم',
                      style: GoogleFonts.cairo(fontSize: 11)),
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
                  Text('تعذر تحميل الصورة',
                      style: GoogleFonts.cairo(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}