import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../services/ops_api.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<LiveOrder>? _orders;
  List<Map<String, dynamic>>? _branches;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      OpsApi.fetchLiveOrders(statuses: ['pending', 'picked_up', 'on_the_way', 'accepted']),
      OpsApi.fetchBranches(),
    ]);
    if (!mounted) return;
    setState(() {
      _orders = results[0] as List<LiveOrder>;
      _branches = results[1] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الخريطة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(33.3152, 44.3661),
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kiwi.operations',
                maxNativeZoom: 19,
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  ...?_branches?.where((b) {
                    final lat = double.tryParse(b['latitude']?.toString() ?? '');
                    final lng = double.tryParse(b['longitude']?.toString() ?? '');
                    return lat != null && lng != null;
                  }).map((b) {
                    return Marker(
                      point: LatLng(
                        double.tryParse(b['latitude'].toString())!,
                        double.tryParse(b['longitude'].toString())!,
                      ),
                      width: 46,
                      height: 46,
                      child: GestureDetector(
                        onTap: () => _showBranchSheet(b),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.3),
                                  blurRadius: 10)
                            ],
                          ),
                          child: const Icon(Icons.store, color: Colors.white, size: 22),
                        ),
                      ),
                    );
                  }),
                  ...?_orders?.where((o) => o.lat != null && o.lng != null).map((o) {
                    return Marker(
                      point: LatLng(o.lat!, o.lng!),
                      width: 42,
                      height: 42,
                      child: GestureDetector(
                        onTap: () => _showOrderBottomSheet(o),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _statusColor(o.status),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: _statusColor(o.status).withOpacity(0.4),
                                  blurRadius: 12)
                            ],
                          ),
                          child: const Icon(Icons.local_shipping_outlined,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFf59e0b);
      case 'picked_up':
        return const Color(0xFF3b82f6);
      case 'on_the_way':
        return const Color(0xFF8b5cf6);
      case 'accepted':
        return const Color(0xFF0ea5e9);
      default:
        return const Color(0xFF10b981);
    }
  }

  void _showOrderBottomSheet(LiveOrder o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(o.orderNumber,
                      style: GoogleFonts.cairo(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(o.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_statusLabel(o.status),
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: _statusColor(o.status))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(Icons.person_outline, o.customerName ?? 'عميل مباشر'),
              _infoRow(Icons.place_outlined, o.address ?? '—'),
              _infoRow(Icons.store_outlined, o.branchName ?? '—'),
              _infoRow(Icons.local_shipping_outlined, o.driverName ?? 'غير معين'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.cairo(fontSize: 13))),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'معلق';
      case 'picked_up':
        return 'تم الاستلام';
      case 'on_the_way':
        return 'في الطريق';
      case 'accepted':
        return 'تم القبول';
      default:
        return s;
    }
  }

  void _showBranchSheet(Map<String, dynamic> b) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b['name']?.toString() ?? '',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _infoRow(Icons.info_outline, b['status']?.toString() ?? '—'),
            _infoRow(Icons.place_outlined, b['address']?.toString() ?? '—'),
          ],
        ),
      ),
    );
  }
}