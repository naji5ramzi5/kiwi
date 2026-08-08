import 'package:supabase_flutter/supabase_flutter.dart';

/// خطأ قابل للعرض — رسالة عربية واضحة بدل الاستثناءات الخام
class OpsApiException implements Exception {
  final String message;
  const OpsApiException(this.message);

  @override
  String toString() => message;
}

class OpsDashboard {
  final int deliveredToday;
  final int pendingOrders;
  final int activeEmployees;
  final int onlineEmployees;
  final int pendingApprovals;
  final double totalEarningsToday;
  final int totalBranches;
  final double avgDeliveryFee;

  OpsDashboard({
    required this.deliveredToday,
    required this.pendingOrders,
    required this.activeEmployees,
    required this.onlineEmployees,
    required this.pendingApprovals,
    required this.totalEarningsToday,
    required this.totalBranches,
    required this.avgDeliveryFee,
  });
}

class BranchSummary {
  final String id;
  final String name;
  final String? status;
  final int delivered;
  final int employees;
  final double earnings;

  BranchSummary({
    required this.id,
    required this.name,
    this.status,
    required this.delivered,
    required this.employees,
    required this.earnings,
  });
}

/// نموذج Typed كامل لمندوب التوصيل — لا يُعرض أي Map خام في الواجهة أبداً
class DeliveryEmployeeModel {
  final String id; // delivery_employees.id (employee_id)
  final String? userId; // profiles.id (auth user)
  final String fullName;
  final String phone;
  final String email;
  final String vehicleType;
  final String? branchId;
  final String branchName;
  final String onlineStatus; // online | offline
  final bool isActive;
  final bool isApproved;
  final DateTime? joinedAt;
  final DateTime? lastActiveAt;
  final int totalDeliveries;
  final int todayDeliveries;
  final int monthDeliveries;
  final double walletBalance;
  final double todayEarnings;
  final double monthEarnings;
  final double totalEarnings;

  // بيانات الخريطة الحية (من ops_driver_locations)
  final double? lastLat;
  final double? lastLng;
  final DateTime? locationUpdatedAt;
  final String? currentOrderId;
  final String? currentOrderNo;
  final String? currentOrderStatus;
  final String? currentCustomerName;

  const DeliveryEmployeeModel({
    required this.id,
    this.userId,
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.vehicleType = '',
    this.branchId,
    this.branchName = '',
    this.onlineStatus = 'offline',
    this.isActive = true,
    this.isApproved = true,
    this.joinedAt,
    this.lastActiveAt,
    this.totalDeliveries = 0,
    this.todayDeliveries = 0,
    this.monthDeliveries = 0,
    this.walletBalance = 0,
    this.todayEarnings = 0,
    this.monthEarnings = 0,
    this.totalEarnings = 0,
    this.lastLat,
    this.lastLng,
    this.locationUpdatedAt,
    this.currentOrderId,
    this.currentOrderNo,
    this.currentOrderStatus,
    this.currentCustomerName,
  });

  bool get isOnline => onlineStatus == 'online';

  static double _d(Map<String, dynamic> m, String key) =>
      double.tryParse(m[key]?.toString() ?? '') ?? 0;

  static int _i(Map<String, dynamic> m, String key) =>
      int.tryParse(m[key]?.toString() ?? '') ?? 0;

  factory DeliveryEmployeeModel.fromReport(Map<String, dynamic> m) =>
      DeliveryEmployeeModel(
        id: m['id']?.toString() ?? '',
        userId: m['user_id']?.toString(),
        fullName: m['full_name']?.toString() ?? '',
        phone: m['phone']?.toString() ?? '',
        email: m['email']?.toString() ?? '',
        vehicleType: m['vehicle_type']?.toString() ?? '',
        branchId: m['branch_id']?.toString(),
        branchName: m['branch_name']?.toString() ?? '',
        onlineStatus:
            (m['online_status']?.toString() ?? m['status']?.toString() ?? 'offline')
                .toString(),
        isActive: m['is_active'] == true,
        isApproved: m['account_status'] == true || m['is_approved'] == true,
        joinedAt: DateTime.tryParse(m['joined_at']?.toString() ?? ''),
        lastActiveAt: DateTime.tryParse(m['last_active_at']?.toString() ?? ''),
        totalDeliveries: _i(m, 'total_deliveries'),
        todayDeliveries: _i(m, 'today_deliveries'),
        monthDeliveries: _i(m, 'month_deliveries'),
        walletBalance: _d(m, 'wallet_balance'),
        todayEarnings: _d(m, 'today_earnings'),
        monthEarnings: _d(m, 'month_earnings'),
        totalEarnings: _d(m, 'total_earnings'),
      );

  factory DeliveryEmployeeModel.fromLocation(Map<String, dynamic> m) =>
      DeliveryEmployeeModel(
        id: m['employee_id']?.toString() ?? '',
        userId: m['user_id']?.toString(),
        fullName: m['full_name']?.toString() ?? '',
        phone: m['phone']?.toString() ?? '',
        vehicleType: m['vehicle_type']?.toString() ?? '',
        branchId: m['branch_id']?.toString(),
        branchName: m['branch_name']?.toString() ?? '',
        onlineStatus: m['online_status']?.toString() ?? 'offline',
        isActive: m['is_active'] == true,
        joinedAt: DateTime.tryParse(m['joined_at']?.toString() ?? ''),
        lastActiveAt:
            DateTime.tryParse(m['location_updated']?.toString() ?? ''),
        todayDeliveries: _i(m, 'today_deliveries'),
        todayEarnings: _d(m, 'today_earnings'),
        totalDeliveries: _i(m, 'total_deliveries'),
        lastLat: double.tryParse(m['last_lat']?.toString() ?? ''),
        lastLng: double.tryParse(m['last_lng']?.toString() ?? ''),
        locationUpdatedAt:
            DateTime.tryParse(m['location_updated']?.toString() ?? ''),
        currentOrderId: m['current_order_id']?.toString(),
        currentOrderNo: m['current_order_no']?.toString(),
        currentOrderStatus: m['current_status']?.toString(),
        currentCustomerName: m['customer_name']?.toString(),
      );

  /// عنوان عربي لاسم المركبة
  String get vehicleLabel {
    switch (vehicleType) {
      case 'bike':
        return 'دراجة نارية';
      case 'car':
        return 'سيارة';
      case 'van':
        return 'فان';
      case 'truck':
        return 'شاحنة';
      default:
        return vehicleType.isEmpty ? 'غير محدد' : vehicleType;
    }
  }

  /// عنوان عربي لحالة الحساب
  String get accountStatusLabel {
    if (!isApproved) return 'قيد المراجعة';
    if (!isActive) return 'موقوف';
    return 'نشط';
  }
}

/// توافق للشاشات القديمة التي تستخدم EmployeeRow
typedef EmployeeRow = DeliveryEmployeeModel;

class DeliveredOrder {
  final String id;
  final String orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String? address;
  final double totalAmount;
  final double deliveryFee;
  final String? branchName;
  final String? employeeName;
  final String? vehicleType;
  final DateTime? deliveredAt;
  final String? proofImage;

  DeliveredOrder({
    required this.id,
    required this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.address,
    required this.totalAmount,
    required this.deliveryFee,
    this.branchName,
    this.employeeName,
    this.vehicleType,
    this.deliveredAt,
    this.proofImage,
  });

  factory DeliveredOrder.fromRow(Map<String, dynamic> m) => DeliveredOrder(
        id: m['id']?.toString() ?? '',
        orderNumber: m['order_number']?.toString() ?? '',
        customerName: m['customer_name_manual']?.toString(),
        customerPhone: m['customer_phone']?.toString(),
        address: m['delivery_address']?.toString(),
        totalAmount: double.tryParse(m['total_amount']?.toString() ?? '0') ?? 0,
        deliveryFee: double.tryParse(m['delivery_fee']?.toString() ?? '0') ?? 0,
        branchName: m['branch_name']?.toString(),
        employeeName: m['employee_name']?.toString(),
        vehicleType: m['vehicle_type']?.toString(),
        deliveredAt: DateTime.tryParse(m['delivered_at']?.toString() ?? ''),
        proofImage: m['proof_image']?.toString(),
      );
}

class LiveOrder {
  final String id;
  final String orderNumber;
  final String? customerName;
  final String? phone;
  final String? address;
  final String status;
  final double total;
  final double deliveryFee;
  final String? branchName;
  final String? branchId;
  final String? driverName;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? onTheWayAt;
  final double? lat;
  final double? lng;

  LiveOrder({
    required this.id,
    required this.orderNumber,
    this.customerName,
    this.phone,
    this.address,
    required this.status,
    required this.total,
    required this.deliveryFee,
    this.branchName,
    this.branchId,
    this.driverName,
    this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.onTheWayAt,
    this.lat,
    this.lng,
  });

  factory LiveOrder.fromRow(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? '';
    final number = m['order_number']?.toString();
    return LiveOrder(
        id: id,
        orderNumber:
            number != null && number.isNotEmpty ? number : shortId(id),
        customerName: m['customer_name_manual']?.toString() ??
            m['customer_name']?.toString(),
        phone: m['customer_phone']?.toString(),
        address: m['delivery_address']?.toString(),
        status: m['status']?.toString() ?? '',
        total: double.tryParse(
                m['total_price']?.toString() ?? m['total_amount']?.toString() ?? '0') ??
            0,
        deliveryFee: double.tryParse(m['delivery_fee']?.toString() ?? '0') ?? 0,
        branchName: m['branch_name']?.toString(),
        branchId: m['branch_id']?.toString(),
        driverName:
            m['driver_name']?.toString() ?? m['employee_name']?.toString(),
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
        acceptedAt: DateTime.tryParse(
            m['assigned_at']?.toString() ?? m['accepted_at']?.toString() ?? ''),
        pickedUpAt: DateTime.tryParse(m['picked_up_at']?.toString() ?? ''),
        onTheWayAt: DateTime.tryParse(m['on_the_way_at']?.toString() ?? ''),
        lat: double.tryParse(
            m['delivery_lat']?.toString() ?? m['customer_lat']?.toString() ?? ''),
        lng: double.tryParse(
            m['delivery_lng']?.toString() ?? m['customer_lng']?.toString() ?? ''),
      );
  }

  /// رقم الطلب المعروض: أول 8 خانات من المعرّف (كما في بقية التطبيقات)
  static String shortId(String id) {
    if (id.isEmpty) return '—';
    return id.replaceAll('-', '').substring(0, 8).toUpperCase();
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'معلق';
      case 'preparing':
        return 'قيد التحضير';
      case 'prepared':
      case 'ready':
        return 'جاهز';
      case 'assigned':
      case 'accepted':
        return 'تم تعيينه';
      case 'picked_up':
        return 'تم الاستلام';
      case 'on_the_way':
        return 'في الطريق';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}

class NotificationRow {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  NotificationRow({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationRow.fromRow(Map<String, dynamic> m) => NotificationRow(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        message: m['body']?.toString() ?? m['message']?.toString() ?? '',
        type: m['type']?.toString() ?? 'info',
        isRead: m['is_read'] == true,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
      );
}

class EmployeeDeliveryRecord {
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String branchName;
  final double totalAmount;
  final double deliveryFee;
  final double earnings;
  final String status;
  final DateTime? deliveredAt;
  final String? proofImage;

  EmployeeDeliveryRecord({
    required this.orderId,
    required this.orderNumber,
    this.customerName = '',
    this.branchName = '',
    this.totalAmount = 0,
    this.deliveryFee = 0,
    this.earnings = 0,
    this.status = '',
    this.deliveredAt,
    this.proofImage,
  });

  factory EmployeeDeliveryRecord.fromRow(Map<String, dynamic> m) =>
      EmployeeDeliveryRecord(
        orderId: m['order_id']?.toString() ?? '',
        orderNumber: m['order_number']?.toString() ?? '',
        customerName: m['customer_name']?.toString() ?? '',
        branchName: m['branch_name']?.toString() ?? '',
        totalAmount: double.tryParse(m['total_amount']?.toString() ?? '0') ?? 0,
        deliveryFee: double.tryParse(m['delivery_fee']?.toString() ?? '0') ?? 0,
        earnings: double.tryParse(m['earnings']?.toString() ?? '0') ?? 0,
        status: m['status']?.toString() ?? '',
        deliveredAt: DateTime.tryParse(m['delivered_at']?.toString() ?? ''),
        proofImage: m['proof_image']?.toString(),
      );
}

class OpsApi {
  static final SupabaseClient _sb = Supabase.instance.client;

  /// تحويل استثناء Supabase إلى رسالة عربية واضحة
  static String friendlyError(Object e, {String fallback = 'حدث خطأ غير متوقع'}) {
    if (e is OpsApiException) return e.message;
    if (e is AuthException) return e.message;
    if (e is PostgrestException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('row-level security') || msg.contains('permission denied')) {
        return 'لا تملك صلاحية كافية لتنفيذ هذه العملية';
      }
      if (msg.contains('duplicate')) return 'العملية مكررة — حاول مرة أخرى';
      if (msg.contains('network') || msg.contains('connection')) {
        return 'لا يوجد اتصال بالإنترنت';
      }
      final cleaned = e.message
          .replaceAll(RegExp(r'^.*?:\s*'), '')
          .trim();
      return cleaned.isNotEmpty ? cleaned : fallback;
    }
    if (e is FormatException) return 'خطأ في تنسيق البيانات';
    return fallback;
  }

  static Future<Map<String, dynamic>> dashboardData({
    bool superAdmin = false,
  }) async {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    final deliveredRows = <Map<String, dynamic>>[];
    final pendingRows = <Map<String, dynamic>>[];
    final employeeRows = <Map<String, dynamic>>[];

    try {
      final dp = await _sb
          .from('delivered_orders_report')
          .select()
          .gte('delivered_at', today.toIso8601String());
      deliveredRows.addAll(dp);
    } catch (_) {}

    try {
      final pp = await _sb
          .from('orders')
          .select('id,status')
          .inFilter('status', ['pending', 'picked_up', 'on_the_way', 'assigned']);
      pendingRows.addAll(pp);
    } catch (_) {}

    try {
      final ep = await _sb
          .from('delivery_employees_report')
          .select()
          .limit(500);
      employeeRows.addAll(ep);
    } catch (_) {}

    double earnings = 0;
    for (final d in deliveredRows) {
      earnings += double.tryParse(d['delivery_earnings']?.toString() ?? '0') ?? 0;
    }

    final activeEmp = employeeRows.where((e) => e['is_active'] == true).length;
    final onlineEmp = employeeRows
        .where((e) => e['online_status']?.toString() == 'online' || e['is_online'] == true)
        .length;

    int approvals = 0;
    int branchCount = 0;
    try {
      final ap = await _sb
          .from('profiles')
          .select('id')
          .eq('role', 'driver')
          .eq('is_approved', false);
      approvals = ap.length;
    } catch (_) {}
    try {
      final bp = await _sb.from('branches').select('id');
      branchCount = bp.length;
    } catch (_) {}

    final avgFee = deliveredRows.isEmpty
        ? 0.0
        : deliveredRows.fold(
                0.0,
                (s, d) => s + (double.tryParse(d['delivery_fee']?.toString() ?? '0') ?? 0)) /
            deliveredRows.length;

    final dashboard = OpsDashboard(
      deliveredToday: deliveredRows.length,
      pendingOrders: pendingRows.length,
      activeEmployees: activeEmp,
      onlineEmployees: onlineEmp,
      pendingApprovals: approvals,
      totalEarningsToday: earnings,
      totalBranches: branchCount,
      avgDeliveryFee: avgFee,
    );

    final branchStats = <String, BranchSummary>{};
    try {
      final br = await _sb.from('branches').select('id,name,status');
      for (final b in br) {
        branchStats[b['id'].toString()] = BranchSummary(
          id: b['id'].toString(),
          name: b['name']?.toString() ?? '',
          status: b['status']?.toString(),
          delivered: 0,
          employees: 0,
          earnings: 0,
        );
      }
    } catch (_) {}

    for (final d in deliveredRows) {
      final bid = d['branch_id']?.toString();
      if (bid != null && branchStats.containsKey(bid)) {
        final b = branchStats[bid]!;
        branchStats[bid] = BranchSummary(
          id: b.id,
          name: b.name,
          status: b.status,
          delivered: b.delivered + 1,
          employees: b.employees,
          earnings: b.earnings +
              (double.tryParse(d['delivery_earnings']?.toString() ?? '0') ?? 0),
        );
      }
    }

    for (final e in employeeRows) {
      final bid = e['branch_id']?.toString();
      if (bid != null && branchStats.containsKey(bid) && e['is_active'] == true) {
        final b = branchStats[bid]!;
        branchStats[bid] = BranchSummary(
          id: b.id,
          name: b.name,
          status: b.status,
          delivered: b.delivered,
          employees: b.employees + 1,
          earnings: b.earnings,
        );
      }
    }

    return {
      'dashboard': dashboard,
      'branches': branchStats.values.toList(),
      'employees': employeeRows,
      'delivered': deliveredRows,
      'pending': pendingRows,
    };
  }

  /// قائمة المندوبين — نموذج Typed كامل (لا بيانات خام)
  static Future<List<DeliveryEmployeeModel>> fetchEmployees({
    String? branchId,
  }) async {
    try {
      final rows = await _sb
          .from('delivery_employees_report')
          .select()
          .order('online_status', ascending: false)
          .order('total_deliveries', ascending: false)
          .limit(500);
      var list = rows.map(DeliveryEmployeeModel.fromReport).toList();
      if (branchId != null) {
        list.removeWhere((e) => e.branchId != branchId);
      }
      return list;
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر تحميل المندوبين'));
    }
  }

  /// بنك الانتظار: طلبات انضمام غير معتمدة — نموذج Typed
  static Future<List<DeliveryEmployeeModel>> fetchPendingDrivers() async {
    try {
      final rows = await _sb
          .from('profiles')
          .select('id,full_name,phone,email,vehicle_type,is_approved,is_active,branch_id,created_at')
          .eq('role', 'driver')
          .eq('is_approved', false)
          .order('created_at', ascending: false);
      return rows.map((m) => DeliveryEmployeeModel(
            id: m['id']?.toString() ?? '',
            userId: m['id']?.toString(),
            fullName: m['full_name']?.toString() ?? '',
            phone: m['phone']?.toString() ?? '',
            email: m['email']?.toString() ?? '',
            vehicleType: m['vehicle_type']?.toString() ?? '',
            branchId: m['branch_id']?.toString(),
            isApproved: m['is_approved'] == true,
            isActive: m['is_active'] == true,
            joinedAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
          )).toList();
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر تحميل طلبات الانضمام'));
    }
  }

  /// الموافقة على مندوب — عبر RPC آمنة بخادم (مع فرع اختياري)
  static Future<void> approveDriver({
    required String profileId,
    String? branchId,
  }) async {
    try {
      await _sb.rpc('ops_approve_driver', params: {
        'p_profile_id': profileId,
        if (branchId != null && branchId.isNotEmpty) 'p_branch_id': branchId,
      });
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'فشلت الموافقة على المندوب'));
    }
  }

  /// رفض طلب انضمام — RPC آمنة بخادم
  static Future<void> rejectDriver({required String profileId}) async {
    try {
      await _sb.rpc('ops_reject_driver', params: {'p_profile_id': profileId});
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'فشل رفض الطلب'));
    }
  }

  /// تفعيل / إيقاف مندوب — RPC آمنة بخادم (employee_id)
  static Future<void> setDriverActive({
    required String employeeId,
    required bool active,
  }) async {
    try {
      await _sb.rpc('ops_set_driver_active', params: {
        'p_employee_id': employeeId,
        'p_active': active,
      });
    } catch (e) {
      throw OpsApiException(
          friendlyError(e, fallback: active ? 'فشل التفعيل' : 'فشل الإيقاف'));
    }
  }

  /// نقل مندوب بين الفروع — RPC موجودة مسبقاً
  static Future<void> transferEmployee({
    required String employeeId,
    required String newBranchId,
    String? reason,
  }) async {
    try {
      await _sb.rpc('transfer_delivery_employee', params: {
        'p_employee_id': employeeId,
        'p_new_branch_id': newBranchId,
        'p_transferred_by': _sb.auth.currentUser?.id ?? '',
        'p_reason': reason ?? '',
      });
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'فشل نقل المندوب'));
    }
  }

  /// بيانات الخريطة الحية: المواقع + حالة + الطلب الحالي لكل مندوب
  static Future<List<DeliveryEmployeeModel>> fetchDriverLocations() async {
    try {
      final rows = await _sb.rpc('ops_driver_locations');
      return (rows as List)
          .map((m) => DeliveryEmployeeModel.fromLocation(
              (m as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر تحميل الخريطة'));
    }
  }

  /// سجل توصيلات مندوب واحد (لصفحة التفاصيل)
  static Future<List<EmployeeDeliveryRecord>> fetchEmployeeDeliveries({
    required String employeeId,
  }) async {
    try {
      final rows = await _sb.rpc('ops_employee_deliveries', params: {
        'p_employee_id': employeeId,
      });
      return (rows as List)
          .map((m) => EmployeeDeliveryRecord.fromRow(
              (m as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر تحميل سجل التوصيلات'));
    }
  }

  static Future<List<DeliveredOrder>> fetchDeliveredOrders({
    String? branchId,
    DateTime? from,
    DateTime? to,
    int limit = 300,
  }) async {
    try {
      final rows = await _sb
          .from('delivered_orders_report')
          .select()
          .order('delivered_at', ascending: false)
          .limit(limit);
      final orders = rows.map(DeliveredOrder.fromRow).toList();
      if (branchId != null) {
        orders.removeWhere((o) => o.branchName != branchId);
      }
      if (from != null) {
        final fromUtc = from.toUtc();
        orders.removeWhere(
            (o) => o.deliveredAt == null || o.deliveredAt!.isBefore(fromUtc));
      }
      if (to != null) {
        final toUtc = to.toUtc();
        orders.removeWhere(
            (o) => o.deliveredAt == null || o.deliveredAt!.isAfter(toUtc));
      }
      return orders;
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر تحميل الطلبات المنجزة'));
    }
  }

  static Future<List<LiveOrder>> _liveFrom(List<Map<String, dynamic>> maps) {
    final rows = <LiveOrder>[];
    for (final m in maps) {
      final br = m['branch_name'] ??
          (m['branch'] is Map ? (m['branch'] as Map)['name'] : null);
      m['branch_name'] = br;
      final drv = m['driver_name'] ??
          (m['driver'] is Map ? (m['driver'] as Map)['full_name'] : null);
      m['driver_name'] = drv;
      rows.add(LiveOrder.fromRow(m));
    }
    return Future.value(rows);
  }

  static Future<List<LiveOrder>> fetchLiveOrders({
    String? branchId,
    List<String>? statuses,
  }) async {
    final st = statuses ?? ['pending', 'picked_up', 'on_the_way', 'assigned'];
    try {
      final rows = await _sb
          .from('orders')
          .select('id,status,total_price,delivery_fee,customer_name_manual,customer_phone,delivery_address,created_at,assigned_at,picked_up_at,on_the_way_at,delivery_lat,delivery_lng,branch_id,branch:branches(name),driver:drivers(full_name)')
          .inFilter('status', st)
          .order('created_at', ascending: false)
          .limit(200);
      return _liveFrom(rows);
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر تحميل الطلبات الحية'));
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBranches() async {
    try {
      return await _sb.from('branches').select('id,name,status');
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر تحميل الفروع'));
    }
  }

  static Future<double> fetchEarningsRange({
    DateTime? from,
    DateTime? to,
    String? branchId,
  }) async {
    try {
      final rows = await _sb
          .from('delivery_earnings')
          .select('amount,branch_id,created_at')
          .limit(2000);
      final List<Map<String, dynamic>> all = rows;
      var list = all;
      if (branchId != null) {
        list = list
            .where((t) => t['branch_id']?.toString() == branchId)
            .toList();
      }
      if (from != null) {
        final fromUtc = from.toUtc();
        list = list.where((t) {
          final created = DateTime.tryParse(t['created_at']?.toString() ?? '');
          return created != null && !created.isBefore(fromUtc);
        }).toList();
      }
      if (to != null) {
        final toUtc = to.toUtc();
        list = list.where((t) {
          final created = DateTime.tryParse(t['created_at']?.toString() ?? '');
          return created != null && !created.isAfter(toUtc);
        }).toList();
      }
      var total = 0.0;
      for (final t in list) {
        total += double.tryParse(t['amount']?.toString() ?? '0') ?? 0;
      }
      return total;
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر حساب الأرباح'));
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTransferHistory({
    String? branchId,
  }) async {
    try {
      final rows = await _sb
          .from('delivery_transfer_history')
          .select('id,reason,transferred_at,delivery_employee_id,old_branch_id,new_branch_id')
          .order('transferred_at', ascending: false)
          .limit(100);
      var filteredRows = rows;
      if (branchId != null) {
        filteredRows = rows
            .where((r) =>
                r['old_branch_id']?.toString() == branchId ||
                r['new_branch_id']?.toString() == branchId)
            .toList();
      }

      final empIds = <String>{};
      final branchIds = <String>{};
      for (final r in filteredRows) {
        if (r['delivery_employee_id'] != null) {
          empIds.add(r['delivery_employee_id'].toString());
        }
        if (r['old_branch_id'] != null) branchIds.add(r['old_branch_id'].toString());
        if (r['new_branch_id'] != null) branchIds.add(r['new_branch_id'].toString());
      }

      final nameByEmp = <String, String>{};
      final nameByBranch = <String, String>{};

      if (empIds.isNotEmpty) {
        try {
          final e = await _sb
              .from('delivery_employees')
              .select('id,user_id')
              .inFilter('id', empIds.toList());
          final userIds = <String>{};
          final idToUserId = <String, String>{};
          for (final m in e) {
            final uid = m['user_id']?.toString();
            if (uid != null) {
              userIds.add(uid);
              idToUserId[m['id'].toString()] = uid;
            }
          }
          if (userIds.isNotEmpty) {
            try {
              final p = await _sb
                  .from('profiles')
                  .select('id,full_name')
                  .inFilter('id', userIds.toList());
              final byUser = {
                for (final m in p)
                  m['id'].toString(): m['full_name']?.toString() ?? '—'
              };
              idToUserId.forEach((empId, uid) {
                nameByEmp[empId] = byUser[uid] ?? '—';
              });
            } catch (_) {}
          }
        } catch (_) {}
      }
      if (branchIds.isNotEmpty) {
        try {
          final b = await _sb
              .from('branches')
              .select('id,name')
              .inFilter('id', branchIds.toList());
          for (final m in b) {
            nameByBranch[m['id'].toString()] = m['name']?.toString() ?? '';
          }
        } catch (_) {}
      }

      return filteredRows.map((r) {
        return {
          ...r,
          'employee_name': nameByEmp[r['delivery_employee_id']?.toString()] ?? '—',
          'old_branch_name': nameByBranch[r['old_branch_id']?.toString()] ?? '—',
          'new_branch_name': nameByBranch[r['new_branch_id']?.toString()] ?? '—',
        };
      }).toList();
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر تحميل سجل النقل'));
    }
  }

  static Future<bool> assignOrderToEmployee({
    required String orderId,
    required String employeeId,
  }) async {
    try {
      await _sb.rpc('assign_order_to_delivery', params: {
        'p_order_id': orderId,
        'p_employee_id': employeeId,
      });
      return true;
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'فشل تعيين المندوب'));
    }
  }

  static Future<bool> releaseOrderFromDelivery(String orderId) async {
    try {
      await _sb.rpc('release_order_from_delivery', params: {
        'p_order_id': orderId,
      });
      return true;
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'فشل تحرير الطلب'));
    }
  }

  static Future<List<NotificationRow>> fetchNotifications() async {
    try {
      final rows = await _sb
          .from('admin_notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      return rows.map(NotificationRow.fromRow).toList();
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر تحميل الإشعارات'));
    }
  }

  /// عدد مناديب فرع معيّن (لكمّ المستلمين قبل الإرسال)
  static Future<int> countBranchDrivers(String branchId) async {
    try {
      final rows = await _sb
          .from('delivery_employees')
          .select('id')
          .eq('branch_id', branchId)
          .eq('is_active', true);
      return rows.length;
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر حساب المستلمين'));
    }
  }

  /// أجهزة FCM لمناديب محددين (لا broadcast أبداً من هنا)
  /// يدمج `user_fcm_tokens` مع عمود `fcm_token` في profiles كاحتياط
  static Future<List<String>> fetchDriverFcmTokens({
    List<String>? profileIds,
    String? branchId,
  }) async {
    try {
      List<String> ids;
      if (profileIds != null && profileIds.isNotEmpty) {
        ids = profileIds;
      } else {
        var q = _sb.from('delivery_employees').select('user_id');
        if (branchId != null) q = q.eq('branch_id', branchId);
        q = q.eq('is_active', true);
        final rows = await q;
        ids = rows
            .map((r) => r['user_id']?.toString())
            .whereType<String>()
            .toList();
        if (ids.isEmpty) return const [];
      }

      var q = _sb.from('user_fcm_tokens').select('token');
      q = q.inFilter('user_id', ids);
      final rows = await q;
      final tokens = <String>[];
      for (final r in rows) {
        final t = r['token']?.toString();
        if (t != null && t.isNotEmpty && !tokens.contains(t)) tokens.add(t);
      }

      // احتياط: أعمدة fcm_token القديمة (profiles.fcm_token)
      try {
        final pr = await _sb
            .from('profiles')
            .select('fcm_token')
            .inFilter('id', ids)
            .not('fcm_token', 'is', null);
        for (final r in pr) {
          final t = r['fcm_token']?.toString();
          if (t != null && t.isNotEmpty && !tokens.contains(t)) tokens.add(t);
        }
      } catch (_) {}

      return tokens;
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر جلب أجهزة المندوبين'));
    }
  }

  /// إعلان داخلي يظهر في تطبيق الإدارة وبرنامج الفروع (الجرس)
  /// يكتب في admin_notifications — لا يُرسل أي FCM
  static Future<void> broadcastAdminNote({
    required String title,
    required String message,
    String? targetBranchId,
    String type = 'ops_announcement',
  }) async {
    try {
      await _sb.from('admin_notifications').insert({
        'title': title,
        'message': message,
        'type': type,
        if (targetBranchId != null) 'target_branch_id': targetBranchId,
        'sender_id': _sb.auth.currentUser?.id,
      });
    } catch (e) {
      throw OpsApiException(friendlyError(e, fallback: 'تعذر حفظ الإعلان'));
    }
  }

  /// إرسال إشعار عبر Edge Function (send-notification) بلا broadcast
  static Future<int> sendDriverNotification({
    required String title,
    required String body,
    String? imageUrl,
    required List<String> tokens,
  }) async {
    if (tokens.isEmpty) {
      throw const OpsApiException('لا توجد أجهزة مستهدفة لهذا الاختيار');
    }
    try {
      final resp = await _sb.functions.invoke('send-notification', body: {
        'tokens': tokens,
        'title': title,
        'body': body,
        'data': {
          'image': imageUrl ?? '',
          'type': 'ops_announcement',
        },
      });
      final data = resp.data;
      if (data is Map) {
        final error = data['error'];
        if (error != null) {
          throw OpsApiException(error.toString());
        }
        return int.tryParse(data['successful']?.toString() ?? '') ?? 0;
      }
      return 0;
    } catch (e) {
      if (e is OpsApiException) rethrow;
      throw OpsApiException(
          friendlyError(e, fallback: 'تعذر إرسال الإشعار — تأكد من نشر دالة الإرسال'));
    }
  }
}
