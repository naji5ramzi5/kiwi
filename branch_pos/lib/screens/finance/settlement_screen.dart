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
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

      // Fetch sales
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

      // Fetch purchases
      final purchasesResponse = await supabase
          .from('purchases')
          .select('total_value')
          .eq('branch_id', authController.currentBranchId.value)
          .gte('created_at', startOfDay);
      
      double purchases = 0;
      for (var row in purchasesResponse) {
        purchases += (row['total_value'] as num).toDouble();
      }

      setState(() {
        stats = {
          'total_sales': sales,
          'total_purchases': purchases,
          'total_damaged': 0.0, // Logic for damaged goods can be added here
          'orders_count': salesResponse.length,
        };
      });
    } catch (e) {
      print('Error fetching stats: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> closeRegister() async {
    try {
      await supabase.from('daily_settlements').insert({
        'branch_id': authController.currentBranchId.value,
        'total_sales': stats['total_sales'],
        'total_purchases': stats['total_purchases'],
        'total_damaged': stats['total_damaged'],
        'cash_on_hand': stats['total_sales'], // In a real app, this would be an input field
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
      Get.snackbar('خطأ', 'فشل في إغلاق الصندوق: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('التسوية المالية (إغلاق الصندوق)')),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ملخص مبيعات اليوم', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('بتاريخ ${DateFormat('dd MMMM yyyy').format(DateTime.now())}', style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                    _buildActionButton('تحديث البيانات', LucideIcons.refreshCcw, AppTheme.secondary, fetchDailyStats),
                  ],
                ),
                const SizedBox(height: 40),
                
                Row(
                  children: [
                    _buildStatCard('إجمالي المبيعات', '${stats['total_sales']} د.ع', LucideIcons.trendingUp, AppTheme.primary),
                    const SizedBox(width: 20),
                    _buildStatCard('إجمالي المشتريات', '${stats['total_purchases']} د.ع', LucideIcons.shoppingCart, AppTheme.accent),
                    const SizedBox(width: 20),
                    _buildStatCard('عدد الطلبات المكتملة', '${stats['orders_count']}', LucideIcons.packageCheck, Colors.blue),
                  ],
                ),
                
                const Spacer(),
                
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'هل أنت متأكد من رغبتك في إغلاق الصندوق لهذا اليوم؟',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'بعد الإغلاق، سيتم ترحيل كافة المبيعات والمشتريات للحساب الختامي ولا يمكن التعديل عليها.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 400,
                        child: ElevatedButton(
                          onPressed: closeRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('إغلاق الصندوق وترحيل البيانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
