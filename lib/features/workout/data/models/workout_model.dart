// lib/features/workout/data/models/workout_model.dart

class WorkoutSet {
  final int reps;
  final double weight;
  final int? rpe;
  bool done;

  WorkoutSet({
    required this.reps,
    required this.weight,
    this.rpe,
    this.done = false,
  });

  WorkoutSet copyWith({int? reps, double? weight, int? rpe, bool? done}) =>
      WorkoutSet(
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        rpe: rpe ?? this.rpe,
        done: done ?? this.done,
      );

  Map<String, dynamic> toMap() => {
        'reps': reps,
        'weight': weight,
        if (rpe != null) 'rpe': rpe,
        'done': done,
      };

  factory WorkoutSet.fromMap(Map<String, dynamic> m) => WorkoutSet(
        reps: int.tryParse(m['reps']?.toString() ?? '0') ?? 0,
        weight: double.tryParse(m['weight']?.toString() ?? '0') ?? 0,
        rpe: int.tryParse(m['rpe']?.toString() ?? ''),
        done: m['done'] == true,
      );
}

class WarmupSet {
  final double loadPct;
  final int reps;

  const WarmupSet({required this.loadPct, required this.reps});
}

class ExerciseLog {
  final String id;
  final String name;
  final String muscle;
  final int workSets;
  final int targetReps;
  final int restSec;
  final String? videoUrl;
  final String? notes;
  final String? alternative;
  final bool hasWarmup;
  List<WorkoutSet> sets;
  bool warmupDone;

  ExerciseLog({
    required this.id,
    required this.name,
    required this.muscle,
    required this.workSets,
    required this.targetReps,
    this.restSec = 90,
    this.videoUrl,
    this.notes,
    this.alternative,
    this.hasWarmup = true,
    List<WorkoutSet>? sets,
    this.warmupDone = false,
  }) : sets = sets ??
            List.generate(
              workSets,
              (_) => WorkoutSet(reps: targetReps, weight: 0),
            );

  double get max1RM {
    double best = 0;
    for (final s in sets) {
      if (s.done && s.weight > 0 && s.reps > 0) {
        final rm = s.weight * (1 + s.reps / 30);
        if (rm > best) best = rm;
      }
    }
    return double.parse(best.toStringAsFixed(1));
  }

  double get totalVolume {
    return sets.fold(0, (sum, s) => sum + (s.done ? s.weight * s.reps : 0));
  }

  double get prevBest1RM => 0; // filled from history

  List<WarmupSet> get warmupSets {
    if (!hasWarmup) return [];
    return const [
      WarmupSet(loadPct: 0.5, reps: 10),
      WarmupSet(loadPct: 0.65, reps: 6),
      WarmupSet(loadPct: 0.80, reps: 3),
      WarmupSet(loadPct: 0.90, reps: 2),
    ];
  }

  ExerciseLog copyWith({
    List<WorkoutSet>? sets,
    bool? warmupDone,
    String? notes,
  }) =>
      ExerciseLog(
        id: id,
        name: name,
        muscle: muscle,
        workSets: workSets,
        targetReps: targetReps,
        restSec: restSec,
        videoUrl: videoUrl,
        notes: notes ?? this.notes,
        alternative: alternative,
        hasWarmup: hasWarmup,
        sets: sets ?? this.sets,
        warmupDone: warmupDone ?? this.warmupDone,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'muscle': muscle,
        'workSets': workSets,
        'targetReps': targetReps,
        'restSec': restSec,
        'videoUrl': videoUrl,
        'notes': notes,
        'alternative': alternative,
        'hasWarmup': hasWarmup,
        'sets': sets.map((s) => s.toMap()).toList(),
        'warmupDone': warmupDone,
      };

  factory ExerciseLog.fromMap(Map<String, dynamic> m) {
    final setsRaw = m['sets'];
    final sets = setsRaw is List
        ? setsRaw
            .map((s) => WorkoutSet.fromMap(Map<String, dynamic>.from(s as Map)))
            .toList()
        : null;
    return ExerciseLog(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      muscle: m['muscle']?.toString() ?? '',
      workSets: int.tryParse(m['workSets']?.toString() ?? '3') ?? 3,
      targetReps: int.tryParse(m['targetReps']?.toString() ?? '10') ?? 10,
      restSec: int.tryParse(m['restSec']?.toString() ?? '90') ?? 90,
      videoUrl: m['videoUrl']?.toString(),
      notes: m['notes']?.toString(),
      alternative: m['alternative']?.toString(),
      hasWarmup: m['hasWarmup'] != false,
      sets: sets,
      warmupDone: m['warmupDone'] == true,
    );
  }
}

class WorkoutLog {
  final String id;
  final String uid;
  final String date;
  final String session;
  final String program;
  final List<ExerciseLog> exercises;
  final int durationSec;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? evaluation;
  final String? notes;

  const WorkoutLog({
    required this.id,
    required this.uid,
    required this.date,
    required this.session,
    required this.program,
    required this.exercises,
    this.durationSec = 0,
    this.startedAt,
    this.finishedAt,
    this.evaluation,
    this.notes,
  });

  double get totalVolume =>
      exercises.fold(0, (sum, e) => sum + e.totalVolume);

  int get completedSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.where((s) => s.done).length);

  int get totalSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.length);

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'date': date,
        'session': session,
        'program': program,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'durationSec': durationSec,
        'startedAt': startedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'evaluation': evaluation,
        'notes': notes,
      };

  factory WorkoutLog.fromMap(Map<String, dynamic> m) {
    final exRaw = m['exercises'];
    final exercises = exRaw is List
        ? exRaw
            .map((e) => ExerciseLog.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <ExerciseLog>[];
    return WorkoutLog(
      id: m['id']?.toString() ?? '',
      uid: m['uid']?.toString() ?? '',
      date: m['date']?.toString() ?? '',
      session: m['session']?.toString() ?? '',
      program: m['program']?.toString() ?? '',
      exercises: exercises,
      durationSec: int.tryParse(m['durationSec']?.toString() ?? '0') ?? 0,
      startedAt: m['startedAt'] != null
          ? DateTime.tryParse(m['startedAt'].toString())
          : null,
      finishedAt: m['finishedAt'] != null
          ? DateTime.tryParse(m['finishedAt'].toString())
          : null,
      evaluation: m['evaluation']?.toString(),
      notes: m['notes']?.toString(),
    );
  }
}

// ── Program Definitions ───────────────────────────────────────
class ProgramDef {
  final String id;
  final String nameAr;
  final String nameEn;
  final List<int> daysOptions;
  final Map<String, List<Map<String, dynamic>>> sessions;

  const ProgramDef({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.daysOptions,
    required this.sessions,
  });
}

// All program data (sessions are defined per program)
class Programs {
  static const Map<String, String> names = {
    'UL': 'Upper / Lower',
    'AP': 'Push / Pull',
    'FB': 'Full Body',
    'ARNOLD': 'Arnold Split',
    'PPL': 'PPL',
    'CUSTOM': 'Custom',
  };

  static List<int> daysForProgram(String prog) {
    switch (prog) {
      case 'UL': return [4];
      case 'AP': return [4, 6];
      case 'FB': return [3];
      case 'ARNOLD': return [6];
      case 'PPL': return [6];
      case 'CUSTOM': return [1, 2, 3, 4, 5, 6, 7];
      default: return [4];
    }
  }
}
