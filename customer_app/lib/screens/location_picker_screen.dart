import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  MapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  static const LatLng _baghdadCenter = LatLng(33.3128, 44.3615);
  LatLng _cameraTarget = _baghdadCenter;

  String _address = 'اسحب الخريطة لتحديد موقعك';
  bool _isLoadingAddress = false;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineAndGoToInitialLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _determineAndGoToInitialLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final userLoc = LatLng(position.latitude, position.longitude);
        _cameraTarget = userLoc;
        _userLocation = userLoc;
        _mapController?.move(userLoc, 16.5);
      } else {
        _geocodePosition(_cameraTarget);
      }
    } catch (_) {
      _geocodePosition(_cameraTarget);
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'تنبيه',
          'يرجى تفعيل صلاحية الموقع',
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController?.move(
        LatLng(position.latitude, position.longitude),
        16.5,
      );
    } catch (_) {}
  }

  Future<void> _geocodePosition(LatLng position) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAddress = true;
      _address = 'جاري جلب العنوان...';
    });

    try {
      try {
        setLocaleIdentifier('ar');
      } catch (_) {}

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[
          if (place.street != null &&
              place.street!.isNotEmpty &&
              !place.street!.contains('+') &&
              !place.street!.contains('Unnamed'))
            place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty)
            place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality!,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea!,
        ];
        if (mounted) {
          setState(() {
            _address =
                parts.isNotEmpty ? parts.join('، ') : 'شارع غير معروف';
            _isLoadingAddress = false;
          });
        }
        return;
      }
    } catch (_) {}

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&accept-language=ar'));
      request.headers.set(HttpHeaders.userAgentHeader, 'KiwiApp/1.0');
      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final json = jsonDecode(content);
        final address = json['address'];
        if (address != null) {
          final road = address['road'] ??
              address['suburb'] ??
              address['neighbourhood'] ??
              '';
          final city = address['city'] ??
              address['town'] ??
              address['governorate'] ??
              'بغداد';
          if (mounted) {
            setState(() {
              _address = road.isNotEmpty ? '$city، $road' : city;
              _isLoadingAddress = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _address =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoadingAddress = true;
      _address = 'جاري البحث...';
    });
    FocusScope.of(context).unfocus();

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        _mapController?.move(
          LatLng(loc.latitude, loc.longitude),
          16.5,
        );
        return;
      }
    } catch (_) {}

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=1&accept-language=ar'));
      request.headers.set(HttpHeaders.userAgentHeader, 'KiwiApp/1.0');
      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final json = jsonDecode(content);
        if (json is List && json.isNotEmpty) {
          _mapController?.move(
            LatLng(
                double.parse(json[0]['lat']),
                double.parse(json[0]['lon'])),
            16.5,
          );
          return;
        }
      }
    } catch (_) {
      Get.snackbar(
        'عذراً',
        'لم نتمكن من العثور على الموقع',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.background,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Solid background while map loads
            Container(color: isDark ? AppTheme.backgroundDark : AppTheme.background),
            // Map
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _cameraTarget,
                  initialZoom: 15.0,
                  onMapEvent: (event) {
                    if (event is MapEventMoveEnd) {
                      _cameraTarget = event.camera.center;
                      _geocodePosition(_cameraTarget);
                    }
                  },
                  onTap: (tapPosition, point) {},
                ),
                mapController: _mapController,
                children: [
                  TileLayer(
                    urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fresh.customer',
                  ),
                  if (_userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation!,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B82F6),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x803B82F6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Center Pin - Fixed in exact center of screen
            IgnorePointer(
              child: Center(
                child: Image.asset(
                  'assets/images/kiwiq.png',
                  width: 56,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.location_on,
                    color: AppTheme.primary,
                    size: 64,
                  ),
                ),
              ),
            ),

            // Search bar
            Positioned(
              top: topPadding + 16,
              left: 20,
              right: 20,
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.surfaceDark : Colors.white)
                      .withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.grey,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textDirection: TextDirection.rtl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _searchAddress,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن حي، شارع...',
                          hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primary,
                      ),
                      onPressed: () =>
                          _searchAddress(_searchController.text),
                    ),
                  ],
                ),
              ),
            ),

            // Current location FAB — right side, higher, more visible
            Positioned(
              bottom: 200,
              right: 16,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  onPressed: _goToCurrentLocation,
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Bottom card
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      'موقع التوصيل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _address,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Cairo',
                                  height: 1.5,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_isLoadingAddress)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<
                                          Color>(AppTheme.primary),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isLoadingAddress ||
                                _address == 'جاري جلب العنوان...' ||
                                _address == 'جاري البحث...')
                            ? null
                            : () {
                                Navigator.pop(context, {
                                  'latitude': _cameraTarget.latitude,
                                  'longitude': _cameraTarget.longitude,
                                  'address': _address,
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.primary.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'تأكيد الموقع',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
