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
  RealtimeChannel? _employeeChannel;
  RealtimeChannel? _branchOrdersChannel;
  String? branchName;
  String? driverBranchId;
  int dailyDeliveries = 0;
  int monthlyDeliveries = 0;
  double todayEarnings = 0;
  double monthlyEarnings = 0;
  String? joinedAt;
  int employeeTotalDeliveries = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndOrders();
    _setupRealtime();
    fcmNavigateToOrders.addListener(_onFcmNavigate);
  }

  void _onFcmNavigate() {
    if (fcmNavigateToOrders.value) {
      setState(() => _currentTab = 0);
      _refreshAll();
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
    if (_employeeChannel != null) {
      supabase.removeChannel(_employeeChannel!);
    }
    if (_branchOrdersChannel != null) {
      supabase.removeChannel(_branchOrdersChannel!);
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
      // Fetch delivery employee record with branch info
      await _fetchDeliveryEmployeeInfo(user.id);
      _fetchRating(user.id);
      _fetchEarnings(user.id);
    }
    await fetchOrders();
    await fetchHistory();
  }

  Future<void> _fetchDeliveryEmployeeInfo(String userId) async {
    try {
      final emp = await supabase
          .from('delivery_employees')
          .select('branch_id, status, total_deliveries, joined_at, branches!inner(name)')
          .eq('user_id', userId)
          .maybeSingle();
      if (emp != null) {
        final branchId = emp['branch_id']?.toString();
        setState(() {
          branchName = emp['branches']?['name'] as String?;
          driverBranchId = branchId;
          joinedAt = emp['joined_at']?.toString();
          employeeTotalDeliveries = (emp['total_deliveries'] as num?)?.toInt() ?? 0;
        });
        if (branchId != null) {
          _setupBranchOrdersRealtime(branchId);
        }
      }
    } catch (e) {
      debugPrint('Error fetching delivery employee info: $e');
    }
    // Fallback: try profiles.branch_id
    if (branchName == null && driverProfile != null && driverProfile!['branch_id'] != null) {
      try {
        final branch = await supabase
            .from('branches')
            .select('name')
            .eq('id', driverProfile!['branch_id'])
            .maybeSingle();
        if (branch != null) {
          setState(() {
            branchName = branch['name'] as String?;
            driverBranchId = driverProfile!['branch_id']?.toString();
          });
          final bid = driverBranchId;
          if (bid != null) {
            _setupBranchOrdersRealtime(bid);
          }
        }
      } catch (_) {}
    }
  }

  // Listen for ANY new/updated order in the driver's branch so the card
  // renders the instant the FCM notification arrives — even before the
  // order has been assigned to this driver.
  void _setupBranchOrdersRealtime(String branchId) {
    if (_branchOrdersChannel != null) return;
    _branchOrdersChannel = supabase
        .channel('driver-branch-orders-$branchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'branch_id',
            value: branchId,
          ),
          callback: (payload) {
            fetchOrders();
          },
        )
        .subscribe();
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

  Future<void> _fetchEarnings(String userId) async {
    try {
      // Read earnings from the delivery_earnings ledger (source of truth).
      final empId = await _myEmployeeId();
      if (empId == null) return;
      final earned = await supabase
          .from('delivery_earnings')
          .select('amount, created_at')
          .eq('delivery_employee_id', empId);
      if (earned is List) {
        double total = 0;
        int daily = 0;
        int monthly = 0;
        double dailyAmount = 0;
        double monthlyAmount = 0;
        final now = DateTime.now();
        for (var o in earned) {
          final amount = (o['amount'] as num?)?.toDouble() ?? 0;
          total += amount;
          if (o['created_at'] != null) {
            final d = DateTime.tryParse(o['created_at'].toString());
            if (d != null) {
              if (d.year == now.year && d.month == now.month && d.day == now.day) {
                daily++;
                dailyAmount += amount;
              }
              if (d.year == now.year && d.month == now.month) {
                monthly++;
                monthlyAmount += amount;
              }
            }
          }
        }
        setState(() {
          deliveryCount = earned.length;
          totalEarnings = total;
          dailyDeliveries = daily;
          monthlyDeliveries = monthly;
          todayEarnings = dailyAmount;
          monthlyEarnings = monthlyAmount;
        });
      }
    } catch (_) {}
  }

  Future<String?> _myEmployeeId() async {
    try {
      final emp = await supabase
          .from('delivery_employees')
          .select('id')
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();
      return emp?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  void _setupRealtime() {
    final driverId = supabase.auth.currentUser?.id;
    if (driverId == null) return;

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

    // Real-time subscription for delivery_employees (branch changes, status)
    _employeeChannel = supabase
        .channel('driver-employee-$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'delivery_employees',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: driverId,
          ),
          callback: (payload) {
            if (driverProfile != null) {
              _fetchDeliveryEmployeeInfo(driverProfile!['id']);
            }
          },
        )
        .subscribe();
  }

  Future<void> fetchOrders() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      // Orders assigned to me (active work) PLUS new/unassigned orders
      // that belong to my branch zone so they render the moment the
      // FCM notification arrives. Branch zone is optional (driver may
      // not be assigned to a branch yet).
      final zoneCond = driverBranchId != null
          ? 'and(status.in.(pending,preparing,prepared,ready),branch_id.eq.$driverBranchId),'
          : '';
      final query = supabase
          .from('orders')
          .select()
          .or(
            '${zoneCond}and(driver_id.eq.$userId,status.in.(shipped,picked_up,assigned,ready,preparing,prepared))',
          )
          .order('created_at', ascending: false);
      final response = await query;
      setState(() {
        activeOrders = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Orders error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
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
    // Also update delivery_employees status
    await supabase
        .from('delivery_employees')
        .update({'status': value ? 'online' : 'offline'})
        .eq('user_id', supabase.auth.currentUser!.id);
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
    if (driverProfile != null) {
      _fetchEarnings(driverProfile!['id']);
      _fetchDeliveryEmployeeInfo(driverProfile!['id']);
    }
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
        dailyDeliveries: dailyDeliveries,
        monthlyDeliveries: monthlyDeliveries,
      ),
      DriverEarningsTab(
        totalEarnings: totalEarnings,
        deliveryCount: deliveryCount,
        avgRating: avgRating,
        totalRatings: totalRatings,
        dailyDeliveries: dailyDeliveries,
        monthlyDeliveries: monthlyDeliveries,
        todayEarnings: todayEarnings,
        monthlyEarnings: monthlyEarnings,
      ),
      DriverHistoryTab(historyOrders: historyOrders),
      DriverSettingsTab(
        driverProfile: driverProfile,
        branchName: branchName,
        joinedAt: joinedAt,
        employeeTotalDeliveries: employeeTotalDeliveries,
        isOnline: isOnline,
        totalEarnings: totalEarnings,
        dailyDeliveries: dailyDeliveries,
        monthlyDeliveries: monthlyDeliveries,
        todayEarnings: todayEarnings,
        monthlyEarnings: monthlyEarnings,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: DriverAppBar(
        driverProfile: driverProfile,
        isOnline: isOnline,
        onToggleOnline: _toggleOnline,
        branchName: branchName,
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
