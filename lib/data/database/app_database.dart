import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../models/connection_settings_model.dart';
import '../models/device_log_model.dart';
import '../models/notification_model.dart';
import '../models/sensor_log_model.dart';
import '../models/vehicle_log_model.dart';
import '../models/visitor_log_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smarthome.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 1. connection_settings
    await db.execute('''
      CREATE TABLE connection_settings (
        id INTEGER PRIMARY KEY,
        esp32_ip TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. sensor_logs
    await db.execute('''
      CREATE TABLE sensor_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        temperature REAL NOT NULL,
        humidity REAL NOT NULL,
        gas_value INTEGER NOT NULL,
        ldr_value INTEGER NOT NULL,
        rain_status INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. device_logs
    await db.execute('''
      CREATE TABLE device_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        servo_angle INTEGER NOT NULL,
        led_status INTEGER NOT NULL,
        buzzer_status INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. visitor_logs
    await db.execute('''
      CREATE TABLE visitor_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        distance REAL NOT NULL,
        detected INTEGER NOT NULL,
        detected_at TEXT NOT NULL
      )
    ''');

    // 5. vehicle_logs
    await db.execute('''
      CREATE TABLE vehicle_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        distance REAL NOT NULL,
        vehicle_status TEXT NOT NULL,
        detected_at TEXT NOT NULL
      )
    ''');

    // 6. notifications
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ==================== CONNECTION SETTINGS ====================

  Future<void> saveEsp32Ip(String ip) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'connection_settings',
      {
        'id': 1,
        'esp32_ip': ip.trim(),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getLastSavedIp() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'connection_settings',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return maps.first['esp32_ip'] as String?;
      }
    } catch (_) {
      // In case database is not initialized or unavailable
    }
    return null;
  }

  Future<ConnectionSettingsModel?> getConnectionSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'connection_settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ConnectionSettingsModel.fromMap(maps.first);
    }
    return null;
  }

  // ==================== SENSOR LOGS ====================

  Future<int> insertSensorLog(SensorLogModel log) async {
    final db = await database;
    final id = await db.insert('sensor_logs', log.toMap());
    _pruneOldRecords('sensor_logs');
    return id;
  }

  Future<List<SensorLogModel>> getRecentSensorLogs({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_logs',
      orderBy: 'id DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => SensorLogModel.fromMap(maps[i]));
  }

  // ==================== DEVICE LOGS ====================

  Future<int> insertDeviceLog(DeviceLogModel log) async {
    final db = await database;
    final id = await db.insert('device_logs', log.toMap());
    _pruneOldRecords('device_logs');
    return id;
  }

  Future<List<DeviceLogModel>> getRecentDeviceLogs({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'device_logs',
      orderBy: 'id DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => DeviceLogModel.fromMap(maps[i]));
  }

  // ==================== VISITOR LOGS ====================

  Future<int> insertVisitorLog(VisitorLogModel log) async {
    final db = await database;
    final id = await db.insert('visitor_logs', log.toMap());
    _pruneOldRecords('visitor_logs');
    return id;
  }

  Future<List<VisitorLogModel>> getRecentVisitorLogs({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visitor_logs',
      orderBy: 'id DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => VisitorLogModel.fromMap(maps[i]));
  }

  // ==================== VEHICLE LOGS ====================

  Future<int> insertVehicleLog(VehicleLogModel log) async {
    final db = await database;
    final id = await db.insert('vehicle_logs', log.toMap());
    _pruneOldRecords('vehicle_logs');
    return id;
  }

  Future<List<VehicleLogModel>> getRecentVehicleLogs({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicle_logs',
      orderBy: 'id DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => VehicleLogModel.fromMap(maps[i]));
  }

  // ==================== NOTIFICATIONS ====================

  Future<int> insertNotification(NotificationModel notification) async {
    final db = await database;
    return await db.insert('notifications', notification.toMap());
  }

  Future<List<NotificationModel>> getAllNotifications({int limit = 100}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'id DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => NotificationModel.fromMap(maps[i]));
  }

  Future<int> getUnreadNotificationCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0',
    );
    if (result.isNotEmpty) {
      return (result.first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<int> markAsRead(int id) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAllAsRead() async {
    final db = await database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'is_read = ?',
      whereArgs: [0],
    );
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllNotifications() async {
    final db = await database;
    return await db.delete('notifications');
  }

  // ==================== PRUNING OLD DATA ====================

  Future<void> _pruneOldRecords(String tableName) async {
    try {
      final db = await database;
      await db.execute('''
        DELETE FROM $tableName WHERE id NOT IN (
          SELECT id FROM $tableName ORDER BY id DESC LIMIT ${AppConstants.maxLogEntries}
        )
      ''');
    } catch (_) {
      // Ignore background pruning errors
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
