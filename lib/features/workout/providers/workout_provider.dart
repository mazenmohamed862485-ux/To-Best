// lib/features/workout/providers/workout_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/workout_model.dart';
import '../data/repositories/workout_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';

// Repository
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(
    localDb: ref.watch(localDbProvider),
    syncService: ref.watch(syncServiceProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

// ── Today's session name ──────────────────────────────────────
final todaySessionProvider = Provider<String?>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return null;
  final today = DateTime.now().weekday; // 1=Mon, 7=Sun
  if (!user.gymDays.contains(today)) return null;
  // Determine session based on program and gym day index
  final gymDayIndex = user.gymDays.indexOf(today);
  final sessions = _sessionNames(user.program, user.programDays);
  if (gymDayIndex < sessions.length) return sessions[gymDayIndex];
  return null;
});

List<String> _sessionNames(String program, int days) {
  switch (program) {
    case 'UL': return ['Upper A', 'Lower A', 'Upper B', 'Lower B'];
    case 'AP': return ['Push A', 'Pull A', 'Push B', 'Pull B', 'Push C', 'Pull C'];
    case 'FB': return ['Full Body A', 'Full Body B', 'Full Body C'];
    case 'ARNOLD': return ['Chest/Back', 'Shoulders/Arms', 'Legs', 'Chest/Back', 'Shoulders/Arms', 'Legs'];
    case 'PPL': return ['Push', 'Pull', 'Legs', 'Push', 'Pull', 'Legs'];
    default: return List.generate(days, (i) => 'Day ${i + 1}');
  }
}

// ── Workout Stats ─────────────────────────────────────────────
final workoutStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return {};
  final repo = ref.read(workoutRepositoryProvider);
  return repo.getStats(user.uid);
}).select((value) => value.asData?.value ?? {});

// ── Latest PRs ────────────────────────────────────────────────
final latestPRsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  final repo = ref.read(workoutRepositoryProvider);
  return repo.getLatestPRs(user.uid);
}).select((value) => value.asData?.value ?? []);

// ── Active Session State ──────────────────────────────────────
class ActiveSessionState {
  final WorkoutLog? log;
  final int currentExerciseIndex;
  final bool isResting;
  final int restRemainingSec;
  final int elapsedSec;
  final bool isFinished;

  const ActiveSessionState({
    this.log,
    this.currentExerciseIndex = 0,
    this.isResting = false,
    this.restRemainingSec = 0,
    this.elapsedSec = 0,
    this.isFinished = false,
  });

  ExerciseLog? get currentExercise {
    if (log == null ||
        currentExerciseIndex >= log!.exercises.length) return null;
    return log!.exercises[currentExerciseIndex];
  }

  bool get hasNext => log != null &&
      currentExerciseIndex < log!.exercises.length - 1;
  bool get hasPrev => currentExerciseIndex > 0;

  ActiveSessionState copyWith({
    WorkoutLog? log,
    int? currentExerciseIndex,
    bool? isResting,
    int? restRemainingSec,
    int? elapsedSec,
    bool? isFinished,
  }) {
    return ActiveSessionState(
      log: log ?? this.log,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      isResting: isResting ?? this.isResting,
      restRemainingSec: restRemainingSec ?? this.restRemainingSec,
      elapsedSec: elapsedSec ?? this.elapsedSec,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSessionState>(
        (ref) => ActiveSessionNotifier(ref));

class ActiveSessionNotifier extends StateNotifier<ActiveSessionState> {
  final Ref _ref;
  DateTime? _startTime;

  ActiveSessionNotifier(this._ref) : super(const ActiveSessionState());

  void startSession(WorkoutLog log) {
    _startTime = DateTime.now();
    state = ActiveSessionState(log: log);
  }

  void goToExercise(int index) {
    if (state.log == null) return;
    if (index < 0 || index >= state.log!.exercises.length) return;
    state = state.copyWith(currentExerciseIndex: index, isResting: false);
  }

  void nextExercise() => goToExercise(state.currentExerciseIndex + 1);
  void prevExercise() => goToExercise(state.currentExerciseIndex - 1);

  void updateSet(int exerciseIdx, int setIdx, WorkoutSet updated) {
    if (state.log == null) return;
    final exercises = List<ExerciseLog>.from(state.log!.exercises);
    final ex = exercises[exerciseIdx];
    final sets = List<WorkoutSet>.from(ex.sets);
    sets[setIdx] = updated;
    exercises[exerciseIdx] = ex.copyWith(sets: sets);
    state = state.copyWith(
      log: WorkoutLog(
        id: state.log!.id,
        uid: state.log!.uid,
        date: state.log!.date,
        session: state.log!.session,
        program: state.log!.program,
        exercises: exercises,
        durationSec: state.elapsedSec,
        startedAt: state.log!.startedAt,
      ),
    );
  }

  void markWarmupDone(int exerciseIdx) {
    if (state.log == null) return;
    final exercises = List<ExerciseLog>.from(state.log!.exercises);
    exercises[exerciseIdx] = exercises[exerciseIdx].copyWith(warmupDone: true);
    state = state.copyWith(
      log: WorkoutLog(
        id: state.log!.id,
        uid: state.log!.uid,
        date: state.log!.date,
        session: state.log!.session,
        program: state.log!.program,
        exercises: exercises,
        startedAt: state.log!.startedAt,
      ),
    );
  }

  void startRest(int seconds) {
    state = state.copyWith(isResting: true, restRemainingSec: seconds);
  }

  void stopRest() {
    state = state.copyWith(isResting: false, restRemainingSec: 0);
  }

  void tickRest() {
    if (!state.isResting) return;
    final remaining = state.restRemainingSec - 1;
    if (remaining <= 0) {
      state = state.copyWith(isResting: false, restRemainingSec: 0);
    } else {
      state = state.copyWith(restRemainingSec: remaining);
    }
  }

  void tickElapsed() {
    state = state.copyWith(elapsedSec: state.elapsedSec + 1);
  }

  Future<void> finishSession() async {
    if (state.log == null) return;
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    final now = DateTime.now();
    final duration = _startTime != null
        ? now.difference(_startTime!).inSeconds
        : state.elapsedSec;

    final finalLog = WorkoutLog(
      id: state.log!.id,
      uid: state.log!.uid,
      date: state.log!.date,
      session: state.log!.session,
      program: state.log!.program,
      exercises: state.log!.exercises,
      durationSec: duration,
      startedAt: _startTime ?? now,
      finishedAt: now,
    );

    final repo = _ref.read(workoutRepositoryProvider);
    await repo.saveLog(user.uid, finalLog);
    state = state.copyWith(log: finalLog, isFinished: true);
  }

  void reset() {
    _startTime = null;
    state = const ActiveSessionState();
  }
}

// ── Workout History ───────────────────────────────────────────
final workoutHistoryProvider =
    FutureProvider<List<WorkoutLog>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  final repo = ref.read(workoutRepositoryProvider);
  return repo.getHistory(user.uid);
});

// ── Exercise PRs by name ──────────────────────────────────────
final exercisePRsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, exerciseName) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return {};
  final repo = ref.read(workoutRepositoryProvider);
  return repo.getExercisePR(user.uid, exerciseName);
});
