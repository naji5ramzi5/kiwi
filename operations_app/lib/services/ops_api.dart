import 'package:supabase_flutter/supabase_flutter.dart';

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

class EmployeeRow {
  final String id;
  final String? userId;
  final String? name;
  final String? phone;
  final String? vehicleType;
  final String? branchId;
  final String? branchName;
  final bool isOnline;
  final bool isActive;
  final int totalDeliveries;
  final double walletBalance;

  EmployeeRow({
    required this.id,
    this.userId,
    this.name,
    this.phone,
    this.vehicleType,
    this.branchId,
    this.branchName,
    this.isOnline = false,
    this.isActive = true,
    this.totalDeliveries = 0,
    this.walletBalance = 0,
  });

  factory EmployeeRow.fromView(Map<String, dynamic> m) {
    final online = m['online_status']?.toString() == 'online' ||
        m['is_online'] == true;
    return EmployeeRow(
      id: m['id']?.toString() ?? '',
      userId: m['user_id']?.toString(),
      name: m['full_name']?.toString(),
      phone: m['phone']?.toString(),
      vehicleType: m['vehicle_type']?.toString(),
      branchId: m['branch_id']?.toString(),
      branchName: m['branch_name']?.toString(),
      isOnline: online,
      isActive: m['is_active'] == true,
      totalDeliveries: (m['total_deliveries'] is num)
          ? (m['total_deliveries'] as num).toInt()
          : int.tryParse(m['total_deliveries']?.toString() ?? '') ?? 0,
      walletBalance:
          double.tryParse(m['wallet_balance']?.toString() ?? '0') ?? 0,
    );
  }
}

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

  factory LiveOrder.fromRow(Map<String, dynamic> m) => LiveOrder(
        id: m['id']?.toString() ?? '',
        orderNumber: m['order_number']?.toString() ?? '',
        customerName: m['customer_name_manual']?.toString() ??
            m['customer_name']?.toString(),
        phone: m['customer_phone']?.toString(),
        address: m['delivery_address']?.toString(),
        status: m['status']?.toString() ?? '',
        total: double.tryParse(m['total_price']?.toString() ??
                m['total_amount']?.toString() ??
                '0') ??
            0,
        deliveryFee:
            double.tryParse(m['delivery_fee']?.toString() ?? '0') ?? 0,
        branchName: m['branch_name']?.toString(),
        branchId: m['branch_id']?.toString(),
        driverName: m['driver_name']?.toString() ??
            m['employee_name']?.toString(),
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
        acceptedAt: DateTime.tryParse(m['assigned_at']?.toString() ??
                m['accepted_at']?.toString() ??
                ''),
        pickedUpAt: DateTime.tryParse(m['picked_up_at']?.toString() ?? ''),
        onTheWayAt: DateTime.tryParse(m['on_the_way_at']?.toString() ?? ''),
        lat: double.tryParse(m['delivery_lat']?.toString() ??
                m['customer_lat']?.toString() ??
                ''),
        lng: double.tryParse(m['delivery_lng']?.toString() ??
                m['customer_lng']?.toString() ??
                ''),
      );
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

class OpsApi {
  static final SupabaseClient _sb = Supabase.instance.client;

  /// Top-level KPIs plus branch breakdown for the performance module.
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
          .inFilter('status', ['pending', 'picked_up', 'on_the_way']);
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
        .where((e) =>
            e['online_status']?.toString() == 'online' || e['is_online'] == true)
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
                (s, d) =>
                    s +
                    (double.tryParse(d['delivery_fee']?.toString() ?? '0') ?? 0)) /
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

  static Future<List<EmployeeRow>> fetchEmployees({String? branchId}) async {
    try {
      final rows = await _sb
          .from('delivery_employees_report')
          .select()
          .order('online_status', ascending: false)
          .order('total_deliveries', ascending: false)
          .limit(500);
      var list = rows.map(EmployeeRow.fromView).toList();
      if (branchId != null) {
        list.removeWhere((e) => e.branchId != branchId);
      }
      return list;
    } catch (_) {
      return [];
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
    } catch (_) {
      return [];
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
    final st = statuses ?? ['pending', 'picked_up', 'on_the_way', 'accepted'];
    try {
      final rows = await _sb
          .from('orders')
          .select('id,order_number,status,total_price,delivery_fee,customer_name_manual,customer_phone,delivery_address,created_at,assigned_at,picked_up_at,on_the_way_at,delivery_lat,delivery_lng,branch_id,branch:branches(name),driver:drivers(full_name)')
          .inFilter('status', st)
          .order('created_at', ascending: false)
          .limit(200);
      return _liveFrom(rows);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBranches() async {
    try {
      return await _sb.from('branches').select('id,name,status');
    } catch (_) {
      return [];
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
    } catch (_) {
      return 0;
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
    } catch (_) {
      return [];
    }
  }

  static Future<bool> transferEmployee({
    required String employeeId,
    required String newBranchId,
    String? reason,
  }) async {
    try {
      await _sb.rpc('transfer_delivery_employee', params: {
        'p_employee_id': employeeId,
        'p_new_branch_id': newBranchId,
        'p_reason': reason ?? '',
      });
      return true;
    } catch (_) {
      return false;
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
    } catch (_) {
      return false;
    }
  }

  static Future<bool> releaseOrderFromDelivery(String orderId) async {
    try {
      await _sb.rpc('release_order_from_delivery', params: {
        'p_order_id': orderId,
      });
      return true;
    } catch (_) {
      return false;
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
    } catch (_) {
      return [];
    }
  }
}