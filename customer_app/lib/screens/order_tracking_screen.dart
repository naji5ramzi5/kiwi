import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../controllers/order_tracking_controller.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final OrderTrackingController controller = Get.put(OrderTrackingController(orderId: orderId));
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final order = controller.orderData;
        final driverId = order['driver_id'];

        return Stack(
          children: [
            // Mock Map View (Emerald Style)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF10b981).withOpacity(0.05),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(LucideIcons.map, size: 400, color: AppTheme.primary),
                    ),
                  ),
                  // Animated Driver Icon
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('id', driverId ?? ''),
                    builder: (context, snapshot) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20)],
                              ),
                              child: Icon(
                                order['vehicle_type'] == 'truck' ? LucideIcons.truck : LucideIcons.bike,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('المندوب في الطريق إليك', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: const Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
                onPressed: () => Get.back(),
              ),
            ),

            // Bottom Status Card
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.statusText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryDark)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStep(LucideIcons.packageCheck, 'تجهيز', isActive: controller.currentStep >= 1),
                        _buildStep(LucideIcons.truck, 'توصيل', isActive: controller.currentStep >= 2),
                        _buildStep(LucideIcons.home, 'وصول', isActive: controller.currentStep >= 3),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStep(IconData icon, String title, {bool isActive = false}) {
    return Column(
      children: [
        Icon(icon, color: isActive ? AppTheme.primary : Colors.grey[300], size: 32),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 12, color: isActive ? AppTheme.textPrimary : Colors.grey[400])),
      ],
    );
  }
}
