import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryMapScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const DeliveryMapScreen({super.key, required this.order});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  final MapController _mapController = MapController();
  LatLng _customerLocation = const LatLng(33.3152, 44.3661);
  LatLng? _driverLocation;
  bool isMapReady = false;
  bool isLocating = false;

  @override
  void initState() {
    super.initState();
    _parseLocation();
    _getDriverLocation();
  }

  void _parseLocation() {
    if (widget.order['customer_lat'] != null && widget.order['customer_lng'] != null) {
      _customerLocation = LatLng(
        (widget.order['customer_lat'] as num).toDouble(),
        (widget.order['customer_lng'] as num).toDouble(),
      );
    }
  }

  Future<void> _getDriverLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    setState(() => isLocating = true);
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _driverLocation = LatLng(pos.latitude, pos.longitude);
        isLocating = false;
      });
    } catch (e) {
      setState(() => isLocating = false);
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

  Future<void> _callCustomer() async {
    final phone = widget.order['customer_phone'];
    if (phone == null || phone.toString().isEmpty) {
      Get.snackbar('تنبيه', 'لا يوجد رقم هاتف للعميل', backgroundColor: Colors.orange, colorText: Colors.white, margin: const EdgeInsets.all(16));
      return;
    }
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'لا يمكن إجراء المكالمة', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _confirmDelivery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 60);

    if (picked == null) {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('تأكيد التسليم'),
          content: const Text('لم يتم التقاط صورة إثبات التوصيل. هل تريد تأكيد التسليم بدون صورة؟'),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('تأكيد بدون صورة')),
          ],
        ),
      );
      if (confirm != true) return;
    } else {
      try {
        final fileName = 'proof_${widget.order['id']}.jpg';
        await Supabase.instance.client.storage.from('delivery_proofs').upload(fileName, File(picked.path));
        final proofUrl = Supabase.instance.client.storage.from('delivery_proofs').getPublicUrl(fileName);
        await Supabase.instance.client.from('orders').update({'proof_image': proofUrl}).eq('id', widget.order['id']);
      } catch (e) {
        debugPrint('Proof upload failed: $e');
      }
    }

    await Supabase.instance.client.from('orders').update({'status': 'delivered'}).eq('id', widget.order['id']);
    Get.back();
    Get.snackbar('عمل ممتاز!', 'تم إنهاء الطلب وتسليمه للعميل بنجاح', backgroundColor: const Color(0xFF10b981), colorText: Colors.white, margin: const EdgeInsets.all(16));
  }

  @override
  Widget build(BuildContext context) {
    bool isDelivering = widget.order['status'] == 'shipped';

    return Scaffold(
      body: Stack(
        children: [
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
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 15)],
                        ),
                        child: const Icon(LucideIcons.navigation, color: Colors.white, size: 24),
                      ),
                    ),
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

          // Back button
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

          // Locate me button
          if (_driverLocation != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  _mapController.move(_driverLocation!, 15.0);
                },
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
                      ),
                      child: Icon(isLocating ? Icons.hourglass_top : LucideIcons.crosshair, color: const Color(0xFF3B82F6), size: 22),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom sheet
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
                          onPressed: _callCustomer,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: const Color(0xFF10b981),
                            side: const BorderSide(color: Color(0xFF10b981)),
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
                      child: ElevatedButton.icon(
                        onPressed: _confirmDelivery,
                        icon: const Icon(LucideIcons.checkCircle, size: 20),
                        label: const Text('تأكيد تسليم الطلب للعميل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
      ),
    );
  }
}
