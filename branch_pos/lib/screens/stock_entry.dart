import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;
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
      final response = await supabase
          .from('products')
          .select('id, name, unit, default_price, price')
          .eq('is_active', true)
          .order('name');

      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('خطأ', 'فشل تحميل المنتجات: $e');
    }
  }

  Future<void> _saveStockEntry() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) return;

    final branchId = authController.currentBranchId.value;
    final productId = _selectedProduct!['id'].toString();
    final quantity = double.parse(_quantityController.text);
    final unitCost = double.tryParse(_costController.text) ?? 0;

    try {
      setState(() => _isSaving = true);

      // 1. Get current stock
      final currentStockData = await supabase
          .from('inventory')
          .select('stock_quantity')
          .eq('branch_id', branchId)
          .eq('product_id', productId)
          .maybeSingle();

      final currentStock = (currentStockData?['stock_quantity'] ?? 0).toDouble();
      final newStock = currentStock + quantity;

      // 2. Upsert inventory (increase stock)
      await supabase.from('inventory').upsert({
        'branch_id': branchId,
        'product_id': productId,
        'stock_quantity': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'branch_id,product_id');

      // 3. Record stock entry
      await supabase.from('stock_entries').insert({
        'branch_id': branchId,
        'product_id': productId,
        'quantity': quantity,
        'unit_cost': unitCost,
        'total_cost': quantity * unitCost,
        'entered_by': Supabase.instance.client.auth.currentUser?.id,
      });

      Get.snackbar('تم', 'تم إدخال المخزون بنجاح، الكمية الجديدة: ${newStock.toStringAsFixed(0)}');
      _formKey.currentState!.reset();
      setState(() => _selectedProduct = null);
      _quantityController.clear();
      _costController.clear();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حفظ إدخال المخزون: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'إدخال المخزون',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                          'إضافة كمية جديدة لفرع: ${authController.currentBranchName.value}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        )),
                    const SizedBox(height: 32),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'اختر المنتج',
                        border: OutlineInputBorder(),
                      ),
                      items: _products.map((product) {
                        final unit = product['unit'] ?? '';
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: product,
                          child: Text('${product['name']} $unit'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProduct = value;
                          _costController.text = (value?['default_price'] ?? value?['price'] ?? '').toString();
                        });
                      },
                      validator: (value) => value == null ? 'يرجى اختيار منتج' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final quantity = double.tryParse(value ?? '');
                        if (quantity == null || quantity <= 0) return 'يرجى إدخال كمية صحيحة';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: 'تكلفة الوحدة',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (double.tryParse(value) == null) return 'يرجى إدخال رقم صحيح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveStockEntry,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ المخزون'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
