import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({super.key});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();

  List<Map<String, dynamic>> _products = [];
  Map<String, Map<String, TextEditingController>> _controllers = {};
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);

      final branchId = authController.currentBranchId.value;

      final productsResponse = await supabase
          .from('products')
          .select('id, name, unit, default_price, price')
          .eq('is_active', true)
          .order('name');

      final inventoryResponse = await supabase
          .from('branch_inventory')
          .select('product_id, actual_stock')
          .eq('branch_id', branchId);

      final stockMap = <String, double>{};
      for (final item in inventoryResponse) {
        stockMap[item['product_id'].toString()] =
            (item['actual_stock'] ?? 0).toDouble();
      }

      for (final p in productsResponse) {
        final pid = p['id'].toString();
        _controllers[pid] = {
          'quantity': TextEditingController(),
          'cost': TextEditingController(text: (p['default_price'] ?? p['price'] ?? '').toString()),
        };
      }

      setState(() {
        _products = List<Map<String, dynamic>>.from(productsResponse).map((p) {
          return {
            ...p,
            'current_stock': stockMap[p['id'].toString()] ?? 0.0,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('خطأ', 'فشل تحميل المنتجات: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) =>
        (p['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  int get _selectedCount {
    int count = 0;
    for (final p in _products) {
      final pid = p['id'].toString();
      final qty = _controllers[pid]?['quantity']?.text ?? '';
      if (qty.isNotEmpty && (double.tryParse(qty) ?? 0) > 0) count++;
    }
    return count;
  }

  double get _totalCost {
    double total = 0;
    for (final p in _products) {
      final pid = p['id'].toString();
      final qty = double.tryParse(_controllers[pid]?['quantity']?.text ?? '') ?? 0;
      final cost = double.tryParse(_controllers[pid]?['cost']?.text ?? '') ?? 0;
      if (qty > 0) total += qty * cost;
    }
    return total;
  }

  Future<void> _saveAll() async {
    if (_selectedCount == 0) {
      Get.snackbar('تنبيه', 'يرجى إدخال كمية لمنتج واحد على الأقل');
      return;
    }

    try {
      setState(() => _isSaving = true);
      final branchId = authController.currentBranchId.value;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      int savedCount = 0;

      for (final p in _products) {
        final pid = p['id'].toString();
        final qty = double.tryParse(_controllers[pid]?['quantity']?.text ?? '') ?? 0;
        if (qty <= 0) continue;

        final cost = double.tryParse(_controllers[pid]?['cost']?.text ?? '') ?? 0;
        final currentStock = (p['current_stock'] as double?) ?? 0;
        final newStock = currentStock + qty;

        await supabase.from('branch_inventory').upsert({
          'branch_id': branchId,
          'product_id': pid,
          'actual_stock': newStock,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'branch_id,product_id');

        await supabase.from('stock_entries').insert({
          'branch_id': branchId,
          'product_id': pid,
          'quantity': qty,
          'unit_cost': cost,
          'total_cost': qty * cost,
          'entered_by': userId,
        });

        _controllers[pid]?['quantity']?.clear();
        p['current_stock'] = newStock;
        savedCount++;
      }

      Get.snackbar('تم', 'تم إدخال المخزون لـ $savedCount منتج بنجاح',
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حفظ إدخال المخزون: $e',
        backgroundColor: AppTheme.error,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (final controllers in _controllers.values) {
      for (final c in controllers.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProductGrid(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(LucideIcons.box, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إدخال المخزون', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker)),
            Obx(() => Text('إضافة كمية جديدة لفرع: ${authController.currentBranchName.value}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: '🔍 بحث عن منتج...',
        prefixIcon: const Icon(LucideIcons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final filtered = _filteredProducts;
    if (filtered.isEmpty) {
      return const Center(child: Text('لا توجد منتجات', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildProductCard(filtered[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final pid = product['id'].toString();
    final currentStock = (product['current_stock'] as double?) ?? 0;
    final unit = product['unit'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${product['name']} $unit',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDarker),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentStock.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('المخزون الحالي', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          const Spacer(),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildCompactField(
                  controller: _controllers[pid]?['quantity'],
                  hint: '+ كمية',
                  icon: LucideIcons.hash,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _buildCompactField(
                  controller: _controllers[pid]?['cost'],
                  hint: 'التكلفة',
                  icon: LucideIcons.banknote,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactField({
    required TextEditingController? controller,
    required String hint,
    required IconData icon,
  }) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 10, color: Colors.grey[400]),
          prefixIcon: Icon(icon, size: 12),
          prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 0),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLighter,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'المنتجات المحددة: $_selectedCount',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'الإجمالي: ${_totalCost.toStringAsFixed(0)} د.ع',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryDarker),
          ),
          const Spacer(),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAll,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Icon(LucideIcons.save, color: Colors.white, size: 18),
              label: Text(
                _isSaving ? 'جاري الحفظ...' : 'حفظ الكل',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
