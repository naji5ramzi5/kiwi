import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../services/supabase_service.dart';

class InventoryController extends GetxController {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();
  
  var inventory = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (authController.isLoggedIn.value) {
      fetchInventory();
    }
  }

  Future<void> fetchInventory() async {
    try {
      isLoading(true);
      // Fetch products using SupabaseService to ensure branch filtering applies correctly
      final products = await SupabaseService().getProducts(branchId: authController.currentBranchId.value);
      
      inventory.value = products.map((p) => {
        'id': p.id,
        'name': p.name,
        'image_url': p.imageUrl,
        'default_price': p.defaultPrice,
        'barcode': p.barcode,
        'cost': p.defaultPrice,
        'inventory': [{'stock_quantity': p.stockQuantity}],
      }).toList();
    } catch (e) {
      print('Error fetching inventory: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateStock(String productId, double newQuantity) async {
    try {
      await supabase.from('inventory').upsert({
        'branch_id': authController.currentBranchId.value,
        'product_id': productId,
        'stock_quantity': newQuantity,
      });
      fetchInventory();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث المخزون: $e');
    }
  }
}
