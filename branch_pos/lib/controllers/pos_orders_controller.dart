import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _subscribed = false;

  int get _pendingOrders => orders.where((o) {
    final status = o['status']?.toString() ?? '';
    return status == 'pending' || status == 'preparing' || status == 'prepared';
  }).length;

  @override
  void onInit() {
    super.onInit();
    // Subscribe once the branch logs in — the controller is created before
    // login, so a plain isLoggedIn check in onInit would never subscribe.
    _startIfLoggedIn();
    ever(authController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        _startIfLoggedIn();
      } else {
        // Full reset on logout so a subsequent login (possibly a different
        // branch) re-subscribes with the new branch filter.
        if (_ordersChannel != null) {
          supabase.removeChannel(_ordersChannel!);
          _ordersChannel = null;
        }
        _subscribed = false;
        orders.clear();
        pendingCount.value = 0;
      }
    });
  }

  void _startIfLoggedIn() {
    if (!authController.isLoggedIn.value) return;
    if (_subscribed) return;
    _subscribed = true;
    fetchOrders();
    fetchDrivers();
    subscribeToOrders();
  }

  Future<void> fetchDrivers() async {
    try {
      final branchId = authController.currentBranchId.value;
      // Fetch active delivery employees for this branch (using view to avoid broken FK join)
      final response = await supabase
          .from('delivery_employees_with_profiles')
          .select('id, user_id, status, is_active, full_name, phone, is_online')
          .eq('branch_id', branchId)
          .eq('is_active', true);
      drivers.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
      // Fallback: fetch all drivers (backward compat)
      try {
        final response = await supabase
            .from('drivers')
            .select('*, profiles(full_name)')
            .eq('is_active', true);
        drivers.value = List<Map<String, dynamic>>.from(response);
      } catch (e2) {
        debugPrint('Fallback fetch drivers also failed: $e2');
      }
    }
  }

  Future<void> assignDriver(String orderId, String employeeId) async {
    try {
      await supabase.rpc('assign_order_to_delivery', params: {
        'p_order_id': orderId,
        'p_employee_id': employeeId,
      });

      // Notify the assigned driver via FCM (edge function)
      try {
        final emp = drivers.firstWhereOrNull((d) => d['id'] == employeeId);
        if (emp != null) {
          await supabase.functions.invoke(
            'send-notification',
            body: {
              'userId': emp['user_id'],
              'title': 'طلب جديد تم إسناده إليك',
              'body': 'تم إسناد طلب جديد لك. الرجاء التوجه لاستلامه من الفرع.',
              'data': {'orderId': orderId, 'type': 'new_assignment'},
            },
          );
        }
      } catch (fcmErr) {
        debugPrint('Failed to send FCM to driver: $fcmErr');
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

      // Fetch recent orders for this branch (last 100 to keep it fast with high volume)
      final response = await supabase
          .from('orders')
          .select(
            '*, profiles(full_name, phone), order_items(*, products(name))',
          )
          .or('branch_id.eq.$branchId,and(branch_id.is.null,status.eq.pending)')
          .order('created_at', ascending: false)
          .limit(100);

      orders.value = List<Map<String, dynamic>>.from(response);
      pendingCount.value = _pendingOrders;
    } catch (e) {
      debugPrint('Error fetching orders: $e');
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
        debugPrint('Fallback fetch also failed: $e2');
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

  /// Plays an audible alert and shows a popup when a new order arrives.
  Future<void> _alertNewOrder() async {
    // Audible notification (works on Windows desktop)
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    Get.snackbar(
      '🔔 طلب جديد',
      'وصل طلب جديد إلى الفرع',
      backgroundColor: const Color(0xFF10b981),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 6),
      isDismissible: true,
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
        'prepared': 'تم التحضير',
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
