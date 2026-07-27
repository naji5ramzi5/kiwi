import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import 'widgets/location_search_bar.dart';
import 'widgets/location_confirm_button.dart';
import 'widgets/map_widget.dart';

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

  String _address = 'choose_area'.tr;
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
          'warning'.tr,
          'enable_location'.tr,
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
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&accept-language=ar',
        ),
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'KiwiApp/1.0');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);

      if (mounted) {
        setState(() {
          _address = data['display_name'] ?? 'العنوان غير معروف';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('[Geocode] Error: $e');
      if (mounted) {
        setState(() {
          _address = 'العنوان غير معروف';
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoadingAddress = true;
      _address = 'searching'.tr;
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
        'cancel'.tr,
        'could_not_get_location'.tr,
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
            Container(color: isDark ? AppTheme.backgroundDark : AppTheme.background),
            Positioned.fill(
              child: LocationMapWidget(
                mapController: _mapController!,
                cameraTarget: _cameraTarget,
                userLocation: _userLocation,
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd) {
                    _cameraTarget = event.camera.center;
                    _geocodePosition(_cameraTarget);
                  }
                },
              ),
            ),

            // Center Pin
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
              child: LocationSearchBar(
                controller: _searchController,
                onBack: () => Navigator.pop(context),
                onSearch: () => _searchAddress(_searchController.text),
              ),
            ),

            // Current location FAB
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
              child: LocationConfirmButton(
                address: _address,
                isLoading: _isLoadingAddress,
                cameraTarget: _cameraTarget,
                onConfirm: () {
                  Navigator.pop(context, {
                    'latitude': _cameraTarget.latitude,
                    'longitude': _cameraTarget.longitude,
                    'address': _address,
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
