import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../services/ops_api.dart';
import '../../services/auth_service.dart';

class EmployeesScreen extends StatefulWidget {
  final AuthState auth;
  const EmployeesScreen({super.key, required this.auth});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<EmployeeView>? _employees;
  bool _loading = true;
  String? _error;
  String _query = '';
  List<Map<String, dynamic>>? _pendingDrivers;
  List<Map<String, dynamic>>? _branches;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final employeesFuture = OpsApi.fetchEmployees();
      final approvalsFuture = _supabase
          .from('profiles')
          .select('id,full_name,phone,vehicle_type,is_approved,is_active')
          .eq('role', 'driver');
      final branchesFuture = _fetchBranches();

      final employees = await employeesFuture;
      final pendingData = await approvalsFuture;
      final branches = await branchesFuture;

      final pending = <Map<String, dynamic>>[];
      if (pendingData.isNotEmpty) {
        for (final m in pendingData) {
          pending.add(m);
        }
      }

      if (!mounted) return;
      setState(() {
        _employees = employees.map(EmployeeView.fromRow).toList();
        _pendingDrivers = pending;
        _branches = branches;
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

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _toggleApproval(String id, bool current) async {
    final res = await _supabase
        .from('profiles')
        .update({'is_approved': !current}).eq('id', id);
    if (res.error == null) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المندوبون', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            const Tab(text: 'الفريق'),
            Tab(text: 'بنك الانتظار'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildTeam(),
          _buildApprovals(),
        ],
      ),
    );
  }

  Widget _buildTeam() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('يمكنك محاولة الاتصال مرة أخرى'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    final employees = _employees ?? [];
    final filtered = _query.isEmpty
        ? employees
        : employees
            .where((e) =>
                (e.name?.contains(_query) ?? false) ||
                (e.branchName?.contains(_query) ?? false))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الفرع',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, size: 44, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text('لا يوجد مناديب', style: GoogleFonts.cairo(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _employeeCard(filtered[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _employeeCard(EmployeeView e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: e.isOnline
              ? const Color(0xFF10b981).withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF10b981).withOpacity(0.1),
                    child: Text(
                      (e.name?.isNotEmpty ?? false)
                          ? e.name!.substring(0, 1)
                          : '?',
                      style: GoogleFonts.cairo(
                          color: const Color(0xFF10b981),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (e.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name ?? '—',
                        style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(
                      '${e.branchName ?? ''}${e.vehicleType != null ? ' - ${e.vehicleType}' : ''}',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${e.totalDeliveries} توصيل',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0ea5e9))),
                  Text(
                    NumberFormat('#,##0').format(e.walletBalance),
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: const Color(0xFF10b981)),
                  ),
                ],
              ),
            ],
          ),
          if (widget.auth.isSuper) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8b5cf6),
                    ),
                    onPressed: () => _showTransferSheet(e),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: Text('نقل',
                        style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: e.isActive
                          ? const Color(0xFFef4444)
                          : const Color(0xFF10b981),
                    ),
                    onPressed: () => _toggleActive(e),
                    icon: Icon(
                        e.isActive ? Icons.block : Icons.check_circle_outline,
                        size: 16),
                    label: Text(
                        e.isActive ? 'إيقاف' : 'تفعيل',
                        style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleActive(EmployeeView e) async {
    if (e.userId == null) return;
    final res = await _supabase
        .from('delivery_employees')
        .update({'is_active': !e.isActive}).eq('id', e.id);
    if (res.error == null) {
      if (mounted) _load();
    }
  }

  void _showTransferSheet(EmployeeView e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? selectedBranch;
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
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
                Text('نقل ${e.name ?? 'المندوب'}',
                    style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_branches != null && _branches!.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedBranch,
                    decoration: InputDecoration(
                      labelText: 'الفرع الجديد',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    items: _branches!
                        .where((b) => b['id'].toString() != e.branchId)
                        .map((b) => DropdownMenuItem(
                              value: b['id'].toString(),
                              child: Text(b['name']?.toString() ?? '',
                                  style: GoogleFonts.cairo(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedBranch = v),
                  )
                else
                  const Text('لا توجد فروع'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                    ),
                    onPressed: selectedBranch == null
                        ? null
                        : () async {
                            Navigator.pop(context);
                            final ok = await OpsApi.transferEmployee(
                              employeeId: e.id,
                              newBranchId: selectedBranch!,
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    ok ? 'تم نقل المندوب' : 'فشل النقل',
                                    style: GoogleFonts.cairo()),
                              ),
                            );
                            if (ok) _load();
                          },
                    child: Text('نقل',
                        style: GoogleFonts.cairo(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApprovals() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final pending = _pendingDrivers ?? [];
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_reg, size: 44, color: Colors.grey),
            const SizedBox(height: 10),
            Text('لا توجد طلبات انضمام بانتظار المراجعة',
                style: GoogleFonts.cairo(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pending.length,
      itemBuilder: (context, i) {
        final d = pending[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFf59e0b).withOpacity(0.1),
                    child: Text(
                      d['full_name']?.toString().isNotEmpty == true
                          ? d['full_name'].toString().substring(0, 1)
                          : '?',
                      style: GoogleFonts.cairo(
                          color: const Color(0xFFf59e0b),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['full_name']?.toString() ?? '—',
                            style: GoogleFonts.cairo(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(d['phone']?.toString() ?? '',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                      ),
                      onPressed: () => _toggleApproval(d['id'].toString(), false),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text('اعتماد',
                          style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFef4444),
                      ),
                      onPressed: () => _rejectDriver(d['id'].toString()),
                      icon: const Icon(Icons.close, size: 16),
                      label: Text('رفض',
                          style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rejectDriver(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الرفض', style: GoogleFonts.cairo(fontSize: 16)),
        content: Text('هل أنت متأكد من رفض طلب الانضمام؟',
            style: GoogleFonts.cairo(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await _supabase.from('profiles').update({
      'is_approved': false,
      'is_active': false,
    }).eq('id', id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.error == null ? 'تم رفض الطلب' : 'فشلت العملية',
              style: GoogleFonts.cairo()),
        ),
      );
      _load();
    }
  }
}

class EmployeeView {
  final String id;
  final String? userId;
  final String? name;
  final String? phone;
  final String? vehicleType;
  final String? branchId;
  final String? branchName;
  final bool isOnline;
  final bool isActive;
  final int totalDeliveries;
  final double walletBalance;

  EmployeeView({
    required this.id,
    this.userId,
    this.name,
    this.phone,
    this.vehicleType,
    this.branchId,
    this.branchName,
    this.isOnline = false,
    this.isActive = true,
    this.totalDeliveries = 0,
    this.walletBalance = 0,
  });

  factory EmployeeView.fromRow(EmployeeRow r) => EmployeeView(
        id: r.id,
        userId: r.userId,
        name: r.name,
        phone: r.phone,
        vehicleType: r.vehicleType,
        branchId: r.branchId,
        branchName: r.branchName,
        isOnline: r.isOnline,
        isActive: r.isActive,
        totalDeliveries: r.totalDeliveries,
        walletBalance: r.walletBalance,
      );
}