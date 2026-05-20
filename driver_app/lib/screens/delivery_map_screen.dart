import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryMapScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const DeliveryMapScreen({super.key, required this.order});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  final MapController _mapController = MapController();
  LatLng _customerLocation = const LatLng(33.3152, 44.3661); // Default Baghdad
  bool isMapReady = false;

  @override
  void initState() {
    super.initState();
    _parseLocation();
  }

  void _parseLocation() {
    // Attempt to parse coordinates from delivery_address or metadata if available
    // For now, using default coordinates, in production you would parse actual coords from the order
    if (widget.order['customer_lat'] != null && widget.order['customer_lng'] != null) {
      _customerLocation = LatLng(widget.order['customer_lat'], widget.order['customer_lng']);
    }
  }

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${_customerLocation.latitude},${_customerLocation.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'لا يمكن فتح خرائط جوجل', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDelivering = widget.order['status'] == 'توصيل';

    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _customerLocation,
              initialZoom: 14.0,
              onMapReady: () => setState(() => isMapReady = true),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.freshenterprise.driver',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _customerLocation,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF10b981).withOpacity(0.4), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: const Icon(LucideIcons.mapPin, color: Color(0xFF10b981), size: 35),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Custom App Bar / Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: const Icon(LucideIcons.arrowRight, color: Color(0xFF1F2937)),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Info Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, -10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('طلب #${widget.order['id'].toString().substring(0, 5).toUpperCase()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                          const SizedBox(height: 4),
                          Text(isDelivering ? 'جاري التوصيل' : 'جاهز للاستلام من الفرع', style: TextStyle(color: isDelivering ? const Color(0xFF10b981) : Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.packageOpen, color: Color(0xFF10b981), size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.mapPin, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(widget.order['delivery_address'] ?? 'عنوان العميل', style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _openGoogleMaps,
                          icon: const Icon(LucideIcons.navigation, size: 18),
                          label: const Text('تتبع عبر Google Maps', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: const Color(0xFF1F2937),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Icon(LucideIcons.phoneCall, size: 20),
                        ),
                      ),
                    ],
                  ),
                  if (isDelivering) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Supabase.instance.client.from('orders').update({'status': 'تم التوصيل'}).eq('id', widget.order['id']);
                          Get.back();
                          Get.snackbar('عمل ممتاز!', 'تم إنهاء الطلب وتسليمه للعميل بنجاح', backgroundColor: const Color(0xFF10b981), colorText: Colors.white, margin: const EdgeInsets.all(16));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('تأكيد تسليم الطلب للعميل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
