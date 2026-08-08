import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/ops_api.dart';
import '../../services/auth_service.dart';
import 'employee_details_screen.dart';

class EmployeesScreen extends StatefulWidget {
  final AuthState auth;
  const EmployeesScreen({super.key, required this.auth});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<DeliveryEmployeeModel>? _employees;
  List<DeliveryEmployeeModel>? _pending;
  List<Map<String, dynamic>>? _branches;
  bool _loadingTeam = true;
  bool _loadingPending = true;
  String? _error;
  String _query = '';
  String? _branchFilter;

  /// منع التكرار: أثناء تنفيذ إجراء على مندوب لا يقبل أي ضغطة أخرى
  final Set<String> _busyKeys = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadTeam();
    _loadPending();
    _loadBranches();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final b = await OpsApi.fetchBranches();
      if (mounted) setState(() => _branches = b);
    } catch (_) {}
  }

  Future<void> _loadTeam() async {
    setState(() {
      _loadingTeam = true;
      _error = null;
    });
    try {
      final employees = await OpsApi.fetchEmployees(branchId: _branchFilter);
      if (!mounted) return;
      setState(() {
        _employees = employees;
        _loadingTeam = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is OpsApiException ? e.message : 'تعذر تحميل المندوبين';
        _loadingTeam = false;
      });
    }
  }

  Future<void> _loadPending() async {
    setState(() => _loadingPending = true);
    try {
      final pending = await OpsApi.fetchPendingDrivers();
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _loadingPending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _loadingPending = false;
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadTeam(), _loadPending(), _loadBranches()]);
  }

  String _busyKey(String action, String id) => '$action:$id';

  bool _isBusy(String key) {
    if (key.isEmpty) return false;
    return _busyKeys.contains(key);
  }

  void _startBusy(String key, String? agentId) {
    setState(() => _busyKeys.add('$key${agentId ?? ''}'));
  }

  void _endBusy(String key, String? agentId) {
    if (!mounted) return;
    setState(() => _busyKeys.remove('$key${agentId ?? ''}'));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFFdc2626),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  // ── الإجراءات ──────────────────────────────────────────────

  Future<void> _approveDriver(DeliveryEmployeeModel d) async {
    if (d.userId == null) return;
    final key = _busyKey('approve', d.userId!);
    _startBusy(key, null);
    try {
      await OpsApi.approveDriver(profileId: d.userId!);
      _showSuccess('تم اعتماد المندوب ${d.fullName} بنجاح');
      await _refresh();
    } catch (e) {
      _showError(e is OpsApiException ? e.message : 'فشلت الموافقة');
    } finally {
      _endBusy(key, null);
    }
  }

  Future<void> _rejectDriver(DeliveryEmployeeModel d) async {
    if (d.userId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الرفض', style: GoogleFonts.cairo(fontSize: 16)),
        content: Text(
          'هل أنت متأكد من رفض طلب انضمام ${d.fullName}؟ لا يمكن التراجع عن هذه العملية.',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFdc2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final key = _busyKey('reject', d.userId!);
    _busyKeys.add(key);
    setState(() {});
    try {
      await OpsApi.rejectDriver(profileId: d.userId!);
      _showSuccess('تم رفض طلب ${d.fullName}');
      await _refresh();
    } catch (e) {
      _showError(e is OpsApiException ? e.message : 'فشل الرفض');
    } finally {
      _busyKeys.remove(key);
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleActive(DeliveryEmployeeModel e) async {
    final key = _busyKey('active', e.id);
    _busyKeys.add(key);
    setState(() {});
    try {
      await OpsApi.setDriverActive(employeeId: e.id, active: !e.isActive);
      _showSuccess(e.isActive ? 'تم إيقاف ${e.fullName}' : 'تم تفعيل ${e.fullName}');
      await _refresh();
    } catch (ex) {
      _showError(ex is OpsApiException ? ex.message : 'فشلت العملية');
    } finally {
      _busyKeys.remove(key);
      if (mounted) setState(() {});
    }
  }

  Future<void> _transfer(DeliveryEmployeeModel e) async {
    if (_branches == null || _branches!.isEmpty) {
      _showError('لا توجد فروع متاحة');
      return;
    }
    String? selected;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final other = _branches!
            .where((b) => b['id'].toString() != e.branchId)
            .toList();
        if (other.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('المندوب بالفعل في الفرع الوحيد المتاح',
                  style: GoogleFonts.cairo()),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نقل ${e.fullName}', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selected,
                decoration: InputDecoration(
                  labelText: 'الفرع الجديد',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                items: other
                    .map((b) => DropdownMenuItem(
                          value: b['id'].toString(),
                          child: Text(b['name']?.toString() ?? '',
                              style: GoogleFonts.cairo(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selected = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                  ),
                  onPressed: selected == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final key = _busyKey('transfer', e.id);
                          _busyKeys.add(key);
                          setState(() {});
                          try {
                            await OpsApi.transferEmployee(
                              employeeId: e.id,
                              newBranchId: selected!,
                              reason: 'نقل من تطبيق العمليات',
                            );
                            _showSuccess('تم نقل ${e.fullName} إلى الفرع الجديد');
                            await _refresh();
                          } catch (ex) {
                            _showError(
                                ex is OpsApiException ? ex.message : 'فشل النقل');
                          } finally {
                            _busyKeys.remove(key);
                            if (mounted) setState(() {});
                          }
                        },
                  child: Text('نقل', style: GoogleFonts.cairo(fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetails(DeliveryEmployeeModel e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeDetailsScreen(employee: e)),
    ).then((_) => _loadTeam());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المندوبون', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'الفريق (${_employees?.length ?? '-'})'),
            Tab(text: 'بنك الانتظار${(_pending?.length ?? 0) > 0 ? ' (${_pending!.length})' : ''}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildTeam(), _buildApprovals()],
      ),
    );
  }

  // ── الفريق ────────────────────────────────────────────────
  Widget _buildTeam() {
    if (_loadingTeam) return const Center(child: CircularProgressIndicator());
    if (_error != null && _employees == null) {
      return _errorState(_error!, onRetry: _loadTeam);
    }

    final employees = _employees ?? [];
    final filtered = employees.where((e) {
      if (_branchFilter != null && e.branchId != _branchFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.trim();
      return e.fullName.toLowerCase().contains(q.toLowerCase()) ||
          e.phone.contains(q) ||
          e.branchName.contains(q);
    }).toList();

    final branches = _branches ?? const [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الهاتف أو الفرع',
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
              const SizedBox(height: 8),
              if (branches.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _filterChip('الكل', _branchFilter == null, () {
                        setState(() => _branchFilter = null);
                        _loadTeam();
                      }),
                      ...branches.map((b) {
                        final id = b['id'].toString();
                        final name = b['name']?.toString() ?? '';
                        return _filterChip(name, _branchFilter == id, () {
                          setState(() => _branchFilter = id);
                          _loadTeam();
                        });
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, size: 44, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text('لا يوجد مناديب مطابقون',
                                style: GoogleFonts.cairo(color: Colors.grey)),
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

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10b981) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF10b981) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'online':
        return const Color(0xFF10b981);
      case 'offline':
        return const Color(0xFF94a3b8);
      default:
        return const Color(0xFF94a3b8);
    }
  }

  Widget _employeeCard(DeliveryEmployeeModel e) {
    final busyActive = _isBusy(_busyKey('active', e.id));
    final busyTransfer = _isBusy(_busyKey('transfer', e.id));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: e.isOnline ? const Color(0xFF10b981).withOpacity(0.3) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openDetails(e),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF10b981).withOpacity(0.12),
                      child: Text(
                        e.fullName.isEmpty ? '؟' : e.fullName.substring(0, 1),
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: e.isOnline ? const Color(0xFF10b981) : const Color(0xFF94a3b8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(e.fullName.isEmpty ? '—' : e.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          _accountBadge(e),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(e.phone.isEmpty ? 'بدون هاتف' : e.phone,
                              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          const SizedBox(width: 10),
                          Icon(Icons.store_outlined, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(e.branchName.isEmpty ? 'بدون فرع' : e.branchName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(e.onlineStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e.isOnline ? 'متصل' : 'غير متصل',
                              style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: _statusColor(e.onlineStatus),
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.delivery_dining, size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(e.vehicleLabel,
                              style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // إحصائيات سريعة
          Row(
            children: [
              _miniStat('اليوم', '${e.todayDeliveries} توصيل', const Color(0xFF10b981)),
              const SizedBox(width: 8),
              _miniStat('أرباح اليوم', NumberFormat('#,##0').format(e.todayEarnings), const Color(0xFF0ea5e9)),
              const SizedBox(width: 8),
              _miniStat('الإجمالي', '${e.totalDeliveries} توصيل', const Color(0xFF8b5cf6)),
              const SizedBox(width: 8),
              _miniStat('المحفظة', NumberFormat('#,##0').format(e.walletBalance), const Color(0xFFf59e0b)),
            ],
          ),
          const SizedBox(height: 12),
          // الأزرار
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0ea5e9),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _openDetails(e),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: Text('تفاصيل', style: GoogleFonts.cairo(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8b5cf6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: busyTransfer ? null : () => _transfer(e),
                  icon: busyTransfer
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.swap_horiz, size: 16),
                  label: Text('نقل', style: GoogleFonts.cairo(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: e.isActive ? const Color(0xFFef4444) : const Color(0xFF10b981),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: busyActive ? null : () => _toggleActive(e),
                  icon: busyActive
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(e.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16),
                  label: Text(e.isActive ? 'إيقاف' : 'تفعيل', style: GoogleFonts.cairo(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.cairo(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _accountBadge(DeliveryEmployeeModel e) {
    final (label, color) = switch (e.accountStatusLabel) {
      'نشط' => ('نشط', const Color(0xFF10b981)),
      'موقوف' => ('موقوف', const Color(0xFFef4444)),
      _ => ('قيد المراجعة', const Color(0xFFf59e0b)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: GoogleFonts.cairo(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
    );
  }

  // ── بنك الانتظار ──────────────────────────────────────────
  Widget _buildApprovals() {
    if (_loadingPending) return const Center(child: CircularProgressIndicator());
    final pending = _pending ?? [];
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_reg, size: 44, color: Colors.grey),
            const SizedBox(height: 10),
            Text('لا توجد طلبات انضمام بانتظار المراجعة', style: GoogleFonts.cairo(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPending,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pending.length,
        itemBuilder: (context, i) {
          final d = pending[i];
          final busyApprove = _isBusy(_busyKey('approve', d.userId ?? ''));
          final busyReject = _isBusy(_busyKey('reject', d.userId ?? ''));
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFf59e0b).withOpacity(0.1),
                      child: Text(
                        d.fullName.isEmpty ? '؟' : d.fullName.substring(0, 1),
                        style: GoogleFonts.cairo(color: const Color(0xFFf59e0b), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.fullName.isEmpty ? '—' : d.fullName,
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(d.phone.isEmpty ? '' : d.phone,
                              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          if (d.vehicleType.isNotEmpty)
                            Text(d.vehicleLabel,
                                style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf59e0b).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('بانتظار المراجعة',
                          style: GoogleFonts.cairo(fontSize: 10, color: const Color(0xFFf59e0b), fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: busyApprove || busyReject ? null : () => _approveDriver(d),
                        icon: busyApprove
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(busyApprove ? 'جاري الاعتماد...' : 'اعتماد',
                            style: GoogleFonts.cairo(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFef4444),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: busyApprove || busyReject ? null : () => _rejectDriver(d),
                        icon: busyReject
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFef4444)))
                            : const Icon(Icons.close, size: 16),
                        label: Text(busyReject ? 'جاري الرفض...' : 'رفض',
                            style: GoogleFonts.cairo(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _errorState(String errorMessage, {required Future<void> Function() onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(errorMessage, style: GoogleFonts.cairo(fontSize: 14)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => onRetry(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}