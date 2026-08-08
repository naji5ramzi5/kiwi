import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ops_api.dart';
import 'employee_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<DeliveryEmployeeModel>? _drivers;
  List<Map<String, dynamic>>? _branches;
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _branchFilter; // branch id
  String? _statusFilter; // online | offline | all
  RealtimeChannel? _channel;

  static const LatLng _baghdad = LatLng(33.3152, 44.3661);

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('ops_map_drivers')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'drivers',
          callback: (payload) {
            // تحديث جزئي: نعيد جلب بيانات الخريطة فقط (خفيف، ليس الصفحة كلها)
            if (!mounted) return;
            _load(quiet: true);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            if (!mounted) return;
            _load(quiet: true);
          },
        )
        .subscribe();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        OpsApi.fetchDriverLocations(),
        OpsApi.fetchBranches(),
      ]);
      if (!mounted) return;
      setState(() {
        _drivers = results[0] as List<DeliveryEmployeeModel>;
        _branches = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is OpsApiException ? e.message : 'تعذر تحميل الخريطة';
        _loading = false;
      });
    }
  }

  List<DeliveryEmployeeModel> get _filtered {
    final drivers = _drivers ?? const [];
    return drivers.where((d) {
      if (_branchFilter != null && d.branchId != _branchFilter) return false;
      if (_statusFilter == 'online' && !d.isOnline) return false;
      if (_statusFilter == 'offline' && d.isOnline) return false;
      if (_query.trim().isNotEmpty) {
        final q = _query.trim().toLowerCase();
        if (!d.fullName.toLowerCase().contains(q) &&
            !d.phone.contains(_query.trim())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get _onlineCount =>
      (_drivers ?? []).where((d) => d.isOnline).length;

  Color _statusColor(String s) {
    switch (s) {
      case 'online':
        return const Color(0xFF10b981);
      case 'offline':
        return const Color(0xFF94a3b8);
      default:
        return const Color(0xFF94a3b8);
    }
  }

  void _fitVisibleDrivers() {
    final withLoc = _filtered.where((d) => d.lastLat != null && d.lastLng != null).toList();
    if (withLoc.isEmpty) {
      _mapController.move(_baghdad, 12);
      return;
    }
    final lats = withLoc.map((d) => d.lastLat!).toList();
    final lngs = withLoc.map((d) => d.lastLng!).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(60),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fit',
            tooltip: 'عرض كل المندوبين',
            onPressed: _fitVisibleDrivers,
            child: const Icon(Icons.fit_screen_outlined),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            tooltip: 'تكبير',
            onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            tooltip: 'تصغير',
            onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'locate',
            tooltip: 'الموقع الافتراضي',
            onPressed: () => _mapController.move(_baghdad, 12),
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'بحث عن مندوب...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _filtersRow(),
              ],
            ),
          ),
          Expanded(child: _mapArea()),
        ],
      ),
    );
  }

  Widget _filtersRow() {
    final branches = _branches ?? const [];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('الكل', _branchFilter == null && _statusFilter == null, () {
            setState(() {
              _branchFilter = null;
              _statusFilter = null;
            });
          }),
          const SizedBox(width: 6),
          _chip('متصل ($_onlineCount)', _statusFilter == 'online', () {
            setState(() => _statusFilter = _statusFilter == 'online' ? null : 'online');
          }),
          const SizedBox(width: 6),
          _chip('غير متصل', _statusFilter == 'offline', () {
            setState(() => _statusFilter = _statusFilter == 'offline' ? null : 'offline');
          }),
          const SizedBox(width: 6),
          ...branches.map((b) {
            final id = b['id'].toString();
            final name = b['name']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _chip(name, _branchFilter == id, () {
                setState(() => _branchFilter = _branchFilter == id ? null : id);
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10b981) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF10b981) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _mapArea() {
    if (_loading && _drivers == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _drivers == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Colors.grey),
            const SizedBox(height: 10),
            Text(_error!, style: GoogleFonts.cairo(fontSize: 13)),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final drivers = _filtered;
    final withLoc = drivers.where((d) => d.lastLat != null && d.lastLng != null).toList();
    final branches = _branches ?? const [];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _baghdad,
            initialZoom: 12,
            minZoom: 3,
            maxZoom: 19,
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
                ...branches.where((b) {
                  final lat = double.tryParse(b['latitude']?.toString() ?? '');
                  final lng = double.tryParse(b['longitude']?.toString() ?? '');
                  return lat != null && lng != null;
                }).map((b) {
                  return Marker(
                    point: LatLng(
                      double.parse(b['latitude'].toString()),
                      double.parse(b['longitude'].toString()),
                    ),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showBranchSheet(b),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.3), blurRadius: 10),
                          ],
                        ),
                        child: const Icon(Icons.store, color: Colors.white, size: 20),
                      ),
                    ),
                  );
                }),
                ...withLoc.map((d) {
                  final color = _statusColor(d.onlineStatus);
                  return Marker(
                    point: LatLng(d.lastLat!, d.lastLng!),
                    width: 46,
                    height: 46,
                    child: GestureDetector(
                      onTap: () => _showDriverSheet(d),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(color: color.withOpacity(0.45), blurRadius: 12),
                              ],
                            ),
                            child: Text(
                              d.fullName.isEmpty ? '؟' : d.fullName.substring(0, 1),
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (d.currentOrderNo != null && d.currentOrderNo!.isNotEmpty)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFf59e0b),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.local_shipping, color: Colors.white, size: 9),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        if (withLoc.isEmpty && !_loading)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                  ],
                ),
                child: Text(
                  'لا توجد مواقع مندوبين مطابقة للفلترة',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showDriverSheet(DeliveryEmployeeModel d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF10b981).withOpacity(0.12),
                  child: Text(
                    d.fullName.isEmpty ? '؟' : d.fullName.substring(0, 1),
                    style: GoogleFonts.cairo(color: const Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.fullName, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        '${d.branchName.isEmpty ? '' : d.branchName} • ${d.vehicleLabel}',
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (d.isOnline ? const Color(0xFF10b981) : const Color(0xFF94a3b8)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    d.isOnline ? 'متصل' : 'غير متصل',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: d.isOnline ? const Color(0xFF10b981) : const Color(0xFF94a3b8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('المركبة', d.vehicleLabel),
            if ((d.currentOrderNo ?? '').isNotEmpty) ...[
              _detailRow('الطلب الحالي', '#${d.currentOrderNo}'),
              _detailRow('حالة الطلب', d.currentOrderStatus ?? '—'),
              if ((d.currentCustomerName ?? '').isNotEmpty)
                _detailRow('العميل', d.currentCustomerName!),
            ] else
              _detailRow('الحالة', 'متاح — لا يوجد طلب نشط'),
            _detailRow('آخر تحديث للموقع', _locationDetail(d)),
            _detailRow('توصيلات اليوم', '${d.todayDeliveries}'),
            _detailRow('أرباح اليوم', NumberFormat('#,##0 د.ع').format(d.todayEarnings)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10b981)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmployeeDetailsScreen(employee: d)),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: Text('عرض المندوب', style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: d.phone.isEmpty
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _callDriver(d.phone);
                          },
                    icon: const Icon(Icons.phone, size: 16),
                    label: Text('اتصال', style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _locationDetail(DeliveryEmployeeModel d) {
    final t = d.locationUpdatedAt;
    if (t == null) return 'غير معروف';
    final diff = DateTime.now().difference(t.toLocal());
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    return DateFormat('HH:mm').format(t.toLocal());
  }

  void _callDriver(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اتصال بالمندوب', style: GoogleFonts.cairo(fontSize: 16)),
        content: Text(digits.isEmpty ? phone : digits, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
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
            Text(b['name']?.toString() ?? '', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _detailRow('الحالة', b['status']?.toString() ?? '—'),
            _detailRow('العنوان', b['address']?.toString() ?? '—'),
          ],
        ),
      ),
    );
  }
}