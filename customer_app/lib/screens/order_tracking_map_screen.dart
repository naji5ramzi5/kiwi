import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class OrderTrackingMapScreen extends StatefulWidget {
  const OrderTrackingMapScreen({super.key});

  @override
  State<OrderTrackingMapScreen> createState() => _OrderTrackingMapScreenState();
}

class _OrderTrackingMapScreenState extends State<OrderTrackingMapScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  static const LatLng _customerPos = LatLng(33.3152, 44.3661);
  LatLng _driverPos = const LatLng(33.3052, 44.3561);
  
  BitmapDescriptor? _scooterIcon;
  
  late AnimationController _moveController;
  late Animation<double> _latAnim;
  late Animation<double> _lngAnim;

  final String _mapStyle = '''
  [
    { "elementType": "geometry", "stylers": [ { "color": "#ffffff" } ] },
    { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
    { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#f0fdf4" } ] },
    { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#dcfce7" } ] },
    { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#ecfdf5" } ] },
    { "featureType": "poi.park", "elementType": "geometry", "stylers": [ { "color": "#f0fdf4" } ] }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _moveController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    
    Timer(const Duration(seconds: 2), () {
      _simulateMovement(const LatLng(33.3140, 44.3650));
    });
  }

  Future<void> _loadIcons() async {
    final Uint8List markerIcon = await getBytesFromAsset('assets/images/scooter.png', 100);
    setState(() {
      _scooterIcon = BitmapDescriptor.fromBytes(markerIcon);
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    try {
      ByteData data = await rootBundle.load(path);
      ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
      ui.FrameInfo fi = await codec.getNextFrame();
      return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    } catch (e) {
      return Uint8List(0);
    }
  }

  void _simulateMovement(LatLng newPos) {
    _latAnim = Tween<double>(begin: _driverPos.latitude, end: newPos.latitude).animate(_moveController);
    _lngAnim = Tween<double>(begin: _driverPos.longitude, end: newPos.longitude).animate(_moveController);
    _moveController.forward();
    _moveController.addListener(() {
      setState(() {
        _driverPos = LatLng(_latAnim.value, _lngAnim.value);
      });
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _driverPos, zoom: 15),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              controller.setMapStyle(_mapStyle);
            },
            markers: {
              Marker(
                markerId: const MarkerId('driver'),
                position: _driverPos,
                icon: _scooterIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                rotation: 45,
                anchor: const Offset(0.5, 0.5),
              ),
              const Marker(
                markerId: MarkerId('customer'),
                position: _customerPos,
                icon: BitmapDescriptor.defaultMarker,
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: [_driverPos, _customerPos],
                color: const Color(0xFF10B981),
                width: 6,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            },
          ),
          
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: const Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(LucideIcons.bike, color: Color(0xFF10B981), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المندوب في الطريق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                            Text('الوصول المتوقع: 8 دقائق', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProgressLine(2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(int currentStep) {
    final steps = ['تأكيد', 'تجهيز', 'في الطريق', 'وصلنا'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 4, color: index == 0 ? Colors.transparent : (isActive ? AppTheme.primary : Colors.grey[200]))),
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(color: isActive ? AppTheme.primary : Colors.grey[200], shape: BoxShape.circle),
                  ),
                  Expanded(child: Container(height: 4, color: index == steps.length - 1 ? Colors.transparent : (index < currentStep ? AppTheme.primary : Colors.grey[200]))),
                ],
              ),
              const SizedBox(height: 8),
              Text(steps[index], style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppTheme.primary : Colors.grey)),
            ],
          ),
        );
      }),
    );
  }
}
