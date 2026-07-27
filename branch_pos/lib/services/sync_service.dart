import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _databaseService = DatabaseService();
  final _supabase = Supabase.instance.client;
  Timer? _periodicSync;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  void startMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        syncPendingOrders();
      }
    });

    _periodicSync = Timer.periodic(const Duration(minutes: 5), (_) {
      syncPendingOrders();
    });

    syncPendingOrders();
  }

  void stopMonitoring() {
    _periodicSync?.cancel();
    _connectivitySubscription?.cancel();
  }

  Future<void> syncPendingOrders() async {
    if (_isSyncing) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    _isSyncing = true;
    try {
      final unsyncedOrders = await _databaseService.getUnsyncedOrders();

      for (final order in unsyncedOrders) {
        try {
          final itemsJson = order['items_json'] as String?;
          if (itemsJson == null) continue;

          final List<dynamic> decoded = jsonDecode(itemsJson);
          final items = decoded.cast<Map<String, dynamic>>();

          await _supabase.from('orders').insert({
            'id': order['id'],
            'branch_id': order['branch_id'] ?? '',
            'total_amount': order['total_amount'],
            'status': 'delivered',
            'created_by': order['created_by'] ?? '',
            'created_at': order['created_at'],
          });

          if (items.isNotEmpty) {
            final orderItems = items.map((item) => {
              'order_id': order['id'],
              'product_id': item['product_id'] ?? item['id'],
              'quantity': item['quantity'] ?? 0,
              'price': item['price'] ?? 0,
              'total': item['total'] ?? 0,
            }).toList();
            await _supabase.from('order_items').insert(orderItems);
          }

          await _databaseService.markAsSynced(order['id']);
        } catch (e) {
          print('Failed to sync order ${order['id']}: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  bool get isSyncing => _isSyncing;

  Future<int> get pendingCount async {
    final unsynced = await _databaseService.getUnsyncedOrders();
    return unsynced.length;
  }
}
