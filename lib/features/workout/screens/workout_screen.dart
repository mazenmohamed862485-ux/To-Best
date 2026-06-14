// lib/features/workout/screens/workout_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../data/models/workout_model.dart';
import '../../../shared/widgets/tb_button.dart';
import '../../../shared/widgets/tb_snackbar.dart';
import 'exercise_card.dart';
import 'session_done_screen.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});
  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Timer? _sessionTimer;
  Timer? _restTimer;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _startSessionClock();
  }

  void _startSessionClock() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(activeSessionProvider.notifier).tickElapsed();
      // Handle rest timer
      final s = ref.read(activeSessionProvider);
      if (s.isResting) {
        ref.read(activeSessionProvider.notifier).tickRest();
        if (ref.read(activeSessionProvider).restRemainingSec == 0) {
          TbSnackbar.show(context, AppLocalizations.of(context)['restDone'],
              isSuccess: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(activeSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (session.isFinished) {
      return SessionDoneScreen(log: session.log!);
    }

    if (session.log == null) {
      return _buildLobby(l, isDark);
    }

    return _buildActiveSession(l, session, isDark);
  }

  Widget _buildLobby(AppLocalizations l, bool isDark) {
    final user = ref.watch(authProvider).user;
    final todaySession = ref.watch(todaySessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l['workout'])),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fitness_center,
                    size: 64, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 24),
              Text(
                todaySession != null ? todaySession : l['restDay'],
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (user != null)
                Text(
                  '${Programs.names[user.program] ?? user.program} • ${user.programDays} ${l['daysPerWeek']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryGreen),
                ),
              const SizedBox(height: 32),
              if (todaySession != null)
                TbButton(
                  label: '🚀 ${l['todaySession']}',
                  onPressed: _startTodaySession,
                )
              else
                _RestDayWidget(l: l),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(l['recentSessions'],
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _RecentSessionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTodaySession() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    // Build a sample session from program definition
    final exercises = _buildDefaultExercises(user.program,
        ref.read(todaySessionProvider) ?? 'Session 1');
    final log = ref.read(workoutRepositoryProvider).buildSession(
          uid: user.uid,
          program: user.program,
          session: ref.read(todaySessionProvider) ?? 'Session 1',
          exercises: exercises,
        );
    ref.read(activeSessionProvider.notifier).startSession(log);
  }

  Widget _buildActiveSession(
      AppLocalizations l, ActiveSessionState session, bool isDark) {
    final log = session.log!;
    final exCount = log.exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(log.session),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final ok = await showTbConfirmDialog(
              context,
              title: 'إنهاء الجلسة',
              content: 'هل أنت متأكد من إنهاء الجلسة؟',
            );
            if (ok) {
              ref.read(activeSessionProvider.notifier).finishSession();
            }
          },
        ),
        actions: [
          // Stopwatch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: _StopwatchBadge(elapsedSec: session.elapsedSec),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: exCount > 0
                ? (session.currentExerciseIndex + 1) / exCount
                : 0,
            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            color: AppColors.primaryGreen,
          ),
          // Rest timer banner
          if (session.isResting)
            _RestTimerBanner(
              remaining: session.restRemainingSec,
              total: session.currentExercise?.restSec ?? 90,
              onStop: () =>
                  ref.read(activeSessionProvider.notifier).stopRest(),
            ),
          // Exercise pages
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: exCount,
              onPageChanged: (i) =>
                  ref.read(activeSessionProvider.notifier).goToExercise(i),
              itemBuilder: (ctx, i) => ExerciseCard(
                exerciseIndex: i,
                isDark: isDark,
              ),
            ),
          ),
          // Navigation bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
              ),
            ),
            child: Row(
              children: [
                if (session.hasPrev)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      _pageCtrl.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    '${session.currentExerciseIndex + 1} / $exCount',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (session.hasNext)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    color: AppColors.primaryGreen,
                    onPressed: () {
                      _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                  )
                else
                  TbButton(
                    label: l['finishSession'],
                    width: 130,
                    onPressed: () async {
                      final ok = await showTbConfirmDialog(
                        context,
                        title: l['finishSession'],
                        content: 'هل انتهيت من جميع التمارين؟',
                        confirmText: l['yes'],
                        cancelText: l['cancel'],
                      );
                      if (ok) {
                        ref.read(activeSessionProvider.notifier).finishSession();
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildDefaultExercises(
      String program, String session) {
    // Return sample exercises based on program
    final isUpper = session.toLowerCase().contains('upper');
    final isPush = session.toLowerCase().contains('push');
    final isPull = session.toLowerCase().contains('pull');
    final isLegs = session.toLowerCase().contains('leg') ||
        session.toLowerCase().contains('lower');

    if (isUpper || isPush) {
      return [
        _ex('Bench Press', 'Chest', 4, 8, 120),
        _ex('Incline DB Press', 'Chest', 3, 10, 90),
        _ex('Lateral Raise', 'Shoulder', 3, 15, 60),
        _ex('Overhead Press', 'Shoulder', 3, 10, 90),
        _ex('Tricep Pushdown', 'Triceps', 3, 12, 60),
      ];
    } else if (isPull) {
      return [
        _ex('Barbell Row', 'Back', 4, 8, 120),
        _ex('Lat Pulldown', 'Back', 3, 12, 90),
        _ex('Face Pull', 'Rear Delt', 3, 15, 60),
        _ex('Barbell Curl', 'Biceps', 3, 12, 60),
        _ex('Hammer Curl', 'Biceps', 2, 15, 60),
      ];
    } else if (isLegs) {
      return [
        _ex('Squat', 'Quads', 4, 8, 180),
        _ex('Romanian Deadlift', 'Hamstrings', 3, 10, 120),
        _ex('Leg Press', 'Quads', 3, 12, 90),
        _ex('Leg Curl', 'Hamstrings', 3, 12, 60),
        _ex('Calf Raise', 'Calves', 4, 15, 60),
      ];
    }
    return [
      _ex('Bench Press', 'Chest', 4, 8, 120),
      _ex('Squat', 'Quads', 4, 8, 180),
      _ex('Deadlift', 'Back', 3, 6, 180),
    ];
  }

  Map<String, dynamic> _ex(
          String name, String muscle, int sets, int reps, int rest) =>
      {
        'id': name.replaceAll(' ', '_').toLowerCase(),
        'name': name,
        'muscle': muscle,
        'workSets': sets,
        'targetReps': reps,
        'restSec': rest,
        'hasWarmup': true,
      };
}

// ── Sub-widgets ───────────────────────────────────────────────

class _StopwatchBadge extends StatelessWidget {
  final int elapsedSec;
  const _StopwatchBadge({required this.elapsedSec});

  @override
  Widget build(BuildContext context) {
    final h = elapsedSec ~/ 3600;
    final m = (elapsedSec % 3600) ~/ 60;
    final s = elapsedSec % 60;
    final display = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 4),
          Text(display,
              style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _RestTimerBanner extends StatelessWidget {
  final int remaining;
  final int total;
  final VoidCallback onStop;
  const _RestTimerBanner(
      {required this.remaining, required this.total, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? remaining / total : 0.0;
    return Container(
      color: AppColors.info.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom, color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${AppLocalizations.of(context)['rest']}: ${remaining}s',
                    style: const TextStyle(
                        color: AppColors.info, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct.toDouble(),
                  backgroundColor: AppColors.info.withOpacity(0.2),
                  color: AppColors.info,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onStop,
            child: const Icon(Icons.stop_circle_outlined,
                color: AppColors.error, size: 28),
          ),
        ],
      ),
    );
  }
}

class _RestDayWidget extends StatelessWidget {
  final AppLocalizations l;
  const _RestDayWidget({required this.l});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.hotel, size: 48, color: AppColors.darkTextMuted),
        const SizedBox(height: 12),
        Text(l['restDay'],
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('استرح واستعد لغد أقوى 💪',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RecentSessionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(workoutHistoryProvider);
    return histAsync.when(
      data: (logs) {
        if (logs.isEmpty) return const SizedBox();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.take(5).length,
          itemBuilder: (ctx, i) {
            final log = logs[i];
            return ListTile(
              leading: const Icon(Icons.check_circle,
                  color: AppColors.primaryGreen),
              title: Text(log.session,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(log.date,
                  style: const TextStyle(fontSize: 12)),
              trailing: Text(
                '${(log.durationSec / 60).toStringAsFixed(0)} min',
                style: const TextStyle(
                    color: AppColors.primaryGreen, fontSize: 12),
              ),
            );
          },
        );
      },
      loading: () =>
          const CircularProgressIndicator(color: AppColors.primaryGreen),
      error: (_, __) => const SizedBox(),
    );
  }
}

  Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? cancelText,
    String? confirmText,
    bool isDestructive = false,
  }) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText ?? 'إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: isDestructive
                ? AppColors.error
                : AppColors.primaryGreen,
          ),
          child: Text(confirmText ?? 'تأكيد'),
        ),
      ],
    ),
  );
  return result ?? false;
}
