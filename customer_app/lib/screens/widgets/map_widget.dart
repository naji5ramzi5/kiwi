import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';

class LocationMapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng cameraTarget;
  final LatLng? userLocation;
  final Function(MapEvent) onMapEvent;

  const LocationMapWidget({
    super.key,
    required this.mapController,
    required this.cameraTarget,
    this.userLocation,
    required this.onMapEvent,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: cameraTarget,
        initialZoom: 15.0,
        onMapEvent: onMapEvent,
        onTap: (tapPosition, point) {},
      ),
      mapController: mapController,
      children: [
        TileLayer(
          urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fresh.customer',
        ),
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation!,
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
    );
  }
}
