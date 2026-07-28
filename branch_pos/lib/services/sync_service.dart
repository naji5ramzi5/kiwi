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

  // Callback for UI to listen to sync events
  void Function()? onSyncComplete;

  void startMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        fullSync();
      }
    });

    _periodicSync = Timer.periodic(const Duration(minutes: 2), (_) {
      fullSync();
    });

    // Initial sync attempt after a short delay
    Future.delayed(const Duration(seconds: 5), fullSync);
  }

  void stopMonitoring() {
    _periodicSync?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Full sync: push local changes + pull remote data
  Future<void> fullSync() async {
    if (_isSyncing) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    _isSyncing = true;
    try {
      await _syncPendingOrders();
      await _syncPendingInventory();
      await _cacheRemoteOrders();
      onSyncComplete?.call();
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Push locally saved offline orders to Supabase
  Future<void> _syncPendingOrders() async {
    final unsyncedOrders = await _databaseService.getUnsyncedOrders();
    for (final order in unsyncedOrders) {
      try {
        final itemsJson = order['items_json'] as String?;
        if (itemsJson == null) continue;

        final List<dynamic> decoded = jsonDecode(itemsJson);
        final items = decoded.cast<Map<String, dynamic>>();

        // Insert order
        final orderData = await _supabase.from('orders').insert({
          'branch_id': order['branch_id'] ?? '',
          'total_amount': order['total_amount'],
          'status': 'delivered',
          'created_by': order['created_by'] ?? '',
          'created_at': order['created_at'],
          'payment_method': order['payment_method'] ?? 'نقداً',
        }).select().single();

        // Insert order items
        if (items.isNotEmpty) {
          final orderItems = items.map((item) => ({
            'order_id': orderData['id'],
            'product_id': item['product_id'] ?? item['id'],
            'product_name': item['name'] ?? '',
            'quantity': item['quantity'] ?? 0,
            'unit_price': (item['price'] ?? 0).toDouble(),
            'total_price': (item['total'] ?? 0).toDouble(),
          })).toList();
          await _supabase.from('order_items').insert(orderItems);
        }

        // Deduct inventory
        for (final item in items) {
          final pid = item['product_id'] ?? item['id'];
          final qty = (item['quantity'] ?? 0).toDouble();
          if (pid != null && qty > 0) {
            final current = await _supabase
                .from('branch_inventory')
                .select('actual_stock')
                .eq('branch_id', order['branch_id'])
                .eq('product_id', pid)
                .maybeSingle();
            final newStock = ((current?['actual_stock'] as num?)?.toDouble() ?? 0) - qty;
            if (newStock >= 0) {
              await _supabase.from('branch_inventory').upsert({
                'branch_id': order['branch_id'],
                'product_id': pid,
                'actual_stock': newStock,
              }, onConflict: 'branch_id,product_id');
            }
          }
        }

        await _databaseService.markAsSynced(order['id']);
        print('Synced order ${order['id']} successfully');
      } catch (e) {
        print('Failed to sync order ${order['id']}: $e');
      }
    }
  }

  /// Push pending inventory changes made offline
  Future<void> _syncPendingInventory() async {
    final pendingItems = await _databaseService.getPendingInventorySync();
    for (final item in pendingItems) {
      try {
        await _supabase.from('branch_inventory').upsert({
          'branch_id': item['branch_id'],
          'product_id': item['product_id'],
          'actual_stock': item['actual_stock'],
          'is_active': true,
        }, onConflict: 'branch_id,product_id');
        await _databaseService.markInventorySynced(item['local_id']);
      } catch (e) {
        print('Failed to sync inventory item ${item['product_id']}: $e');
      }
    }
  }

  /// Cache incoming orders locally for offline viewing
  Future<void> _cacheRemoteOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, profiles(full_name, phone), order_items(*, products(name))')
          .order('created_at', ascending: false)
          .limit(100);
      await _databaseService.cacheOrders(
          List<Map<String, dynamic>>.from(response));
    } catch (e) {
      print('Failed to cache remote orders: $e');
    }
  }

  bool get isSyncing => _isSyncing;

  Future<int> get pendingCount => _databaseService.getUnsyncedCount();

  /// Force immediate sync (triggered by UI button)
  Future<void> syncNow() => fullSync();
}
