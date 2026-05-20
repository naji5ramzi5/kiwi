import '../controllers/auth_controller.dart';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';

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
      // Fetch products and their current stock in branch 1
      // We'll join products table to get names and images
      final response = await supabase
          .from('products')
          .select('*, inventory(stock_quantity)')
          .order('name');
      
      inventory.value = List<Map<String, dynamic>>.from(response);
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
