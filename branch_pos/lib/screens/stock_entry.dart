import 'package:flutter/material.dart';
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
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      Get.snackbar('تنبيه', 'يرجى إدخال كمية صحيحة');
      return;
    }
    final unitCost = double.tryParse(_costController.text) ?? 0;

    try {
      setState(() => _isSaving = true);

      final currentStockData = await supabase
          .from('branch_inventory')
          .select('actual_stock')
          .eq('branch_id', branchId)
          .eq('product_id', productId)
          .maybeSingle();

      final currentStock = (currentStockData?['actual_stock'] ?? 0).toDouble();
      final newStock = currentStock + quantity;

      await supabase.from('branch_inventory').upsert({
        'branch_id': branchId,
        'product_id': productId,
        'actual_stock': newStock,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'branch_id,product_id');

      await supabase.from('stock_entries').insert({
        'branch_id': branchId,
        'product_id': productId,
        'quantity': quantity,
        'unit_cost': unitCost,
        'total_cost': quantity * unitCost,
        'entered_by': Supabase.instance.client.auth.currentUser?.id,
      });

      Get.snackbar('تم', 'تم إدخال المخزون بنجاح، الكمية الجديدة: ${newStock.toStringAsFixed(0)}',
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
      _formKey.currentState!.reset();
      setState(() => _selectedProduct = null);
      _quantityController.clear();
      _costController.clear();
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
                    // Header
                    Row(
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
                    ),
                    const SizedBox(height: 40),

                    // Form card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('بيانات الإدخال', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDarker)),
                          const SizedBox(height: 24),

                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedProduct,
                            decoration: const InputDecoration(
                              labelText: 'اختر المنتج',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.package),
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
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'الكمية',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.hash),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              final quantity = double.tryParse(value ?? '');
                              if (quantity == null || quantity <= 0) return 'يرجى إدخال كمية صحيحة';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _costController,
                            decoration: const InputDecoration(
                              labelText: 'تكلفة الوحدة',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.banknote),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (double.tryParse(value) == null) return 'يرجى إدخال رقم صحيح';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppTheme.buttonShadow,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveStockEntry,
                              icon: _isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                  : const Icon(LucideIcons.save, color: Colors.white),
                              label: Text(
                                _isSaving ? 'جاري الحفظ...' : 'حفظ المخزون',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
