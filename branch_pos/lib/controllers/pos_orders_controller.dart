import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';
import '../controllers/inventory_controller.dart';

class POSOrdersController extends GetxController {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();
  
  var orders = <Map<String, dynamic>>[].obs;
  var drivers = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (authController.isLoggedIn.value) {
      fetchOrders();
      fetchDrivers();
      subscribeToOrders();
    }
  }

  Future<void> fetchDrivers() async {
    try {
      final response = await supabase
          .from('drivers')
          .select('*, profiles(full_name)')
          .eq('is_active', true);
      drivers.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching drivers: $e');
    }
  }

  Future<void> assignDriver(String orderId, String driverId) async {
    try {
      await supabase
          .from('orders')
          .update({'driver_id': driverId, 'status': 'shipped'})
          .eq('id', orderId);
      
      Get.snackbar('تم الإسناد', 'تم إسناد الطلب للمندوب بنجاح');
      fetchOrders();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إسناد المندوب: $e');
    }
  }

  Future<void> fetchOrders() async {
    try {
      isLoading(true);
      // For now, fetch all orders for the branch (assuming branch_id = 1 for testing)
      final response = await supabase
          .from('orders')
          .select('*, profiles(full_name, phone), order_items(*, products(name))')
          .eq('branch_id', authController.currentBranchId.value)
          .order('created_at', ascending: false);
      
      orders.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      isLoading(false);
    }
  }

  void subscribeToOrders() {
    supabase
        .channel('public:orders')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'branch_id',
              value: authController.currentBranchId.value,
            ),
            callback: (payload) {
              fetchOrders();
            })
        .subscribe();
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      
      // If preparing, the SQL Trigger will handle inventory deduction automatically
      // based on the schema we set up earlier. 
      // But we will refresh the inventory controller if it exists
      try {
        if (Get.isRegistered<InventoryController>()) {
          Get.find<InventoryController>().fetchInventory();
        }
      } catch (_) {}

      Get.snackbar(
        'تم التحديث',
        'حالة الطلب الآن: $newStatus',
        snackPosition: SnackPosition.BOTTOM,
      );
      fetchOrders();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث الحالة: $e');
    }
  }
}
