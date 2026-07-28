import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/inventory_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final supabase = Supabase.instance.client;
  final InventoryController inventoryController = Get.find<InventoryController>();
  final AuthController authController = Get.find<AuthController>();

  List<Map<String, dynamic>> cart = [];
  final TextEditingController supplierController = TextEditingController();
  double totalValue = 0;
  final TextEditingController barcodeController = TextEditingController();
  bool _isSaving = false;

  void scanBarcode(String barcode) {
    if (barcode.isEmpty) return;
    final product = inventoryController.inventory.firstWhere(
      (p) => p['barcode'] == barcode || p['id'].toString() == barcode,
      orElse: () => <String, dynamic>{},
    );
    if (product.isNotEmpty) {
      addToPurchase(product);
      barcodeController.clear();
    } else {
      Get.snackbar('غير موجود', 'لم يتم العثور على منتج بهذا الباركود');
      barcodeController.clear();
    }
  }

  void updateQuantityDialog(int index) {
    final controller = TextEditingController(text: cart[index]['quantity'].toString());
    Get.defaultDialog(
      title: 'تعديل الكمية لـ ${cart[index]['name']}',
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: 'الكمية المستلمة'),
      ),
      onConfirm: () {
        final qty = double.tryParse(controller.text);
        if (qty != null && qty > 0) {
          setState(() {
            cart[index]['quantity'] = qty;
            calculateTotal();
          });
          Get.back();
        }
      },
      textConfirm: 'حفظ',
      textCancel: 'إلغاء',
    );
  }

  void addToPurchase(Map<String, dynamic> product) {
    setState(() {
      final index = cart.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        cart[index]['quantity'] += 1;
      } else {
        cart.add({
          'id': product['id'],
          'name': product['name'],
          'quantity': 1.0,
          'unit_cost': product['cost'] ?? 0.0,
        });
      }
      calculateTotal();
    });
  }

  void calculateTotal() {
    totalValue = cart.fold(0, (sum, item) => sum + (item['quantity'] * item['unit_cost']));
  }

  Future<void> savePurchase() async {
    if (cart.isEmpty || supplierController.text.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى اختيار منتجات وإدخال اسم المورد');
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final branchId = authController.currentBranchId.value;

      await supabase.from('purchases').insert({
        'branch_id': branchId,
        'supplier_name': supplierController.text,
        'total_amount': totalValue,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      }).select().single().then((purchaseResponse) async {
        final itemsToInsert = cart.map((item) => {
          'purchase_id': purchaseResponse['id'],
          'product_id': item['id'],
          'quantity': item['quantity'],
          'unit_cost': item['unit_cost'],
          'total_cost': item['quantity'] * item['unit_cost'],
        }).toList();

        await supabase.from('purchase_items').insert(itemsToInsert);

        final supabaseService = SupabaseService();
        for (final item in cart) {
          await supabaseService.addStockEntry(
            branchId,
            item['id'],
            item['quantity'],
            item['unit_cost'],
            Supabase.instance.client.auth.currentUser?.id ?? '',
          );
        }
      });

      // ── Success: clear state silently, then show snackbar ──
      setState(() {
        cart.clear();
        supplierController.clear();
        totalValue = 0;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✓ تم تسجيل المشتريات وتحديث المخزون بنجاح'),
          backgroundColor: const Color(0xFF10b981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ));
      }
      inventoryController.fetchInventory();
    } catch (e) {
      setState(() => _isSaving = false);
      Get.snackbar('خطأ', 'فشل في حفظ المشتريات: $e',
        backgroundColor: AppTheme.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
      );
    }
  }

  @override
  void dispose() {
    barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Products Catalog (Left)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.truck, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text('كتالوج المنتجات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryDarker)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Barcode search
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: TextField(
                      controller: barcodeController,
                      onSubmitted: scanBarcode,
                      decoration: InputDecoration(
                        hintText: 'اسحب الباركود هنا أو أدخل الرقم...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLighter,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.scanLine, size: 18, color: AppTheme.primary),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Products grid
                  Expanded(
                    child: Obx(() {
                      if (inventoryController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: inventoryController.inventory.length,
                        itemBuilder: (context, index) {
                          final p = inventoryController.inventory[index];
                          return _buildProductCard(p);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Purchase Cart (Right)
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(-4, 0)),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary.withOpacity(0.05), AppTheme.primary.withOpacity(0.02)],
                    ),
                    border: Border(bottom: BorderSide(color: AppTheme.primary.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.fileText, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('فاتورة الشراء الجديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // Supplier name
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: supplierController,
                    decoration: InputDecoration(
                      labelText: 'اسم المورد / المصدر',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLighter,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.user, size: 18, color: AppTheme.primary),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                // Cart items
                Expanded(
                  child: cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.shoppingCart, size: 48, color: Colors.grey.shade200),
                              const SizedBox(height: 12),
                              Text('السلة فارغة', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cart.length,
                          itemBuilder: (context, index) {
                            final item = cart[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text('سعر التكلفة: ${item['unit_cost']} د.ع', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildQtyBtn(LucideIcons.minus, () {
                                        setState(() {
                                          if (item['quantity'] > 1) item['quantity'] -= 1;
                                          else cart.removeAt(index);
                                          calculateTotal();
                                        });
                                      }),
                                      GestureDetector(
                                        onTap: () => updateQuantityDialog(index),
                                        child: Container(
                                          width: 36,
                                          alignment: Alignment.center,
                                          child: Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                      ),
                                      _buildQtyBtn(LucideIcons.plus, () {
                                        setState(() {
                                          item['quantity'] += 1;
                                          calculateTotal();
                                        });
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Total + Save
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('إجمالي الفاتورة:', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                          Text(
                            '$totalValue د.ع',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.buttonShadow,
                        ),
                          child: ElevatedButton(
                          onPressed: _isSaving ? null : savePurchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.check, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('تثبيت الشراء وتحديث المخزون', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: icon == LucideIcons.plus ? AppTheme.primaryLighter : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: icon == LucideIcons.plus ? AppTheme.primary : Colors.grey.shade600),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    return GestureDetector(
      onTap: () => addToPurchase(p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(LucideIcons.package, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('التكلفة: ${p['cost'] ?? 0} د.ع', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
