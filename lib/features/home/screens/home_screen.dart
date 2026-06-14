// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/tb_snackbar.dart';
import '../../workout/providers/workout_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import 'main_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l['appName']),
        actions: [
          if (user?.pictureUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(user!.pictureUrl!),
                backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                child: Text(
                  (user?.name.isNotEmpty == true)
                      ? user!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ──────────────────────────────────
              _GreetingCard(user: user, l: l, isDark: isDark),
              const SizedBox(height: 16),

              // ── Today's Session ───────────────────────────
              _TodaySessionCard(l: l, isDark: isDark),
              const SizedBox(height: 16),

              // ── Stats Row ─────────────────────────────────
              _StatsRow(l: l, isDark: isDark),
              const SizedBox(height: 16),

              // ── Quick Access ──────────────────────────────
              Text(l['quickAccess'],
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _QuickAccessGrid(l: l),
              const SizedBox(height: 16),

              // ── Latest PRs ────────────────────────────────
              _LatestPRsCard(l: l, isDark: isDark),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting Card ─────────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  final dynamic user;
  final AppLocalizations l;
  final bool isDark;
  const _GreetingCard({required this.user, required this.l, required this.isDark});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return l['greeting_morning'];
    if (h < 18) return l['greeting_afternoon'];
    return l['greeting_evening'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.15),
            AppColors.primaryGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryGreen)),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? '',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700),
                ),
                if (user?.role != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user!.role.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.fitness_center,
              size: 48, color: AppColors.primaryGreen),
        ],
      ),
    );
  }
}

// ── Today's Session Card ──────────────────────────────────────
class _TodaySessionCard extends ConsumerWidget {
  final AppLocalizations l;
  final bool isDark;
  const _TodaySessionCard({required this.l, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySession = ref.watch(todaySessionProvider);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).state = 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                todaySession != null
                    ? Icons.play_circle_outline
                    : Icons.hotel_outlined,
                color: AppColors.primaryGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todaySession != null
                        ? l['todaySession']
                        : l['restDay'],
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todaySession ?? l['noSession'],
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryGreen),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (todaySession != null)
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────
class _StatsRow extends ConsumerWidget {
  final AppLocalizations l;
  final bool isDark;
  const _StatsRow({required this.l, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(workoutStatsProvider);

    return Row(
      children: [
        Expanded(child: _StatCard(
          value: stats['total']?.toString() ?? '0',
          label: l['totalSessions'],
          icon: Icons.fitness_center,
          color: AppColors.primaryGreen,
          isDark: isDark,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          value: '${stats['streak'] ?? 0}🔥',
          label: l['streak'],
          icon: Icons.local_fire_department,
          color: AppColors.warning,
          isDark: isDark,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          value: stats['daysAgo']?.toString() ?? '-',
          label: l['daysSince'],
          icon: Icons.calendar_month,
          color: AppColors.info,
          isDark: isDark,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              textAlign: TextAlign.center,
              maxLines: 2),
        ],
      ),
    );
  }
}

// ── Quick Access Grid ─────────────────────────────────────────
class _QuickAccessGrid extends ConsumerWidget {
  final AppLocalizations l;
  const _QuickAccessGrid({required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _QA(Icons.fitness_center, l['workout'], 1, AppColors.primaryGreen),
      _QA(Icons.restaurant, l['nutrition'], 2, AppColors.info),
      _QA(Icons.calendar_today, l['attendance'], 3, AppColors.warning),
      _QA(Icons.trending_up, l['progress'], 4, AppColors.success),
      _QA(Icons.chat, l['chat'], 5, AppColors.evalGD),
      _QA(Icons.settings, l['settings'], 6, AppColors.darkTextSecondary),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: items.map((q) => _QuickAccessTile(q: q, ref: ref)).toList(),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final int navIndex;
  final Color color;
  _QA(this.icon, this.label, this.navIndex, this.color);
}

class _QuickAccessTile extends StatelessWidget {
  final _QA q;
  final WidgetRef ref;
  const _QuickAccessTile({required this.q, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).state = q.navIndex,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(q.icon, color: q.color, size: 28),
            const SizedBox(height: 6),
            Text(q.label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkText
                        : AppColors.lightText),
                textAlign: TextAlign.center,
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}

// ── Latest PRs ────────────────────────────────────────────────
class _LatestPRsCard extends ConsumerWidget {
  final AppLocalizations l;
  final bool isDark;
  const _LatestPRsCard({required this.l, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prs = ref.watch(latestPRsProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(l['latestPRs'], style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          if (prs.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(l['noPRs'],
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                  const SizedBox(height: 4),
                  Text(l['noPRsDesc'],
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                ],
              ),
            )
          else
            ...prs.take(5).map((pr) => _PRRow(pr: pr, isDark: isDark)),
        ],
      ),
    );
  }
}

class _PRRow extends StatelessWidget {
  final Map<String, dynamic> pr;
  final bool isDark;
  const _PRRow({required this.pr, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.evalS1, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(pr['exercise'] ?? '',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            '${pr['weight']} kg × ${pr['reps']}',
            style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
