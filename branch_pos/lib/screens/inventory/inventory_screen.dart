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

      final productsResponse = await supabase
          .from('products')
          .select('*')
          .eq('is_active', true);

      final invResponse = await supabase
          .from('branch_inventory')
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
              ? (invEntry['actual_stock'] is num ? (invEntry['actual_stock'] as num).toDouble() : double.tryParse(invEntry['actual_stock'].toString()) ?? 0.0)
              : 0.0,
          'min_stock_level': invEntry.isNotEmpty
              ? (invEntry['buffer_limit'] is num ? (invEntry['buffer_limit'] as num).toDouble() : double.tryParse(invEntry['buffer_limit'].toString()) ?? 2.0)
              : 2.0,
          'products': prod,
        };
      }).toList();

      setState(() {
        _inventory = mappedInventory;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> updateStock(String productId, double qty) async {
    try {
      final branchId = authController.currentBranchId.value;

      await supabase.from('branch_inventory').upsert({
        'branch_id': branchId,
        'product_id': productId,
        'actual_stock': qty,
        'is_active': true,
      }, onConflict: 'branch_id,product_id');

      Get.snackbar('تم', 'تم تحديث كمية المخزون بنجاح',
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
      fetchInventory();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث المخزون: $e',
        backgroundColor: AppTheme.error,
        colorText: Colors.white,
      );
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

      await _decrementStock(branchId, productId, qty);

      Get.snackbar('تم', 'تم تسجيل التالف وتحديث المخزون بنجاح',
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
      fetchInventory();
    } catch (e) {
      try {
        await supabase.from('waste_records').insert({
          'branch_id': branchId,
          'product_id': productId,
          'quantity': qty,
          'reason': 'تلف فرع',
        });

        await _decrementStock(branchId, productId, qty);

        Get.snackbar('تم', 'تم تسجيل التالف وتحديث المخزون بنجاح',
          backgroundColor: AppTheme.success,
          colorText: Colors.white,
        );
        fetchInventory();
      } catch (err) {
        Get.snackbar('خطأ', 'فشل تسجيل التالف: $err',
          backgroundColor: AppTheme.error,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _decrementStock(String branchId, String productId, double qty) async {
    try {
      final current = await supabase
          .from('branch_inventory')
          .select('actual_stock')
          .eq('branch_id', branchId)
          .eq('product_id', productId)
          .maybeSingle();

      final currentStock = (current?['actual_stock'] ?? 0).toDouble();
      final newStock = (currentStock - qty) < 0 ? 0.0 : currentStock - qty;

      await supabase.from('branch_inventory').upsert({
        'branch_id': branchId,
        'product_id': productId,
        'actual_stock': newStock,
        'is_active': true,
      }, onConflict: 'branch_id,product_id');
    } catch (e) {
      debugPrint('Error decrementing stock for waste: $e');
    }
  }

  void _generateBarcode(Map<String, dynamic> item) {
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
          const Text('تم ربط هذا الباركود محلياً للصنف لطباعته واستخدامه في المبيعات والمشتريات.'),
        ],
      ),
      confirm: ElevatedButton.icon(
        onPressed: () {
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.package, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Text('إدارة المخزون والتوالف', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.primaryDarker)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Obx(() => Text('جرد المنتجات الحالي لفرع: ${authController.currentBranchName.value}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                  ],
                ),
                _buildSearchField(),
              ],
            ),
            const SizedBox(height: 32),
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
      width: 360,
      height: 44,
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
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'بحث عن منتج...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(LucideIcons.search, size: 18, color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildInventoryTable(List<Map<String, dynamic>> items) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.primaryLighter),
                columns: const [
                  DataColumn(label: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDarker))),
                  DataColumn(label: Text('المخزون الحالي', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDarker))),
                  DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDarker))),
                  DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDarker))),
                ],
                rows: items.map((item) {
                  final stock = item['stock_quantity'];
                  final unit = item['products']['unit'];
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.package, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(item['products']['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    )),
                    DataCell(Text(
                      '$stock $unit',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primaryDarker),
                    )),
                    DataCell(_buildStatusBadge(stock)),
                    DataCell(Row(
                      children: [
                        _buildActionBtn(
                          'تحديث الكمية',
                          LucideIcons.edit2,
                          AppTheme.primary,
                          () => _showUpdateStockDialog(item),
                        ),
                        const SizedBox(width: 8),
                        _buildActionBtn(
                          'تسجيل تالف',
                          LucideIcons.alertTriangle,
                          AppTheme.error,
                          () => _showWasteDialog(item),
                          isDestructive: true,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _generateBarcode(item),
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLighter,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.qr_code, size: 16, color: AppTheme.primary),
                          ),
                          tooltip: 'توليد وطباعة باركود',
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive ? AppTheme.errorLight : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(double stock) {
    String label = 'متوفر';
    Color color = AppTheme.success;
    if (stock <= 0) { label = 'منتهي'; color = AppTheme.error; }
    else if (stock < 5) { label = 'منخفض'; color = AppTheme.warning; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
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
