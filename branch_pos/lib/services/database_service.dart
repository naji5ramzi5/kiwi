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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // 1. جدول المخزون المحلي (Offline Cache)
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

    // 2. جدول المبيعات المعلقة (Offline Sales)
    await db.execute('''
      CREATE TABLE offline_orders (
        id TEXT PRIMARY KEY,
        total_amount REAL,
        created_at TEXT,
        items_json TEXT, -- JSON string of items
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Inventory Operations
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

  // Offline Orders Operations
  Future<void> saveOfflineOrder(Map<String, dynamic> order) async {
    final db = await database;
    await db.insert('offline_orders', order);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final db = await database;
    return await db.query('offline_orders', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markAsSynced(String orderId) async {
    final db = await database;
    await db.update('offline_orders', {'is_synced': 1}, where: 'id = ?', whereArgs: [orderId]);
  }
}
