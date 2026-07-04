import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/order_tracking_controller.dart';
import '../theme/app_theme.dart';

class OrderTrackingMapScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingMapScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingMapScreen> createState() => _OrderTrackingMapScreenState();
}

class _OrderTrackingMapScreenState extends State<OrderTrackingMapScreen> {
  late final OrderTrackingController controller;
  final MapController _mapController = MapController();
  Map<String, dynamic>? driverProfile;

  @override
  void initState() {
    super.initState();
    controller = Get.put(OrderTrackingController(orderId: widget.orderId));
    _fetchDriverProfile();
  }

  Future<void> _fetchDriverProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final driverId = controller.orderData['driver_id'];
    if (driverId == null) return;
    try {
      final res = await controller.supabase
          .from('profiles')
          .select('full_name, phone')
          .eq('id', driverId)
          .single();
      if (mounted) setState(() => driverProfile = res);
    } catch (_) {}
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final order = controller.orderData;
        final hasDriver = order['driver_id'] != null;
        final hasLocation = order['drivers'] != null &&
            order['drivers']['last_location_lat'] != null;
        final driverLat = hasLocation
            ? double.tryParse(order['drivers']['last_location_lat'].toString()) ?? 33.3152
            : null;
        final driverLng = hasLocation
            ? double.tryParse(order['drivers']['last_location_lng'].toString()) ?? 44.3661
            : null;
        final driverPos = (driverLat != null && driverLng != null)
            ? LatLng(driverLat, driverLng)
            : null;
        final driverName = driverProfile?['full_name'] ?? 'مندوب التوصيل';
        final driverPhone = driverProfile?['phone'] ?? '';
        final step = controller.currentStep;

        return Stack(
          children: [
            if (hasDriver && driverPos != null)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: driverPos,
                  initialZoom: 15.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.freshenterprise.customer',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: driverPos,
                        width: 50,
                        height: 50,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.directions_bike, color: Color(0xFF10B981), size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFF0FDF4), const Color(0xFFECFDF5)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.hourglass_empty, size: 48, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'بانتظار قبول الطلب',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لم يتم تعيين مندوب بعد',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ),

            // Gradient overlay at bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (isDark ? const Color(0xFF121212) : Colors.white).withOpacity(0.95),
                    ],
                  ),
                ),
              ),
            ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.grey.shade800 : Colors.white).withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Icon(Icons.arrow_forward_rounded, color: isDark ? Colors.white : AppTheme.textPrimary, size: 22),
                ),
              ),
            ),

            // Top info bar
            if (hasDriver)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16, right: 72,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.grey.shade800 : Colors.white).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      const Text('مباشر', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Cairo')),
                      const Spacer(),
                      Text(
                        controller.statusText,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom card
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDriver) ...[
                      Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(driverName)}&background=10b981&color=fff',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverName,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.statusText,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                          ),
                          if (driverPhone.isNotEmpty)
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => launchUrl(Uri.parse('tel://$driverPhone')),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.call, color: Colors.blue, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => launchUrl(Uri.parse('https://wa.me/$driverPhone')),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.access_time, size: 32, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'بانتظار قبول الطلب',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'لم يتم تعيين مندوب بعد',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildSteps(step, hasDriver),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSteps(int currentStep, bool hasDriver) {
    final steps = ['تأكيد', 'تجهيز', 'توصيل', 'وصلنا'];
    final stepStatus = hasDriver ? currentStep : (currentStep > 0 ? currentStep : 0);
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= stepStatus;
        final isCurrent = index == stepStatus;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: index <= stepStatus ? const Color(0xFF10B981) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 16 : 12,
                    height: isCurrent ? 16 : 12,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF10B981) : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                          : null,
                    ),
                    child: isActive && !isCurrent
                        ? const Icon(Icons.check, color: Colors.white, size: 8)
                        : null,
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: index < stepStatus ? const Color(0xFF10B981) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(steps[index], style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF10B981) : Colors.grey.shade400,
                fontFamily: 'Cairo',
              )),
            ],
          ),
        );
      }),
    );
  }
}
