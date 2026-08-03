import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class DeliveryEmployeesScreen extends StatefulWidget {
  const DeliveryEmployeesScreen({super.key});

  @override
  State<DeliveryEmployeesScreen> createState() => _DeliveryEmployeesScreenState();
}

class _DeliveryEmployeesScreenState extends State<DeliveryEmployeesScreen> {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();
  List<Map<String, dynamic>> employees = [];
  bool isLoading = true;
  RealtimeChannel? _employeeChannel;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
    _subscribeToEmployees();
  }

  @override
  void dispose() {
    if (_employeeChannel != null) {
      supabase.removeChannel(_employeeChannel!);
    }
    super.dispose();
  }

  Future<void> fetchEmployees() async {
    try {
      final branchId = authController.currentBranchId.value;
      final response = await supabase
          .from('delivery_employees_with_profiles')
          .select('*')
          .eq('branch_id', branchId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      setState(() {
        employees = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching delivery employees: $e');
      setState(() => isLoading = false);
    }
  }

  void _subscribeToEmployees() {
    final branchId = authController.currentBranchId.value;
    _employeeChannel = supabase
        .channel('branch-employees-$branchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_employees',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'branch_id',
            value: branchId,
          ),
          callback: (payload) {
            fetchEmployees();
          },
        )
        .subscribe();
  }

  String _joinedDate(dynamic joinedAt) {
    if (joinedAt == null) return '--';
    try {
      final d = DateTime.parse(joinedAt.toString());
      return '${d.month}/${d.day}/${d.year}';
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.truck, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('مناديب التوصيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const Spacer(),
                Obx(() => Text(
                  '${employees.length} مندوب',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                )),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: fetchEmployees,
                    icon: const Icon(LucideIcons.refreshCcw, size: 20, color: AppTheme.primary),
                    tooltip: 'تحديث',
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : employees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.truck, size: 64, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            Text('لا يوجد مناديب في هذا الفرع', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('بعد اعتماد المندوب من الإدارة، سيظهر هنا', style: TextStyle(color: Colors.grey.shade300, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final emp = employees[index];
                          final isOnline = emp['is_online'] ?? false;
                          final fullName = emp['full_name'] ?? 'مندوب';
                          final phone = emp['phone'] ?? '--';
                          final avatarUrl = emp['avatar_url'] as String?;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey.shade100,
                                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                        child: avatarUrl == null
                                            ? const Icon(LucideIcons.user, color: AppTheme.textSecondary, size: 28)
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: isOnline ? const Color(0xFF10b981) : Colors.grey,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isOnline ? const Color(0xFF10b981).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                isOnline ? 'متصل' : 'غير متصل',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isOnline ? const Color(0xFF10b981) : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(LucideIcons.phone, size: 14, color: Colors.grey.shade400),
                                            const SizedBox(width: 6),
                                            Text(phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                            const SizedBox(width: 20),
                                            Icon(LucideIcons.calendar, size: 14, color: Colors.grey.shade400),
                                            const SizedBox(width: 6),
                                            Text('تاريخ الانضمام: ${_joinedDate(emp['joined_at'])}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(LucideIcons.package, size: 14, color: Colors.grey.shade400),
                                            const SizedBox(width: 6),
                                            Text('${emp['total_deliveries'] ?? 0} توصيلة', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                            const SizedBox(width: 20),
                                            Icon(LucideIcons.shield, size: 14, color: Colors.grey.shade400),
                                            const SizedBox(width: 6),
                                            Text('الحساب ${emp['is_active'] == true ? 'نشط' : 'موقف'}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _showEmployeeDetails(context, emp, null);
                                    },
                                    icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, Map<String, dynamic> emp, Map<String, dynamic>? profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile?['full_name'] ?? emp['full_name'] ?? 'تفاصيل المندوب'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('الهاتف', profile?['phone'] ?? emp['phone'] ?? '--'),
              _detailRow('الحالة', emp['status'] == 'online' ? 'متصل' : 'غير متصل'),
              _detailRow('حالة الحساب', emp['is_active'] == true ? 'نشط' : 'موقف'),
              _detailRow('إجمالي التوصيلات', '${emp['total_deliveries'] ?? 0}'),
              _detailRow('تاريخ الانضمام', _joinedDate(emp['joined_at'])),
              if (emp['transferred_at'] != null)
                _detailRow('آخر نقل', _joinedDate(emp['transferred_at'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
