import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();
  bool isLoading = true;
  Map<String, dynamic> stats = {
    'total_sales': 0.0,
    'total_purchases': 0.0,
    'total_damaged': 0.0,
    'orders_count': 0,
  };

  @override
  void initState() {
    super.initState();
    fetchDailyStats();
  }

  Future<void> fetchDailyStats() async {
    setState(() => isLoading = true);
    try {
      final branchId = authController.currentBranchId.value;

      final rpcData = await supabase.rpc('get_branch_daily_stats', params: {
        'p_branch_id': branchId,
      });

      setState(() {
        stats = {
          'total_sales': (rpcData?['total_sales'] as num?)?.toDouble() ?? 0.0,
          'total_purchases': (rpcData?['total_purchases'] as num?)?.toDouble() ?? 0.0,
          'total_damaged': (rpcData?['total_damaged'] as num?)?.toDouble() ?? 0.0,
          'orders_count': rpcData?['orders_count'] ?? 0,
        };
      });
    } catch (e) {
      debugPrint('Error fetching stats via RPC: $e');
      await _fetchDailyStatsFallback();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchDailyStatsFallback() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

      final salesResponse = await supabase
          .from('orders')
          .select('total_amount')
          .eq('branch_id', authController.currentBranchId.value)
          .eq('status', 'delivered')
          .gte('created_at', startOfDay);

      double sales = 0;
      for (var row in salesResponse) {
        sales += (row['total_amount'] as num).toDouble();
      }

      final purchasesResponse = await supabase
          .from('purchases')
          .select('total_amount')
          .eq('branch_id', authController.currentBranchId.value)
          .gte('created_at', startOfDay);

      double purchases = 0;
      for (var row in purchasesResponse) {
        purchases += (row['total_amount'] as num).toDouble();
      }

      setState(() {
        stats = {
          'total_sales': sales,
          'total_purchases': purchases,
          'total_damaged': 0.0,
          'orders_count': salesResponse.length,
        };
      });
    } catch (e) {
      debugPrint('Error fetching stats fallback: $e');
    }
  }

  Future<void> closeRegister() async {
    try {
      await supabase.from('daily_settlements').insert({
        'branch_id': authController.currentBranchId.value,
        'total_sales': stats['total_sales'],
        'total_purchases': stats['total_purchases'],
        'total_damaged': stats['total_damaged'],
        'cash_on_hand': stats['total_sales'],
        'status': 'closed',
        'closed_at': DateTime.now().toIso8601String(),
      });

      Get.defaultDialog(
        title: 'تم إغلاق الصندوق',
        middleText: 'تم ترحيل البيانات المالية لليوم بنجاح إلى الإدارة المركزية.',
        onConfirm: () => Navigator.pop(context),
        textConfirm: 'موافق',
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إغلاق الصندوق: $e',
        backgroundColor: AppTheme.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.barChart3, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('التسوية المالية', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker)),
                            Text('بتاريخ ${DateFormat('dd MMMM yyyy').format(DateTime.now())}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLighter,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: fetchDailyStats,
                        icon: const Icon(LucideIcons.refreshCcw, size: 20, color: AppTheme.primary),
                        tooltip: 'تحديث البيانات',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Stats cards
                Row(
                  children: [
                    _buildStatCard('إجمالي المبيعات', '${stats['total_sales']} د.ع', LucideIcons.trendingUp, AppTheme.primary),
                    const SizedBox(width: 20),
                    _buildStatCard('إجمالي المشتريات', '${stats['total_purchases']} د.ع', LucideIcons.shoppingCart, AppTheme.accent),
                    const SizedBox(width: 20),
                    _buildStatCard('الطلبات المكتملة', '${stats['orders_count']}', LucideIcons.packageCheck, AppTheme.info),
                  ],
                ),

                const Spacer(),

                // Close register section
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: AppTheme.primary.withOpacity(0.15), width: 2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(LucideIcons.lock, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'هل أنت متأكد من رغبتك في إغلاق الصندوق لهذا اليوم؟',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDarker),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'بعد الإغلاق، سيتم ترحيل كافة المبيعات والمشتريات للحساب الختامي ولا يمكن التعديل عليها.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: 400,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.buttonShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: closeRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.lock, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('إغلاق الصندوق وترحيل البيانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}
