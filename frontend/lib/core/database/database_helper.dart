import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'farmconnect.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create crops table
    await db.execute('''
      CREATE TABLE crops(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        price_per_unit REAL,
        unit TEXT,
        image_url TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create farmers table
    await db.execute('''
      CREATE TABLE farmers(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        location TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create orders table
    await db.execute('''
      CREATE TABLE orders(
        id TEXT PRIMARY KEY,
        farmer_id TEXT,
        crop_id TEXT,
        quantity INTEGER NOT NULL,
        total_price REAL,
        status TEXT DEFAULT 'pending',
        order_date TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (farmer_id) REFERENCES farmers (id),
        FOREIGN KEY (crop_id) REFERENCES crops (id)
      )
    ''');

    // Create sync_queue table for offline actions
    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT,
        created_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Crop operations
  Future<int> insertCrop(Map<String, dynamic> crop) async {
    final db = await database;
    crop['synced'] = 0;
    crop['created_at'] = DateTime.now().toIso8601String();
    crop['updated_at'] = DateTime.now().toIso8601String();
    
    // Add to sync queue
    await _addToSyncQueue('crops', crop['id'], 'INSERT', crop);
    
    return await db.insert('crops', crop);
  }

  Future<List<Map<String, dynamic>>> getAllCrops() async {
    final db = await database;
    return await db.query('crops', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getCropById(String id) async {
    final db = await database;
    final results = await db.query('crops', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateCrop(String id, Map<String, dynamic> crop) async {
    final db = await database;
    crop['updated_at'] = DateTime.now().toIso8601String();
    crop['synced'] = 0;
    
    // Add to sync queue
    await _addToSyncQueue('crops', id, 'UPDATE', crop);
    
    return await db.update('crops', crop, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCrop(String id) async {
    final db = await database;
    
    // Add to sync queue
    await _addToSyncQueue('crops', id, 'DELETE', {'id': id});
    
    return await db.delete('crops', where: 'id = ?', whereArgs: [id]);
  }

  // Farmer operations
  Future<int> insertFarmer(Map<String, dynamic> farmer) async {
    final db = await database;
    farmer['synced'] = 0;
    farmer['created_at'] = DateTime.now().toIso8601String();
    farmer['updated_at'] = DateTime.now().toIso8601String();
    
    await _addToSyncQueue('farmers', farmer['id'], 'INSERT', farmer);
    
    return await db.insert('farmers', farmer);
  }

  Future<List<Map<String, dynamic>>> getAllFarmers() async {
    final db = await database;
    return await db.query('farmers', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getFarmerById(String id) async {
    final db = await database;
    final results = await db.query('farmers', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  // Order operations
  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    order['synced'] = 0;
    order['created_at'] = DateTime.now().toIso8601String();
    order['updated_at'] = DateTime.now().toIso8601String();
    
    await _addToSyncQueue('orders', order['id'], 'INSERT', order);
    
    return await db.insert('orders', order);
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    return await db.query('orders', orderBy: 'order_date DESC');
  }

  Future<List<Map<String, dynamic>>> getOrdersWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        o.*,
        c.name as crop_name,
        c.image_url as crop_image,
        f.name as farmer_name,
        f.location as farmer_location
      FROM orders o
      LEFT JOIN crops c ON o.crop_id = c.id
      LEFT JOIN farmers f ON o.farmer_id = f.id
      ORDER BY o.order_date DESC
    ''');
  }

  // Sync operations
  Future<void> _addToSyncQueue(String tableName, String recordId, String action, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'data': data.toString(),
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedItems() async {
    final db = await database;
    return await db.query('sync_queue', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markAsSynced(String tableName, String recordId) async {
    final db = await database;
    await db.update(
      tableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<void> markSyncQueueItemAsSynced(int syncQueueId) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [syncQueueId],
    );
  }

  // Bulk operations for initial data sync
  Future<void> bulkInsertCrops(List<Map<String, dynamic>> crops) async {
    final db = await database;
    Batch batch = db.batch();
    
    for (var crop in crops) {
      crop['synced'] = 1; // Mark as synced since it's from server
      crop['created_at'] = DateTime.now().toIso8601String();
      crop['updated_at'] = DateTime.now().toIso8601String();
      batch.insert('crops', crop, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit();
  }

  Future<void> bulkInsertFarmers(List<Map<String, dynamic>> farmers) async {
    final db = await database;
    Batch batch = db.batch();
    
    for (var farmer in farmers) {
      farmer['synced'] = 1; // Mark as synced since it's from server
      farmer['created_at'] = DateTime.now().toIso8601String();
      farmer['updated_at'] = DateTime.now().toIso8601String();
      batch.insert('farmers', farmer, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit();
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('crops');
    await db.delete('farmers');
    await db.delete('orders');
    await db.delete('sync_queue');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
