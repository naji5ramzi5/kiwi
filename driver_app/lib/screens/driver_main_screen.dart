import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart' show fcmNavigateToOrders;
import 'widgets/driver_app_bar.dart';
import 'widgets/driver_home_tab.dart';
import 'widgets/driver_earnings_tab.dart';
import 'widgets/driver_history_tab.dart';
import 'widgets/driver_settings_tab.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  final supabase = Supabase.instance.client;
  bool isOnline = true;
  List<Map<String, dynamic>> activeOrders = [];
  List<Map<String, dynamic>> historyOrders = [];
  bool isLoading = true;
  Map<String, dynamic>? driverProfile;
  String avgRating = 'جديد';
  int totalRatings = 0;
  int deliveryCount = 0;
  double totalEarnings = 0;
  int _currentTab = 0;
  Timer? _locationTimer;
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _assignmentsChannel;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndOrders();
    _setupRealtime();
    // Listen for FCM navigation signals (foreground, background tap, cold start)
    fcmNavigateToOrders.addListener(_onFcmNavigate);
  }

  void _onFcmNavigate() {
    if (fcmNavigateToOrders.value) {
      setState(() => _currentTab = 0);
      _refreshAll();
      // Reset so it can fire again
      fcmNavigateToOrders.value = false;
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    if (_ordersChannel != null) {
      supabase.removeChannel(_ordersChannel!);
    }
    if (_assignmentsChannel != null) {
      supabase.removeChannel(_assignmentsChannel!);
    }
    fcmNavigateToOrders.removeListener(_onFcmNavigate);
    super.dispose();
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateLocation(),
    );
    _updateLocation();
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _updateLocation() async {
    if (!isOnline || supabase.auth.currentUser == null) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await supabase.from('drivers').upsert({
        'id': supabase.auth.currentUser!.id,
        'last_location_lat': pos.latitude,
        'last_location_lng': pos.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('Location update error: $e');
    }
  }

  Future<void> _fetchProfileAndOrders() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      setState(() {
        driverProfile = profile;
        isOnline = profile['is_online'] ?? false;
      });
      _fetchRating(user.id);
      _fetchEarnings(user.id);
    }
    await fetchOrders();
    await fetchHistory();
  }

  Future<void> _fetchRating(String driverId) async {
    try {
      final result = await supabase
          .from('driver_ratings')
          .select('rating')
          .eq('driver_id', driverId);
      if (result is List && result.isNotEmpty) {
        final ratings = result
            .map((e) => (e['rating'] as num).toDouble())
            .toList();
        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        setState(() {
          avgRating = avg.toStringAsFixed(1);
          totalRatings = ratings.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchEarnings(String driverId) async {
    try {
      final delivered = await supabase
          .from('orders')
          .select('delivery_fee')
          .eq('driver_id', driverId)
          .eq('status', 'delivered');
      if (delivered is List) {
        double total = 0;
        for (var o in delivered) {
          total += (o['delivery_fee'] as num?)?.toDouble() ?? 0;
        }
        setState(() {
          deliveryCount = delivered.length;
          totalEarnings = total;
        });
      }
    } catch (_) {}
  }

  void _setupRealtime() {
    final driverId = supabase.auth.currentUser?.id;
    if (driverId == null) return;

    // Subscribe to order changes relevant to this driver
    _ordersChannel = supabase
        .channel('driver-orders-$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (payload) {
            fetchOrders();
            fetchHistory();
            if (driverProfile != null) _fetchEarnings(driverProfile!['id']);
          },
        )
        .subscribe();

    // Also listen for new orders assigned to this driver (status changes to 'picked_up')
    _assignmentsChannel = supabase
        .channel('driver-assignments-$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (payload) {
            fetchOrders();
            if (driverProfile != null) _fetchEarnings(driverProfile!['id']);
          },
        )
        .subscribe();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await supabase
          .from('orders')
          .select()
          .inFilter('status', ['shipped', 'picked_up'])
          .eq('driver_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
      setState(() {
        activeOrders = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Orders error: $e');
    }
  }

  Future<void> fetchHistory() async {
    try {
      final response = await supabase
          .from('orders')
          .select()
          .inFilter('status', ['delivered'])
          .eq('driver_id', supabase.auth.currentUser!.id)
          .order('updated_at', ascending: false)
          .limit(50);
      setState(() {
        historyOrders = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('History error: $e');
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => isOnline = value);
    await supabase
        .from('profiles')
        .update({'is_online': value})
        .eq('id', supabase.auth.currentUser!.id);
    if (value) {
      _startLocationTracking();
      Get.snackbar(
        'أنت متصل الآن',
        'مستعد لتلقي الطلبات',
        backgroundColor: const Color(0xFF10b981),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } else {
      _stopLocationTracking();
    }
  }

  void _refreshAll() {
    fetchOrders();
    fetchHistory();
    if (driverProfile != null) _fetchEarnings(driverProfile!['id']);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DriverHomeTab(
        isOnline: isOnline,
        isLoading: isLoading,
        activeOrders: activeOrders,
        avgRating: avgRating,
        totalRatings: totalRatings,
        onRefresh: _refreshAll,
      ),
      DriverEarningsTab(
        totalEarnings: totalEarnings,
        deliveryCount: deliveryCount,
        avgRating: avgRating,
        totalRatings: totalRatings,
      ),
      DriverHistoryTab(historyOrders: historyOrders),
      DriverSettingsTab(driverProfile: driverProfile),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: DriverAppBar(
        driverProfile: driverProfile,
        isOnline: isOnline,
        onToggleOnline: _toggleOnline,
      ),
      body: screens[_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF10b981),
        unselectedItemColor: Colors.grey.shade400,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.wallet),
            label: 'الأرباح',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.clock),
            label: 'السجل',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
