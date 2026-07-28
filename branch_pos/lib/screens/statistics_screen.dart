import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import 'finance/settlement_screen.dart';

/// Optimized Statistics screen with RPC-based aggregations,
/// skeleton loading, lazy loading, and server-side computation.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _topProducts = [];
  String _selectedPeriod = 'today';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final periods = ['today', 'week', 'month'];
        setState(() => _selectedPeriod = periods[_tabController.index]);
        _fetchStats();
      }
    });
    _fetchStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final branchId = authController.currentBranchId.value;

      // Use RPC for server-side aggregation
      final statsResult = await supabase.rpc('get_branch_statistics', params: {
        'p_branch_id': branchId,
        'p_period': _selectedPeriod,
      });

      final topResult = await supabase.rpc('get_top_products', params: {
        'p_branch_id': branchId,
        'p_limit': 10,
      });

      setState(() {
        _stats = statsResult is Map<String, dynamic>
            ? statsResult
            : {};
        _topProducts = topResult is List ? topResult : [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('RPC fetch failed, using fallback: $e');
      await _fetchFallback();
    }
  }

  Future<void> _fetchFallback() async {
    try {
      final branchId = authController.currentBranchId.value;
      final now = DateTime.now();
      DateTime start;

      switch (_selectedPeriod) {
        case 'week':
          start = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'month':
          start = DateTime(now.year, now.month, 1);
          break;
        default:
          start = DateTime(now.year, now.month, now.day);
      }

      final startStr = start.toIso8601String();

      final salesResponse = await supabase
          .from('orders')
          .select('total_amount')
          .eq('branch_id', branchId)
          .eq('status', 'delivered')
          .gte('created_at', startStr);

      double totalSales = 0;
      for (final row in salesResponse) {
        totalSales += (row['total_amount'] as num?)?.toDouble() ?? 0;
      }

      final purchasesResponse = await supabase
          .from('purchases')
          .select('total_amount')
          .eq('branch_id', branchId)
          .gte('created_at', startStr);

      double totalPurchases = 0;
      for (final row in purchasesResponse) {
        totalPurchases += (row['total_amount'] as num?)?.toDouble() ?? 0;
      }

      setState(() {
        _stats = {
          'total_sales': totalSales,
          'orders_count': salesResponse.length,
          'avg_order_value': salesResponse.isNotEmpty
              ? totalSales / salesResponse.length
              : 0,
          'total_purchases': totalPurchases,
          'total_stock_value': 0,
        };
        _topProducts = [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fallback error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildPeriodTabs(),
            const SizedBox(height: 28),
            Expanded(
              child: _isLoading
                  ? _buildSkeletonLoader()
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(LucideIcons.barChart3, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الإحصائيات',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker),
              ),
              Text(
                'تحليلات أداء ${authController.currentBranchName.value}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.refreshCw, size: 18, color: AppTheme.primary),
              ),
              onPressed: _fetchStats,
              tooltip: 'تحديث',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.lock, size: 18, color: AppTheme.warning),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const SettlementScreen(),
              )),
              tooltip: 'تسوية مالية',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'اليوم'),
          Tab(text: 'الأسبوع'),
          Tab(text: 'الشهر'),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      children: [
        // Stats cards skeleton
        SizedBox(
          height: 140,
          child: Row(
            children: List.generate(3, (_) => Expanded(
              child: _skeletonCard(),
            )).expand((w) => [w, const SizedBox(width: 16)]).toList()
              ..removeLast(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 100,
          child: Row(
            children: List.generate(2, (_) => Expanded(
              child: _skeletonCard(),
            )).expand((w) => [w, const SizedBox(width: 16)]).toList()
              ..removeLast(),
          ),
        ),
        const SizedBox(height: 24),
        _skeletonCard(),
      ],
    );
  }

  Widget _skeletonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: 80, height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        children: [
          // Stats cards row 1
          Row(
            children: [
              Expanded(child: _statCard(
                'إجمالي المبيعات',
                '${_fmt(_stats['total_sales'])} د.ع',
                LucideIcons.trendingUp,
                AppTheme.primary,
              )),
              const SizedBox(width: 16),
              Expanded(child: _statCard(
                'عدد الطلبات',
                '${_stats['orders_count'] ?? 0}',
                LucideIcons.shoppingBag,
                AppTheme.info,
              )),
              const SizedBox(width: 16),
              Expanded(child: _statCard(
                'متوسط الطلب',
                '${_fmt(_stats['avg_order_value'])} د.ع',
                LucideIcons.receipt,
                AppTheme.accent,
              )),
            ],
          ),
          const SizedBox(height: 16),
          // Stats cards row 2
          Row(
            children: [
              Expanded(child: _statCard(
                'إجمالي المشتريات',
                '${_fmt(_stats['total_purchases'])} د.ع',
                LucideIcons.truck,
                AppTheme.warning,
              )),
              const SizedBox(width: 16),
              Expanded(child: _statCard(
                'قيمة المخزون',
                '${_fmt(_stats['total_stock_value'])} د.ع',
                LucideIcons.package,
                AppTheme.secondary,
              )),
            ],
          ),
          const SizedBox(height: 24),

          // Top Products
          if (_topProducts.isNotEmpty) ...[
            const Text(
              'أكثر المنتجات مبيعاً',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDarker),
            ),
            const SizedBox(height: 12),
            ...(_topProducts).map((p) => _buildProductRow(p as Map<String, dynamic>)),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildProductRow(dynamic product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryLighter,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${product['total_quantity'] ?? 0}',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Text(
            '${_fmt(product['total_revenue'])} د.ع',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDarker),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toDouble() : 0.0;
    return n.toStringAsFixed(0);
  }
}
