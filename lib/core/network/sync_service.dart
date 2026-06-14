// lib/core/network/sync_service.dart
import 'dart:async';
import '../storage/local_db.dart';
import 'api_client.dart';
import 'connectivity_service.dart';

class SyncService {
  final ApiClient _api;
  final LocalDb _db;
  final ConnectivityService _connectivity;
  Timer? _syncTimer;
  bool _isFlushing = false;

  SyncService({
    required ApiClient api,
    required LocalDb db,
    required ConnectivityService connectivity,
  })  : _api = api,
        _db = db,
        _connectivity = connectivity;

  void startAutoSync({Duration interval = const Duration(seconds: 30)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => flushQueue());
    _connectivity.stream.listen((online) {
      if (online) flushQueue();
    });
  }

  Future<int> flushQueue() async {
    if (_isFlushing) return 0;
    if (!_connectivity.isOnline) return 0;
    if (!await _api.isConfigured) return 0;

    _isFlushing = true;
    int failed = 0;
    try {
      final queue = await _db.getSyncQueue();
      for (final item in queue) {
        final ok = await _api.pushToCloud(item);
        if (ok) {
          await _db.removeFromQueue(item['id'] as int);
        } else {
          await _db.incrementRetryCount(item['id'] as int);
          failed++;
        }
      }
      await _db.clearOldQueue();
    } finally {
      _isFlushing = false;
    }
    return failed;
  }

  Future<bool> seedFromCloud(String uid) async {
    if (!_connectivity.isOnline) return false;
    final data = await _api.fetchFullData(uid);
    if (data != null) {
      await _db.seedFromCloud(uid, data);
      return true;
    }
    // Fallback to basic user data
    final profile = await _api.fetchUserData(uid);
    if (profile != null) {
      await _db.upsertUser(profile);
      return true;
    }
    return false;
  }

  Future<bool> syncUser(String uid) async {
    if (!_connectivity.isOnline || !await _api.isConfigured) return false;
    final data = await _api.fetchUserData(uid);
    if (data == null) return false;
    await _db.upsertUser(data);
    return true;
  }

  void queueWorkoutLog(String uid, Map<String, dynamic> log) {
    _db.upsertWorkoutLog(uid, log);
    _db.addToSyncQueue({
      'action': 'SAVE_WORKOUT_LOG',
      'key': 'workoutLog_${uid}_${log['date']}_${log['session']}',
      'uid': uid,
      'data': log,
    });
    flushQueue();
  }

  void queueNutritionLog(String uid, Map<String, dynamic> log) {
    _db.upsertNutritionLog(uid, log);
    _db.addToSyncQueue({
      'action': 'SAVE_NUTRITION_LOG',
      'key': 'nutritionLog_${uid}_${log['date']}',
      'uid': uid,
      'data': log,
    });
    flushQueue();
  }

  void queueAttendance(String uid, String date, String mark) {
    _db.upsertAttendance(uid, date, mark);
    _db.addToSyncQueue({
      'action': 'SAVE_ATTENDANCE',
      'key': 'attendance_${uid}_$date',
      'uid': uid,
      'data': {'date': date, 'mark': mark},
    });
    flushQueue();
  }

  void queueProfileUpdate(String uid, Map<String, dynamic> fields) {
    _db.addToSyncQueue({
      'action': 'UPDATE_PROFILE',
      'key': 'profile_$uid',
      'uid': uid,
      'data': fields,
    });
    flushQueue();
  }

  void queueProgress(String uid, Map<String, dynamic> p) {
    _db.upsertProgress(uid, p);
    _db.addToSyncQueue({
      'action': 'SAVE_PROGRESS',
      'key': 'progress_${uid}_${p['date']}_${p['type']}',
      'uid': uid,
      'data': p,
    });
    flushQueue();
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
