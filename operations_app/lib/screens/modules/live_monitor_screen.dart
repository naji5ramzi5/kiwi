import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ops_api.dart';

class LiveMonitorScreen extends StatefulWidget {
  const LiveMonitorScreen({super.key});

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  List<LiveOrder>? _orders;
  List<EmployeeRow>? _employees;
  bool _loading = true;
  bool _realtime = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        OpsApi.fetchLiveOrders(),
        OpsApi.fetchEmployees(),
      ]);
      if (!mounted) return;
      setState(() {
        _orders = results[0] as List<LiveOrder>;
        _employees = results[1] as List<EmployeeRow>;
        _loading = false;
      });
    } on OpsApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: GoogleFonts.cairo()),
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذر تحميل البيانات الحية',
            style: GoogleFonts.cairo()),
        duration: const Duration(seconds: 3),
      ));
    }
    if (_realtime) _subscribe();
  }

  void _subscribe() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('ops_live_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            if (!mounted) return;
            _load();
          },
        )
        .subscribe();
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'معلق';
      case 'picked_up':
        return 'تم الاستلام';
      case 'on_the_way':
        return 'في الطريق';
      case 'accepted':
        return 'تم القبول';
      case 'delivered':
        return 'تم التوصيل';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFf59e0b);
      case 'picked_up':
        return const Color(0xFF3b82f6);
      case 'on_the_way':
        return const Color(0xFF8b5cf6);
      case 'accepted':
        return const Color(0xFF0ea5e9);
      case 'delivered':
        return const Color(0xFF10b981);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مراقبة مباشرة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: _realtime ? 'إيقاف التحديث الفوري' : 'تشغيل التحديث الفوري',
            onPressed: () {
              setState(() => _realtime = !_realtime);
              if (_realtime) {
                _subscribe();
              } else {
                _channel?.unsubscribe();
                _channel = null;
              }
            },
            icon: Icon(
              _realtime ? Icons.sync : Icons.sync_disabled,
              color: _realtime ? const Color(0xFF10b981) : Colors.grey,
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    final orders = _orders ?? [];
    final byStatus = <String, List<LiveOrder>>{};
    for (final o in orders) {
      byStatus.putIfAbsent(o.status, () => []).add(o);
    }

    final statusOrder = ['pending', 'accepted', 'picked_up', 'on_the_way'];
    final statuses = statusOrder.where(byStatus.containsKey).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (statuses.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF10b981)),
                const SizedBox(height: 10),
                Text('لا توجد طلبات نشطة حالياً',
                    style: GoogleFonts.cairo(color: Colors.grey)),
              ],
            ),
          )
        else
          ...statuses.map((s) => _statusSection(s, byStatus[s]!)),
      ],
    );
  }

  Widget _statusSection(String status, List<LiveOrder> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${_statusLabel(status)} (${orders.length})',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...orders.map((o) => _orderCard(o)),
      ],
    );
  }

  Widget _orderCard(LiveOrder o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor(o.status).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.orderNumber,
                  style: GoogleFonts.cairo(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(o.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_statusLabel(o.status),
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: _statusColor(o.status))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(o.customerName ?? 'عميل مباشر',
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade800)),
          Text(o.address ?? '—',
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 16, color: o.driverName != null
                      ? const Color(0xFF10b981)
                      : Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  o.driverName ?? 'غير معين',
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: o.driverName != null
                          ? const Color(0xFF10b981)
                          : Colors.grey),
                ),
              ),
              Text(NumberFormat('#,##0').format(o.deliveryFee),
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0ea5e9))),
              if (o.createdAt != null) ...[
                const SizedBox(width: 10),
                Text(
                  DateFormat('HH:mm').format(o.createdAt!.toLocal()),
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
          if (o.status == 'pending') ...[
            const SizedBox(height: 8),
            _assignButton(o),
          ],
        ],
      ),
    );
  }

  Widget _assignButton(LiveOrder o) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF10b981),
        ),
        onPressed: () => _showAssignSheet(o),
        icon: const Icon(Icons.assignment_ind, size: 18),
        label: Text('تعيين مندوب', style: GoogleFonts.cairo(fontSize: 13)),
      ),
    );
  }

  void _showAssignSheet(LiveOrder o) {
    final available = (_employees ?? [])
        .where((e) => e.isOnline || true)
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تعيين مندوب للطلب ${o.orderNumber}',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (available.isEmpty)
              Text('لا يوجد مناديب متاحون',
                  style: GoogleFonts.cairo(color: Colors.grey))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (context, i) {
                    final e = available[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF10b981).withOpacity(0.1),
                        child: Icon(
                          e.isOnline ? Icons.wifi : Icons.person_outline,
                          size: 18,
                          color: e.isOnline
                              ? const Color(0xFF10b981)
                              : Colors.grey,
                        ),
                      ),
                      title: Text(e.fullName,
                          style: GoogleFonts.cairo(fontSize: 13)),
                      subtitle: Text(
                        '${e.branchName} - ${e.totalDeliveries} توصيل',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final ok = await OpsApi.assignOrderToEmployee(
                            orderId: o.id,
                            employeeId: e.id,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? 'تم تعيين المندوب' : 'فشل التعيين',
                                style: GoogleFonts.cairo(),
                              ),
                            ),
                          );
                          if (ok) _load();
                        },
                        child: Text('تعيين',
                            style: GoogleFonts.cairo(fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}