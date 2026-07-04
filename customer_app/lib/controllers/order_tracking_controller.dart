import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderTrackingController extends GetxController {
  final String orderId;
  final supabase = Supabase.instance.client;
  
  var orderData = <String, dynamic>{}.obs;
  var isLoading = true.obs;

  OrderTrackingController({required this.orderId});

  @override
  void onInit() {
    super.onInit();
    fetchOrderDetails();
    subscribeToOrderChanges();
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
    } catch (e) {
      print('Error fetching order: $e');
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
              print('Order Updated: ${payload.newRecord}');
              final merged = <String, dynamic>{...orderData, ...payload.newRecord};
              orderData.assignAll(merged);
            })
        .subscribe();
  }

  int get currentStep {
    final status = orderData['status'] ?? 'pending';
    switch (status) {
      case 'pending': return 0;
      case 'preparing': return 1;
      case 'shipped': return 2;
      case 'delivered': return 3;
      default: return 0;
    }
  }

  String get statusText {
    final status = orderData['status'] ?? 'pending';
    switch (status) {
      case 'pending': return 'بانتظار الموافقة';
      case 'preparing': return 'جاري التحضير';
      case 'shipped': return 'في الطريق إليك';
      case 'delivered': return 'تم التوصيل بنجاح';
      default: return 'جاري المعالجة';
    }
  }
}
