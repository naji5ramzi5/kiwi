import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

class OrderTrackingController extends GetxController {
  final String orderId;
  final supabase = Supabase.instance.client;
  
  var orderData = <String, dynamic>{}.obs;
  var isLoading = true.obs;
  var driverLat = 0.0.obs;
  var driverLng = 0.0.obs;

  // Arrival detection
  var arrivalBannerVisible = false.obs;
  bool _arrivalNotified = false;

  OrderTrackingController({required this.orderId});

  double get _customerLat {
    final o = orderData;
    if (o['customer_lat'] != null) return (o['customer_lat'] as num).toDouble();
    if (o['delivery_lat'] != null) return (o['delivery_lat'] as num).toDouble();
    return 33.3152;
  }

  double get _customerLng {
    final o = orderData;
    if (o['customer_lng'] != null) return (o['customer_lng'] as num).toDouble();
    if (o['delivery_lng'] != null) return (o['delivery_lng'] as num).toDouble();
    return 44.3661;
  }

  void _checkArrival() {
    if (_arrivalNotified) return;
    if (driverLat.value == 0.0 || driverLng.value == 0.0) return;
    const distance = Distance();
    final meters = distance.as(
      LengthUnit.Meter,
      LatLng(driverLat.value, driverLng.value),
      LatLng(_customerLat, _customerLng),
    );
    if (meters <= 100) {
      _arrivalNotified = true;
      arrivalBannerVisible(true);
      Get.snackbar(
        'driver_arrived_title'.tr,
        'driver_arrived_msg'.tr,
        backgroundColor: AppTheme.emerald,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchOrderDetails();
    subscribeToOrderChanges();
  }

  @override
  void onClose() {
    supabase.removeChannel(supabase.channel('public:orders:id=$orderId'));
    if (orderData['driver_id'] != null) {
      supabase.removeChannel(supabase.channel('driver-location:${orderData['driver_id']}'));
    }
    super.onClose();
  }

  Future<void> fetchOrderDetails() async {
    try {
      isLoading(true);
      final response = await supabase
          .from('orders')
          .select('*, drivers(*)')
          .eq('id', orderId)
          .single();
      
      orderData.value = response;
      
      final driverId = response['driver_id'];
      if (driverId != null) {
        subscribeToDriverLocation(driverId.toString());
        final driverData = response['drivers'];
        if (driverData is Map && driverData['last_location_lat'] != null) {
          driverLat.value = (driverData['last_location_lat'] as num).toDouble();
          driverLng.value = (driverData['last_location_lng'] as num).toDouble();
          _checkArrival();
        }
      }
    } catch (e) {
      debugPrint('Error fetching order: $e');
    } finally {
      isLoading(false);
    }
  }

  void subscribeToOrderChanges() {
    supabase
        .channel('public:orders:id=$orderId')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: orderId,
            ),
            callback: (payload) {
              final merged = <String, dynamic>{...orderData, ...payload.newRecord};
              orderData.assignAll(merged);
              // If driver assigned, subscribe to their location
              if (payload.newRecord['driver_id'] != null && orderData['driver_id'] == null) {
                subscribeToDriverLocation(payload.newRecord['driver_id'].toString());
              }
            })
        .subscribe();
  }

  void subscribeToDriverLocation(String driverId) {
    supabase
        .channel('driver-location:$driverId')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'drivers',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: driverId,
            ),
            callback: (payload) {
              final newLat = payload.newRecord['last_location_lat'];
              final newLng = payload.newRecord['last_location_lng'];
              if (newLat != null && newLng != null) {
                driverLat.value = (newLat as num).toDouble();
                driverLng.value = (newLng as num).toDouble();
                _checkArrival();
              }
            })
        .subscribe();
  }

  int get currentStep {
    final status = orderData['status'] ?? 'pending';
    switch (status) {
      case 'pending': return 0;
      case 'preparing': return 1;
      case 'prepared':
      case 'picked_up': return 2;
      case 'shipped': return 3;
      case 'delivered': return 4;
      default: return 0;
    }
  }

  String get statusText {
    final status = orderData['status'] ?? 'pending';
    switch (status) {
      case 'pending': return 'status_pending'.tr;
      case 'preparing': return 'status_preparing'.tr;
      case 'prepared': return 'status_prepared'.tr;
      case 'picked_up': return 'status_picked_up'.tr;
      case 'shipped': return 'status_shipped'.tr;
      case 'delivered': return 'status_delivered'.tr;
      default: return 'status_processing'.tr;
    }
  }
}
