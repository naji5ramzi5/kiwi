import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  var selectedIndex = 0.obs;
  var deliveryCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDeliveryCount();
  }

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  Future<void> fetchDeliveryCount() async {
    try {
      final auth = Get.find<AuthController>();
      final branchId = auth.currentBranchId.value;
      if (branchId.isEmpty) return;

      final response = await Supabase.instance.client
          .from('delivery_employees')
          .select('id')
          .eq('branch_id', branchId)
          .eq('is_active', true);

      deliveryCount.value = response.length;
    } catch (e) {
      print('Error fetching delivery count: $e');
    }
  }
}
