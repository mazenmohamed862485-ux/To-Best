// lib/core/storage/local_db.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static const int _version = 1;
  static const String _dbName = 'to_best.db';
  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(path, version: _version, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_logs (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        session TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_workout_logs_uid_date ON workout_logs(uid, date)
    ''');
    await db.execute('''
      CREATE TABLE nutrition_logs (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_nutrition_logs_uid_date ON nutrition_logs(uid, date)
    ''');
    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        mark TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_attendance_uid_date ON attendance(uid, date)
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_messages_room ON messages(room_id, timestamp)
    ''');
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        key_name TEXT NOT NULL,
        uid TEXT NOT NULL,
        data TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE progress (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_progress_uid ON progress(uid, date)
    ''');
    await db.execute('''
      CREATE TABLE kv_store (
        key_name TEXT PRIMARY KEY,
        value TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // ── Settings ──────────────────────────────────────────────
  Future<String?> getSetting(String key) async {
    final database = await db;
    final rows = await database.query('settings',
        where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final database = await db;
    await database.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSetting(String key) async {
    final database = await db;
    await database.delete('settings', where: 'key = ?', whereArgs: [key]);
  }

  // ── Users ──────────────────────────────────────────────────
  Future<void> upsertUser(Map<String, dynamic> userData) async {
    final database = await db;
    final uid = userData['uid']?.toString() ?? '';
    if (uid.isEmpty) return;
    await database.insert(
      'users',
      {
        'uid': uid,
        'data': jsonEncode(userData),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final database = await db;
    final rows = await database.query('users',
        where: 'uid = ?', whereArgs: [uid], limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final database = await db;
    final rows = await database.query('users', orderBy: 'updated_at DESC');
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList();
  }

  Future<void> deleteUser(String uid) async {
    final database = await db;
    await database.delete('users', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> seedFromCloud(String uid, Map<String, dynamic> data) async {
    await upsertUser(data);
    // Seed workout logs
    if (data['workoutLogs'] is List) {
      for (final log in data['workoutLogs'] as List) {
        if (log is Map<String, dynamic>) await upsertWorkoutLog(uid, log);
      }
    }
    // Seed nutrition logs
    if (data['nutritionLogs'] is List) {
      for (final log in data['nutritionLogs'] as List) {
        if (log is Map<String, dynamic>) await upsertNutritionLog(uid, log);
      }
    }
    // Seed attendance
    if (data['attendance'] is Map) {
      final att = data['attendance'] as Map;
      for (final entry in att.entries) {
        await upsertAttendance(uid, entry.key.toString(), entry.value.toString());
      }
    }
    // Seed progress
    if (data['progress'] is List) {
      for (final p in data['progress'] as List) {
        if (p is Map<String, dynamic>) await upsertProgress(uid, p);
      }
    }
  }

  // ── Workout Logs ───────────────────────────────────────────
  Future<void> upsertWorkoutLog(String uid, Map<String, dynamic> log) async {
    final database = await db;
    final id = log['id']?.toString() ?? '${uid}_${log['date']}_${log['session']}';
    await database.insert(
      'workout_logs',
      {
        'id': id,
        'uid': uid,
        'date': log['date']?.toString() ?? '',
        'session': log['session']?.toString() ?? '',
        'data': jsonEncode(log),
        'synced': log['synced'] == true ? 1 : 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogs(String uid,
      {String? dateFrom, String? dateTo, int limit = 100}) async {
    final database = await db;
    String where = 'uid = ?';
    List<dynamic> args = [uid];
    if (dateFrom != null) {
      where += ' AND date >= ?';
      args.add(dateFrom);
    }
    if (dateTo != null) {
      where += ' AND date <= ?';
      args.add(dateTo);
    }
    final rows = await database.query(
      'workout_logs',
      where: where,
      whereArgs: args,
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>?> getWorkoutLog(String uid, String date, String session) async {
    final database = await db;
    final rows = await database.query(
      'workout_logs',
      where: 'uid = ? AND date = ? AND session = ?',
      whereArgs: [uid, date, session],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  // ── Nutrition Logs ─────────────────────────────────────────
  Future<void> upsertNutritionLog(String uid, Map<String, dynamic> log) async {
    final database = await db;
    final id = log['id']?.toString() ?? '${uid}_${log['date']}';
    await database.insert(
      'nutrition_logs',
      {
        'id': id,
        'uid': uid,
        'date': log['date']?.toString() ?? '',
        'data': jsonEncode(log),
        'synced': log['synced'] == true ? 1 : 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getNutritionLog(String uid, String date) async {
    final database = await db;
    final rows = await database.query(
      'nutrition_logs',
      where: 'uid = ? AND date = ?',
      whereArgs: [uid, date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getNutritionLogs(String uid,
      {String? dateFrom, String? dateTo}) async {
    final database = await db;
    String where = 'uid = ?';
    List<dynamic> args = [uid];
    if (dateFrom != null) { where += ' AND date >= ?'; args.add(dateFrom); }
    if (dateTo != null)   { where += ' AND date <= ?'; args.add(dateTo); }
    final rows = await database.query(
      'nutrition_logs', where: where, whereArgs: args, orderBy: 'date DESC', limit: 90);
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList();
  }

  // ── Attendance ─────────────────────────────────────────────
  Future<void> upsertAttendance(String uid, String date, String mark) async {
    final database = await db;
    await database.insert(
      'attendance',
      {
        'id': '${uid}_$date',
        'uid': uid,
        'date': date,
        'mark': mark,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getAttendanceForMonth(String uid, String yearMonth) async {
    final database = await db;
    final rows = await database.query(
      'attendance',
      where: "uid = ? AND date LIKE ?",
      whereArgs: [uid, '$yearMonth%'],
    );
    final result = <String, String>{};
    for (final row in rows) {
      result[row['date'] as String] = row['mark'] as String;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAttendance(String uid) async {
    final database = await db;
    return database.query('attendance',
        where: 'uid = ? AND synced = 0', whereArgs: [uid]);
  }

  Future<void> markAttendanceSynced(String uid, String date) async {
    final database = await db;
    await database.update(
      'attendance',
      {'synced': 1},
      where: 'uid = ? AND date = ?',
      whereArgs: [uid, date],
    );
  }

  // ── Messages ───────────────────────────────────────────────
  Future<void> upsertMessage(String roomId, Map<String, dynamic> msg) async {
    final database = await db;
    final id = msg['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ts = msg['timestamp'];
    int timestamp;
    if (ts is int) timestamp = ts;
    else if (ts is String) timestamp = int.tryParse(ts) ?? DateTime.now().millisecondsSinceEpoch;
    else timestamp = DateTime.now().millisecondsSinceEpoch;
    await database.insert(
      'messages',
      {'id': id, 'room_id': roomId, 'data': jsonEncode(msg), 'timestamp': timestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(String roomId,
      {int limit = 50, int? before}) async {
    final database = await db;
    String where = 'room_id = ?';
    List<dynamic> args = [roomId];
    if (before != null) { where += ' AND timestamp < ?'; args.add(before); }
    final rows = await database.query(
      'messages', where: where, whereArgs: args, orderBy: 'timestamp DESC', limit: limit);
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList()
        .reversed.toList();
  }

  Future<void> deleteMessage(String msgId) async {
    final database = await db;
    await database.delete('messages', where: 'id = ?', whereArgs: [msgId]);
  }

  // ── Progress ───────────────────────────────────────────────
  Future<void> upsertProgress(String uid, Map<String, dynamic> p) async {
    final database = await db;
    final id = p['id']?.toString() ?? '${uid}_${p['date']}_${p['type']}';
    await database.insert(
      'progress',
      {
        'id': id,
        'uid': uid,
        'date': p['date']?.toString() ?? '',
        'type': p['type']?.toString() ?? '',
        'data': jsonEncode(p),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getProgress(String uid,
      {String? type, int limit = 200}) async {
    final database = await db;
    String where = 'uid = ?';
    List<dynamic> args = [uid];
    if (type != null) { where += ' AND type = ?'; args.add(type); }
    final rows = await database.query(
      'progress', where: where, whereArgs: args, orderBy: 'date DESC', limit: limit);
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList();
  }

  // ── Sync Queue ─────────────────────────────────────────────
  Future<void> addToSyncQueue(Map<String, dynamic> item) async {
    final database = await db;
    await database.insert('sync_queue', {
      'action': item['action']?.toString() ?? '',
      'key_name': item['key']?.toString() ?? '',
      'uid': item['uid']?.toString() ?? '',
      'data': jsonEncode(item['data'] ?? {}),
      'retry_count': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final database = await db;
    final rows = await database.query('sync_queue', orderBy: 'created_at ASC', limit: 50);
    return rows.map((r) => {
      'id': r['id'],
      'action': r['action'],
      'key': r['key_name'],
      'uid': r['uid'],
      'data': jsonDecode(r['data'] as String),
    }).toList();
  }

  Future<void> removeFromQueue(int id) async {
    final database = await db;
    await database.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetryCount(int id) async {
    final database = await db;
    await database.rawUpdate(
        'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?', [id]);
  }

  Future<void> clearOldQueue() async {
    final database = await db;
    final cutoff = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    await database.delete('sync_queue',
        where: 'created_at < ? OR retry_count > 10', whereArgs: [cutoff]);
  }

  // ── KV Store (generic key-value) ───────────────────────────
  Future<String?> getKv(String key) async {
    final database = await db;
    final rows = await database.query('kv_store',
        where: 'key_name = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setKv(String key, String value) async {
    final database = await db;
    await database.insert(
      'kv_store',
      {'key_name': key, 'value': value, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteKv(String key) async {
    final database = await db;
    await database.delete('kv_store', where: 'key_name = ?', whereArgs: [key]);
  }

  // ── Cleanup ────────────────────────────────────────────────
  Future<void> clearUserData(String uid) async {
    final database = await db;
    await database.delete('workout_logs', where: 'uid = ?', whereArgs: [uid]);
    await database.delete('nutrition_logs', where: 'uid = ?', whereArgs: [uid]);
    await database.delete('attendance', where: 'uid = ?', whereArgs: [uid]);
    await database.delete('progress', where: 'uid = ?', whereArgs: [uid]);
    await database.delete('users', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> clearMessages(String roomId) async {
    final database = await db;
    await database.delete('messages', where: 'room_id = ?', whereArgs: [roomId]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
