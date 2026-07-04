import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../../theme/app_theme.dart';
import '../../controllers/order_tracking_controller.dart';
import 'rating/rate_driver_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final OrderTrackingController controller = Get.put(OrderTrackingController(orderId: orderId));
    final supabase = Supabase.instance.client;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAF5),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final order = controller.orderData;
        if (order.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.packageOpen, size: 72, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد طلبات حالياً',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'عند تقديم طلب جديد سيظهر هنا',
                  style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final driverId = order['driver_id'];

        return Stack(
          children: [
            // Map Background Area
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF064E3B).withOpacity(0.3), const Color(0xFF0F1722)]
                      : [const Color(0xFF10b981).withOpacity(0.06), const Color(0xFFF8FAF5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: isDark ? 0.06 : 0.08,
                      child: const Icon(LucideIcons.map, size: 400, color: Color(0xFF047857)),
                    ),
                  ),
                  // Driver Info Card
                  if (controller.currentStep >= 2)
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('id', driverId ?? ''),
                      builder: (context, snapshot) {
                        final driverProfile = (snapshot.hasData && snapshot.data!.isNotEmpty) ? snapshot.data!.first : null;
                        final driverName = driverProfile?['full_name'] ?? 'سامي محمد';
                        final driverPhone = driverProfile?['phone'] ?? '07712345678';
                        final driverImage = driverProfile?['avatar_url'] ?? 'https://ui-avatars.com/api/?name=Driver&background=10b981&color=fff';

                        return Positioned(
                          bottom: 240,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B).withOpacity(0.95) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.8),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF10B981), width: 2),
                                      ),
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundImage: NetworkImage(driverImage),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            driverName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              fontFamily: 'Cairo',
                                              color: isDark ? Colors.white : const Color(0xFF064E3B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'المندوب في الطريق إليك',
                                            style: TextStyle(
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                              fontSize: 12,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.call, color: Color(0xFF10B981), size: 20),
                                            onPressed: () async {
                                              final uri = Uri.parse('tel:$driverPhone');
                                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF25D366).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: Image.asset(
                                              'assets/images/whatsapp.png',
                                              width: 18,
                                              height: 18,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.chat, color: Color(0xFF25D366), size: 18),
                                            ),
                                            onPressed: () async {
                                              final uri = Uri.parse('https://wa.me/$driverPhone');
                                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Back button
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.9) : Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.textPrimary, size: 20),
                  onPressed: () => Get.back(),
                ),
              ),
            ),

            // Bottom Status Card
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1722) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.5 : 0.06),
                      blurRadius: 25,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status text
                    Text(
                      controller.statusText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF064E3B),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Timeline steps with connecting lines
                    Row(
                      children: [
                        _buildTimelineStep(LucideIcons.packageCheck, 'تجهيز', 1, controller.currentStep, isDark),
                        _buildTimelineConnector(1, controller.currentStep, isDark),
                        _buildTimelineStep(LucideIcons.truck, 'توصيل', 2, controller.currentStep, isDark),
                        _buildTimelineConnector(2, controller.currentStep, isDark),
                        _buildTimelineStep(LucideIcons.home, 'وصول', 3, controller.currentStep, isDark),
                      ],
                    ),
                    if (controller.currentStep >= 3) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final driverId = order['driver_id'] ?? '';
                            String driverName = 'المندوب';
                            String? driverImage;
                            try {
                              final profile = await supabase
                                  .from('profiles')
                                  .select('full_name, avatar_url')
                                  .eq('id', driverId)
                                  .single();
                              driverName = profile['full_name'] ?? 'المندوب';
                              driverImage = profile['avatar_url'];
                            } catch (_) {}
                            final result = await Get.to(
                              () => RateDriverScreen(
                                orderId: orderId,
                                driverId: driverId,
                                driverName: driverName,
                                driverImage: driverImage,
                              ),
                              transition: Transition.fadeIn,
                            );
                            if (result == true) Get.back();
                          },
                          icon: const Icon(LucideIcons.star, color: Colors.white, size: 20),
                          label: const Text(
                            'قيم المندوب',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Cairo'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTimelineStep(IconData icon, String title, int step, int currentStep, bool isDark) {
    final isActive = currentStep >= step;
    final isCompleted = currentStep > step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF10B981)
                  : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Icon(
              isCompleted ? LucideIcons.check : icon,
              size: 20,
              color: isActive ? Colors.white : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
              color: isActive
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF064E3B))
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(int step, int currentStep, bool isDark) {
    final isActive = currentStep > step;
    return SizedBox(
      width: 32,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [const Color(0xFF10B981), const Color(0xFF10B981)]
                : [isDark ? const Color(0xFF334155) : Colors.grey.shade200, isDark ? const Color(0xFF334155) : Colors.grey.shade200],
          ),
        ),
      ),
    );
  }
}