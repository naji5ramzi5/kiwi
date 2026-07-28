import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'fresh_pos.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Inventory cache (offline access)
    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        product_id TEXT,
        title TEXT,
        actual_stock REAL,
        price REAL,
        unit TEXT,
        image_url TEXT
      )
    ''');

    // Offline sales queue
    await db.execute('''
      CREATE TABLE offline_orders (
        id TEXT PRIMARY KEY,
        branch_id TEXT,
        created_by TEXT,
        total_amount REAL,
        payment_method TEXT,
        items_json TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Pending inventory changes (offline stock adjustments)
    await db.execute('''
      CREATE TABLE pending_inventory (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        branch_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        actual_stock REAL NOT NULL,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Cached remote orders (for offline viewing)
    await db.execute('''
      CREATE TABLE cached_orders (
        id TEXT PRIMARY KEY,
        order_json TEXT NOT NULL,
        cached_at TEXT
      )
    ''');

    // Sync log
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event TEXT NOT NULL,
        details TEXT,
        created_at TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_inventory (
          local_id INTEGER PRIMARY KEY AUTOINCREMENT,
          branch_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          actual_stock REAL NOT NULL,
          is_synced INTEGER DEFAULT 0,
          created_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_orders (
          id TEXT PRIMARY KEY,
          order_json TEXT NOT NULL,
          cached_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event TEXT NOT NULL,
          details TEXT,
          created_at TEXT
        )
      ''');
      // Add columns to offline_orders if missing
      await db.execute(
          "ALTER TABLE offline_orders ADD COLUMN branch_id TEXT DEFAULT ''");
      await db.execute(
          "ALTER TABLE offline_orders ADD COLUMN created_by TEXT DEFAULT ''");
      await db.execute(
          "ALTER TABLE offline_orders ADD COLUMN payment_method TEXT DEFAULT 'نقداً'");
    }
  }

  // ─── Inventory Operations ───────────────────────────────────
  Future<void> saveInventory(List<Map<String, dynamic>> items) async {
    final db = await database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert('inventory', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getLocalInventory() async {
    final db = await database;
    return await db.query('inventory');
  }

  // ─── Offline Orders ─────────────────────────────────────────
  Future<void> saveOfflineOrder(Map<String, dynamic> order) async {
    final db = await database;
    await db.insert('offline_orders', order,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final db = await database;
    return await db.query('offline_orders', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as cnt FROM offline_orders WHERE is_synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markAsSynced(String orderId) async {
    final db = await database;
    await db.update('offline_orders', {'is_synced': 1},
        where: 'id = ?', whereArgs: [orderId]);
  }

  // ─── Pending Inventory Sync ────────────────────────────────
  Future<void> savePendingInventory(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('pending_inventory', {
      ...item,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingInventorySync() async {
    final db = await database;
    return await db.query('pending_inventory', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markInventorySynced(int localId) async {
    final db = await database;
    await db.update('pending_inventory', {'is_synced': 1},
        where: 'local_id = ?', whereArgs: [localId]);
  }

  // ─── Cached Remote Orders (for offline viewing) ────────────
  Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    final db = await database;
    await db.delete('cached_orders'); // clear old cache
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final order in orders) {
      batch.insert('cached_orders', {
        'id': order['id'],
        'order_json': order.toString(),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedOrders() async {
    final db = await database;
    final rows = await db.query('cached_orders', orderBy: 'cached_at DESC');
    return rows;
  }

  // ─── Sync Log ──────────────────────────────────────────────
  Future<void> logSyncEvent(String event, {String? details}) async {
    final db = await database;
    await db.insert('sync_log', {
      'event': event,
      'details': details,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
