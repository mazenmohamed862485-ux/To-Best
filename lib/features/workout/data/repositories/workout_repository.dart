// lib/features/workout/data/repositories/workout_repository.dart
import 'dart:math';
import '../models/workout_model.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/network/sync_service.dart';
import '../../../../core/network/api_client.dart';
import 'package:uuid/uuid.dart';

class WorkoutRepository {
  final LocalDb _db;
  final SyncService _sync;
  final ApiClient _api;
  static const _uuid = Uuid();

  WorkoutRepository({
    required LocalDb localDb,
    required SyncService syncService,
    required ApiClient apiClient,
  })  : _db = localDb,
        _sync = syncService,
        _api = apiClient;

  Future<void> saveLog(String uid, WorkoutLog log) async {
    final map = log.toMap();
    map['id'] = log.id.isNotEmpty ? log.id : _uuid.v4();
    await _db.upsertWorkoutLog(uid, map);
    _sync.queueWorkoutLog(uid, map);
  }

  Future<List<WorkoutLog>> getHistory(String uid,
      {String? dateFrom, String? dateTo, int limit = 50}) async {
    final rows = await _db.getWorkoutLogs(uid,
        dateFrom: dateFrom, dateTo: dateTo, limit: limit);
    return rows.map(WorkoutLog.fromMap).toList();
  }

  Future<WorkoutLog?> getLogForDate(
      String uid, String date, String session) async {
    final map = await _db.getWorkoutLog(uid, date, session);
    return map != null ? WorkoutLog.fromMap(map) : null;
  }

  Future<Map<String, dynamic>> getStats(String uid) async {
    final logs = await getHistory(uid, limit: 200);
    if (logs.isEmpty) return {'total': 0, 'streak': 0, 'daysAgo': '-'};

    final total = logs.length;
    // Streak (consecutive gym days)
    final dates = logs.map((l) => l.date).toSet().toList()..sort();
    int streak = 0;
    DateTime? prev;
    for (final d in dates.reversed) {
      final dt = DateTime.tryParse(d);
      if (dt == null) continue;
      if (prev == null) {
        streak = 1;
        prev = dt;
        continue;
      }
      if (prev.difference(dt).inDays == 1) {
        streak++;
        prev = dt;
      } else {
        break;
      }
    }

    // Days since last workout
    int daysAgo = 0;
    if (logs.isNotEmpty) {
      final last = DateTime.tryParse(logs.first.date);
      if (last != null) {
        daysAgo = DateTime.now().difference(last).inDays;
      }
    }

    return {'total': total, 'streak': streak, 'daysAgo': daysAgo};
  }

  Future<List<Map<String, dynamic>>> getLatestPRs(String uid) async {
    final logs = await getHistory(uid, limit: 100);
    final prMap = <String, Map<String, dynamic>>{};
    for (final log in logs) {
      for (final ex in log.exercises) {
        for (final s in ex.sets) {
          if (!s.done || s.weight <= 0 || s.reps <= 0) continue;
          final epley = s.weight * (1 + s.reps / 30);
          final existing = prMap[ex.name];
          if (existing == null || epley > (existing['epley'] as double)) {
            prMap[ex.name] = {
              'exercise': ex.name,
              'weight': s.weight,
              'reps': s.reps,
              'epley': epley,
              'date': log.date,
            };
          }
        }
      }
    }
    final prs = prMap.values.toList();
    prs.sort((a, b) =>
        (b['date'] as String).compareTo(a['date'] as String));
    return prs.take(10).toList();
  }

  Future<Map<String, dynamic>> getExercisePR(
      String uid, String exerciseName) async {
    final logs = await getHistory(uid, limit: 200);
    double bestEpley = 0;
    Map<String, dynamic> bestSet = {};
    for (final log in logs) {
      for (final ex in log.exercises) {
        if (ex.name.toLowerCase() != exerciseName.toLowerCase()) continue;
        for (final s in ex.sets) {
          if (!s.done || s.weight <= 0 || s.reps <= 0) continue;
          final epley = s.weight * (1 + s.reps / 30);
          if (epley > bestEpley) {
            bestEpley = epley;
            bestSet = {
              'weight': s.weight,
              'reps': s.reps,
              'epley': epley,
              'date': log.date,
            };
          }
        }
      }
    }
    return bestSet;
  }

  /// Returns chart data for an exercise (weight over dates)
  Future<List<Map<String, dynamic>>> getExerciseChartData(
      String uid, String exerciseName) async {
    final logs = await getHistory(uid, limit: 200);
    final points = <Map<String, dynamic>>[];
    for (final log in logs.reversed) {
      for (final ex in log.exercises) {
        if (ex.name.toLowerCase() != exerciseName.toLowerCase()) continue;
        double maxWeight = 0;
        for (final s in ex.sets) {
          if (s.done && s.weight > maxWeight) maxWeight = s.weight;
        }
        if (maxWeight > 0) {
          points.add({'date': log.date, 'weight': maxWeight});
        }
      }
    }
    return points;
  }

  /// Returns volume chart data
  Future<List<Map<String, dynamic>>> getVolumeChartData(String uid,
      {int days = 30}) async {
    final from =
        DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);
    final logs = await getHistory(uid, dateFrom: from);
    return logs
        .map((l) => {'date': l.date, 'volume': l.totalVolume})
        .toList()
        .reversed
        .toList();
  }

  WorkoutLog buildSession({
    required String uid,
    required String program,
    required String session,
    required List<Map<String, dynamic>> exercises,
  }) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final exLogs = exercises
        .map((e) => ExerciseLog.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return WorkoutLog(
      id: const Uuid().v4(),
      uid: uid,
      date: today,
      session: session,
      program: program,
      exercises: exLogs,
      startedAt: DateTime.now(),
    );
  }
}
