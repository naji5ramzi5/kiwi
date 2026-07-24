import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../controllers/auth_controller.dart';
import '../controllers/inventory_controller.dart';

class POSOrdersController extends GetxController {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();

  var orders = <Map<String, dynamic>>[].obs;
  var drivers = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var pendingCount = 0.obs;

  RealtimeChannel? _ordersChannel;

  int get _pendingOrders => orders.where((o) {
    final status = o['status']?.toString() ?? '';
    return status == 'pending' || status == 'preparing';
  }).length;

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
          .update({'driver_id': driverId, 'status': 'picked_up'})
          .eq('id', orderId);

      // Notify the assigned driver via FCM
      try {
        await supabase.functions.invoke(
          'send-fcm-notification',
          body: {
            'userId': driverId,
            'title': 'طلب جديد تم إسناده إليك',
            'body': 'تم إسناد طلب جديد لك. الرجاء التوجه لاستلامه من الفرع.',
            'data': {'orderId': orderId, 'type': 'new_assignment'},
          },
        );
      } catch (fcmErr) {
        print('Failed to send FCM to driver: $fcmErr');
      }

      Get.snackbar('تم الإسناد', 'تم إسناد الطلب للمندوب بنجاح');
      fetchOrders();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إسناد المندوب: $e');
    }
  }

  Future<void> fetchOrders() async {
    try {
      isLoading(true);
      final branchId = authController.currentBranchId.value;

      // Fetch orders for this branch (including orders without branch_id for backward compatibility)
      final response = await supabase
          .from('orders')
          .select(
            '*, profiles(full_name, phone), order_items(*, products(name))',
          )
          .or('branch_id.eq.$branchId,and(branch_id.is.null,status.eq.pending)')
          .order('created_at', ascending: false);

      orders.value = List<Map<String, dynamic>>.from(response);
      pendingCount.value = _pendingOrders;
    } catch (e) {
      print('Error fetching orders: $e');
      // Fallback: try without branch_id filter
      try {
        final response = await supabase
            .from('orders')
            .select(
              '*, profiles(full_name, phone), order_items(*, products(name))',
            )
            .order('created_at', ascending: false)
            .limit(50);
        orders.value = List<Map<String, dynamic>>.from(response);
        pendingCount.value = _pendingOrders;
      } catch (e2) {
        print('Fallback fetch also failed: $e2');
      }
    } finally {
      isLoading(false);
    }
  }

  void subscribeToOrders() {
    final branchId = authController.currentBranchId.value;
    _ordersChannel = supabase
        .channel('public:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'branch_id',
            value: branchId,
          ),
          callback: (payload) {
            // Vibrate + alert on brand new orders (INSERT)
            if (payload.eventType == PostgresChangeEvent.insert) {
              _alertNewOrder();
            }
            fetchOrders();
          },
        )
        .subscribe();
  }

  @override
  void onClose() {
    if (_ordersChannel != null) {
      supabase.removeChannel(_ordersChannel!);
    }
    super.onClose();
  }

  /// Plays a vibration and shows an alert when a new order arrives for this branch.
  Future<void> _alertNewOrder() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    Get.snackbar(
      'طلب جديد',
      'وصل طلب جديد إلى الفرع',
      backgroundColor: const Color(0xFF10b981),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    try {
      // Update order status - the DB trigger will automatically create notifications
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // Refresh inventory controller if registered
      try {
        if (Get.isRegistered<InventoryController>()) {
          Get.find<InventoryController>().fetchInventory();
        }
      } catch (_) {}

      // Map status to Arabic for display
      final statusArabic = {
        'pending': 'بالانتظار',
        'preparing': 'قيد التحضير',
        'picked_up': 'تم الاستلام من الفرع',
        'rejected': 'مرفوض',
        'shipped': 'في الطريق',
        'delivered': 'تم التوصيل',
        'cancelled': 'ملغي',
      };
      final displayStatus = statusArabic[newStatus] ?? newStatus;

      Get.snackbar(
        'تم التحديث',
        'حالة الطلب الآن: $displayStatus',
        snackPosition: SnackPosition.BOTTOM,
      );
      fetchOrders();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث الحالة: $e');
    }
  }
}
