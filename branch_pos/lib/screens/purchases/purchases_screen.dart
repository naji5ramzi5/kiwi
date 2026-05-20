import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/inventory_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final supabase = Supabase.instance.client;
  final InventoryController inventoryController = Get.find<InventoryController>();
  
  List<Map<String, dynamic>> cart = [];
  String supplierName = '';
  double totalValue = 0;

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
    if (cart.isEmpty || supplierName.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى اختيار منتجات وإدخال اسم المورد');
      return;
    }

    try {
      // 1. Create Purchase record
      final purchaseResponse = await supabase.from('purchases').insert({
        'branch_id': 1, // Assume branch 1 for now
        'supplier_name': supplierName,
        'total_value': totalValue,
      }).select().single();

      // 2. Create Purchase Items
      final List<Map<String, dynamic>> itemsToInsert = cart.map((item) => {
        'purchase_id': purchaseResponse['id'],
        'product_id': item['id'],
        'quantity': item['quantity'],
        'unit_cost': item['unit_cost'],
        'total_cost': item['quantity'] * item['unit_cost'],
      }).toList();

      await supabase.from('purchase_items').insert(itemsToInsert);

      Get.snackbar('نجاح', 'تم تسجيل المشتريات وتحديث المخزون تلقائياً');
      setState(() {
        cart = [];
        supplierName = '';
        totalValue = 0;
      });
      inventoryController.fetchInventory();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حفظ المشتريات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('قسم المشتريات (توريد المخزون)')),
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
                  const Text('كتالوج المنتجات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(() {
                      if (inventoryController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2
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
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('فاتورة الشراء الجديدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  onChanged: (v) => supplierName = v,
                  decoration: InputDecoration(
                    labelText: 'اسم المورد / المصدر',
                    prefixIcon: const Icon(LucideIcons.user),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: cart.isEmpty 
                    ? const Center(child: Text('السلة فارغة', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          return ListTile(
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('سعر التكلفة: ${item['unit_cost']} د.ع'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(LucideIcons.minusCircle, size: 20), onPressed: () {
                                  setState(() {
                                    if (item['quantity'] > 1) item['quantity'] -= 1;
                                    else cart.removeAt(index);
                                    calculateTotal();
                                  });
                                }),
                                Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(LucideIcons.plusCircle, size: 20, color: AppTheme.primary), onPressed: () {
                                  setState(() {
                                    item['quantity'] += 1;
                                    calculateTotal();
                                  });
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                ),
                const Divider(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي الفاتورة:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text('$totalValue د.ع', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryDark)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: savePurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('تثبيت الشراء وتحديث المخزون', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    return GestureDetector(
      onTap: () => addToPurchase(p),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.package, color: AppTheme.primary, size: 32),
            const SizedBox(height: 12),
            Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('التكلفة: ${p['cost'] ?? 0} د.ع', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
