// lib/features/workout/screens/exercise_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/tb_button.dart';
import '../../../shared/widgets/tb_snackbar.dart';
import '../../home/screens/main_shell.dart';
import '../providers/workout_provider.dart';
import '../data/models/workout_model.dart';

class ExerciseCard extends ConsumerWidget {
  final int exerciseIndex;
  final bool isDark;
  const ExerciseCard({super.key, required this.exerciseIndex, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    if (session.log == null || exerciseIndex >= session.log!.exercises.length) {
      return const SizedBox();
    }
    final ex = session.log!.exercises[exerciseIndex];
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Exercise Header ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(ex.muscle,
                          style: const TextStyle(
                              color: AppColors.primaryGreen, fontSize: 11)),
                    ),
                    const SizedBox(height: 6),
                    Text(ex.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700)),
                    Text(
                        '${ex.workSets} ${l['sets']} × ${ex.targetReps} ${l['reps']} • ${ex.restSec}s ${l['rest']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary)),
                  ],
                ),
              ),
              // Video button
              if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.play_circle_outline,
                      color: AppColors.primaryGreen, size: 32),
                  onPressed: () =>
                      _openVideo(context, ex.videoUrl!),
                ),
            ],
          ),

          // ── Warmup Protocol ────────────────────────────────
          if (ex.hasWarmup && !ex.warmupDone) ...[
            const SizedBox(height: 16),
            _WarmupCard(
              exerciseIndex: exerciseIndex,
              sets: ex.warmupSets,
              isDark: isDark,
              l: l,
            ),
          ] else if (ex.hasWarmup && ex.warmupDone) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text(l['warmupDone'],
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Text(l['sets'],
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // ── Work Sets ─────────────────────────────────────
          ...List.generate(ex.sets.length, (si) {
            final s = ex.sets[si];
            return _SetRow(
              setIndex: si,
              exerciseIndex: exerciseIndex,
              set: s,
              targetReps: ex.targetReps,
              isDark: isDark,
              l: l,
              showEpley: user?.showEpley ?? false,
              showRPE: user?.showRPE ?? true,
              onRestStart: () {
                ref
                    .read(activeSessionProvider.notifier)
                    .startRest(ex.restSec);
              },
            );
          }),

          // ── Notes ─────────────────────────────────────────
          if (ex.notes != null && ex.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ex.notes!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _openVideo(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: _VideoSheet(url: url),
      ),
    );
  }
}

class _WarmupCard extends ConsumerWidget {
  final int exerciseIndex;
  final List<WarmupSet> sets;
  final bool isDark;
  final AppLocalizations l;
  const _WarmupCard({
    required this.exerciseIndex,
    required this.sets,
    required this.isDark,
    required this.l,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l['warmupProtocol'],
              style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 12),
          ...sets.map((ws) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Text('${(ws.loadPct * 100).toInt()}% × ${ws.reps} reps',
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ref
                  .read(activeSessionProvider.notifier)
                  .markWarmupDone(exerciseIndex),
              icon: const Icon(Icons.check, size: 16),
              label: Text(l['warmupDone']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  final int setIndex;
  final int exerciseIndex;
  final WorkoutSet set;
  final int targetReps;
  final bool isDark;
  final AppLocalizations l;
  final bool showEpley;
  final bool showRPE;
  final VoidCallback onRestStart;
  const _SetRow({
    required this.setIndex,
    required this.exerciseIndex,
    required this.set,
    required this.targetReps,
    required this.isDark,
    required this.l,
    required this.showEpley,
    required this.showRPE,
    required this.onRestStart,
  });

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  late int? _rpe;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
        text: widget.set.weight > 0
            ? widget.set.weight.toString()
            : '');
    _repsCtrl = TextEditingController(
        text: widget.set.reps.toString());
    _rpe = widget.set.rpe;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  double get epley {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final r = int.tryParse(_repsCtrl.text) ?? 0;
    if (w <= 0 || r <= 0) return 0;
    return double.parse((w * (1 + r / 30)).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.set.done;
    final l = widget.l;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.primaryGreen.withOpacity(0.12)
            : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? AppColors.primaryGreen.withOpacity(0.4)
              : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Set number badge
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primaryGreen
                      : AppColors.primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.setIndex + 1}',
                    style: TextStyle(
                        color: isDone ? Colors.white : AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Weight input
              Expanded(
                child: _NumInput(
                  controller: _weightCtrl,
                  label: l['kg'],
                  readOnly: isDone,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              const Text('×', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              // Reps input
              Expanded(
                child: _NumInput(
                  controller: _repsCtrl,
                  label: l['reps'],
                  readOnly: isDone,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              // Done button
              GestureDetector(
                onTap: () => _toggleDone(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primaryGreen
                        : AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDone ? Icons.check : Icons.check_circle_outline,
                    color: isDone ? Colors.white : AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          // Epley / RPE
          if (isDone && (widget.showEpley || widget.showRPE)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.showEpley && epley > 0)
                  Text('1RM ≈ ${epley}kg',
                      style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                const Spacer(),
                if (widget.showRPE)
                  _RPESelector(
                    value: _rpe,
                    onChanged: (v) => setState(() => _rpe = v),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _toggleDone() {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final r = int.tryParse(_repsCtrl.text) ?? widget.targetReps;
    final newSet = widget.set.copyWith(
      weight: w,
      reps: r,
      rpe: _rpe,
      done: !widget.set.done,
    );
    ref.read(activeSessionProvider.notifier).updateSet(
          widget.exerciseIndex,
          widget.setIndex,
          newSet,
        );
    if (!widget.set.done) {
      // Mark done -> start rest timer
      widget.onRestStart();
    }
  }
}

class _NumInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool readOnly;
  final void Function(String)? onChanged;
  const _NumInput({
    required this.controller,
    required this.label,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        isDense: true,
      ),
    );
  }
}

class _RPESelector extends StatelessWidget {
  final int? value;
  final void Function(int) onChanged;
  const _RPESelector({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('RPE: ',
            style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
        ...List.generate(10, (i) {
          final v = i + 1;
          final selected = value == v;
          return GestureDetector(
            onTap: () => onChanged(v),
            child: Container(
              margin: const EdgeInsets.only(left: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryGreen
                    : AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$v',
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _VideoSheet extends StatelessWidget {
  final String url;
  const _VideoSheet({required this.url});

  @override
  Widget build(BuildContext context) {
    // Use WebView for Google Drive videos
    return Column(
      children: [
        AppBar(
          title: const Text('Video'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_outline,
                    size: 64, color: AppColors.primaryGreen),
                const SizedBox(height: 16),
                const Text('يتم فتح الفيديو...'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Open via url_launcher
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('فتح الفيديو'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Session Done Screen
class SessionDoneScreen extends ConsumerWidget {
  final WorkoutLog log;
  const SessionDoneScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dur = log.durationSec;
    final mins = dur ~/ 60;
    final secs = dur % 60;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(l['sessionDone'],
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DoneStat('$mins:${secs.toString().padLeft(2, '0')}',
                      l['min']),
                  _DoneStat(log.exercises.length.toString(),
                      'تمرين'),
                  _DoneStat(log.completedSets.toString(),
                      l['sets']),
                  _DoneStat(
                      '${log.totalVolume.toStringAsFixed(0)} kg',
                      l['volume']),
                ],
              ),
              const SizedBox(height: 40),
              TbButton(
                label: '🏠 ${l['home']}',
                onPressed: () {
                  ref.read(activeSessionProvider.notifier).reset();
                  ref.read(navIndexProvider.notifier).state = 0;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneStat extends StatelessWidget {
  final String value;
  final String label;
  const _DoneStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
      ],
    );
  }
}
