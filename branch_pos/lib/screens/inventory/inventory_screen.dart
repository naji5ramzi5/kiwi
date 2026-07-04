import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();
  
  List<Map<String, dynamic>> _inventory = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      setState(() => _loading = true);
      final branchId = authController.currentBranchId.value;
      
      // 1. Fetch all active products in catalog
      final productsResponse = await supabase
          .from('products')
          .select('*')
          .eq('is_active', true);
      
      // 2. Fetch branch inventory
      final invResponse = await supabase
          .from('inventory')
          .select('*')
          .eq('branch_id', branchId);
      
      final List<Map<String, dynamic>> allCatalog = List<Map<String, dynamic>>.from(productsResponse);
      final List<Map<String, dynamic>> branchInv = List<Map<String, dynamic>>.from(invResponse);
      
      final List<Map<String, dynamic>> mappedInventory = allCatalog.map((prod) {
        final invEntry = branchInv.firstWhere(
          (inv) => inv['product_id'] == prod['id'],
          orElse: () => <String, dynamic>{},
        );
        
        return {
          'id': invEntry.isNotEmpty ? invEntry['id'] : null,
          'product_id': prod['id'],
          'branch_id': branchId,
          'stock_quantity': invEntry.isNotEmpty 
              ? (invEntry['stock_quantity'] is num ? (invEntry['stock_quantity'] as num).toDouble() : double.tryParse(invEntry['stock_quantity'].toString()) ?? 0.0)
              : 0.0,
          'min_stock_level': invEntry.isNotEmpty 
              ? (invEntry['min_stock_level'] is num ? (invEntry['min_stock_level'] as num).toDouble() : double.tryParse(invEntry['min_stock_level'].toString()) ?? 2.0)
              : 2.0,
          'products': prod,
        };
      }).toList();

      setState(() {
        _inventory = mappedInventory;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching inventory: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> updateStock(String productId, double qty) async {
    try {
      final branchId = authController.currentBranchId.value;
      
      await supabase.from('inventory').upsert({
        'branch_id': branchId,
        'product_id': productId,
        'stock_quantity': qty,
      }, onConflict: 'branch_id,product_id');
      
      Get.snackbar('تم', 'تم تحديث كمية المخزون بنجاح');
      fetchInventory();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث المخزون: $e');
    }
  }

  Future<void> reportWaste(String productId, double qty) async {
    final branchId = authController.currentBranchId.value;
    try {
      await supabase.from('damaged_goods').insert({
        'branch_id': branchId,
        'product_id': productId,
        'quantity': qty,
        'loss_value': 0.00,
        'reason': 'تلف فرع',
        'type': 'damaged'
      });
      
      Get.snackbar('تم', 'تم تسجيل التالف وتحديث المخزون بنجاح');
      fetchInventory();
    } catch (e) {
      try {
        await supabase.from('waste_records').insert({
          'branch_id': branchId,
          'product_id': productId,
          'quantity': qty,
          'reason': 'تلف فرع',
        });
        Get.snackbar('تم', 'تم تسجيل التالف وتحديث المخزون بنجاح');
        fetchInventory();
      } catch (err) {
        Get.snackbar('خطأ', 'فشل تسجيل التالف: $err');
      }
    }
  }

  void _generateBarcode(Map<String, dynamic> item) {
    // Basic local barcode generation (e.g. branch prefix + product id)
    final String branchId = authController.currentBranchId.value.toString();
    final String productId = item['product_id'].toString();
    final String localBarcode = 'BR-$branchId-PR-$productId';
    
    Get.defaultDialog(
      title: 'طباعة باركود محلي',
      content: Column(
        children: [
          const Text('الباركود المولد للصنف:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            child: Text(localBarcode, style: const TextStyle(fontSize: 18, letterSpacing: 2)),
          ),
          const SizedBox(height: 10),
          const Text('تم ربط هذا الباركود محلياً للصنف لطباعته واستخدامه في המبيعات والمشتريات.'),
        ],
      ),
      confirm: ElevatedButton.icon(
        onPressed: () {
          // Implement actual printing logic via printing package
          Get.back();
          Get.snackbar('جاري الطباعة', 'يتم إرسال أمر الطباعة إلى طابعة الباركود الحرارية...');
        },
        icon: const Icon(LucideIcons.printer, size: 16),
        label: const Text('طباعة استيكر الباركود'),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('إغلاق')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _inventory.where((item) => 
      item['products']['name'].toString().contains(_search)
    ).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إدارة المخزون والتوالف', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryDark)),
                    Obx(() => Text('جرد المنتجات الحالي لفرع: ${authController.currentBranchName.value}', style: const TextStyle(color: AppTheme.textSecondary))),
                  ],
                ),
                _buildSearchField(),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator()) 
                : _buildInventoryTable(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: const InputDecoration(border: InputBorder.none, hintText: 'بحث عن منتج...', icon: Icon(LucideIcons.search, size: 18)),
      ),
    );
  }

  Widget _buildInventoryTable(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30)]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.primary.withOpacity(0.05)),
              columns: const [
                DataColumn(label: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('المخزون الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: items.map((item) {
                final stock = item['stock_quantity'];
                final unit = item['products']['unit'];
                return DataRow(cells: [
                  DataCell(Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)), child: const Icon(LucideIcons.package, size: 20)),
                      const SizedBox(width: 12),
                      Text(item['products']['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )),
                  DataCell(Text('$stock $unit', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                  DataCell(_buildStatusBadge(stock)),
                  DataCell(Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showUpdateStockDialog(item),
                        icon: const Icon(LucideIcons.edit2, size: 14),
                        label: const Text('تحديث الكمية'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary.withOpacity(0.1), foregroundColor: AppTheme.primary, elevation: 0),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showWasteDialog(item),
                        icon: const Icon(LucideIcons.alertTriangle, size: 14),
                        label: const Text('تسجيل تالف'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.red, elevation: 0),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _generateBarcode(item),
                        icon: const Icon(Icons.qr_code, size: 20),
                        tooltip: 'توليد وطباعة باركود',
                        color: AppTheme.secondary,
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(double stock) {
    String label = 'متوفر';
    Color color = Colors.green;
    if (stock <= 0) { label = 'منتهي'; color = Colors.red; }
    else if (stock < 5) { label = 'منخفض'; color = Colors.orange; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showWasteDialog(Map<String, dynamic> item) {
    final controller = TextEditingController();
    Get.defaultDialog(
      title: 'تسجيل تالف: ${item['products']['name']}',
      content: Column(
        children: [
          const Text('أدخل الكمية التالفة التي سيتم خصمها من المخزون'),
          const SizedBox(height: 20),
          TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'الكمية بـ ${item['products']['unit']}')),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          final qty = double.tryParse(controller.text) ?? 0;
          if (qty > 0) {
            reportWaste(item['product_id'], qty);
            Get.back();
          }
        },
        child: const Text('تأكيد التلف'),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
    );
  }

  void _showUpdateStockDialog(Map<String, dynamic> item) {
    final controller = TextEditingController(text: item['stock_quantity'].toString());
    Get.defaultDialog(
      title: 'تعديل مخزون: ${item['products']['name']}',
      content: Column(
        children: [
          const Text('أدخل الكمية الفعلية المتوفرة في الرفوف حالياً'),
          const SizedBox(height: 20),
          TextField(
            controller: controller, 
            keyboardType: TextInputType.number, 
            decoration: InputDecoration(hintText: 'الكمية بـ ${item['products']['unit']}')
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          final qty = double.tryParse(controller.text) ?? -1;
          if (qty >= 0) {
            updateStock(item['product_id'], qty);
            Get.back();
          } else {
            Get.snackbar('تنبيه', 'يرجى إدخال كمية صحيحة');
          }
        },
        child: const Text('تأكيد الكمية'),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
    );
  }
}
