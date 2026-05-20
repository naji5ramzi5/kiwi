import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final supabase = Supabase.instance.client;
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
      // Get the current branch ID from global state (Auth)
      final branchId = supabase.auth.currentUser?.userMetadata?['branch_id'] ?? 'BRANCH_ID_HERE';
      
      final response = await supabase
          .from('branch_inventory')
          .select('*, products(*)')
          .eq('branch_id', branchId);
      
      setState(() {
        _inventory = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> reportWaste(String productId, double qty) async {
    try {
      final branchId = supabase.auth.currentUser?.userMetadata?['branch_id'] ?? 'BRANCH_ID_HERE';
      
      await supabase.from('waste_records').insert({
        'branch_id': branchId,
        'product_id': productId,
        'quantity': qty,
        'reason': 'تلف فرع',
      });
      
      Get.snackbar('تم', 'تم تسجيل التالف وتحديث المخزون بنجاح');
      fetchInventory();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تسجيل التالف: $e');
    }
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
                    Text('جرد المنتجات الحالي لفرع: ${supabase.auth.currentUser?.userMetadata?['branch_name'] ?? 'الفرع الحالي'}', style: const TextStyle(color: AppTheme.textSecondary)),
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
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppTheme.primary.withOpacity(0.05)),
          columns: const [
            DataColumn(label: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المخزون الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: items.map((item) {
            final stock = item['actual_stock'];
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
                    onPressed: () => _showWasteDialog(item),
                    icon: const Icon(LucideIcons.alertTriangle, size: 14),
                    label: const Text('تسجيل تالف'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.red, elevation: 0),
                  ),
                ],
              )),
            ]);
          }).toList(),
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
}
