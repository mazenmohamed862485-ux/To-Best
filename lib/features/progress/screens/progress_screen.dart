// lib/features/progress/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/progress_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dataAsync = ref.watch(progressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l['progress'])),
      body: dataAsync.when(
        data: (data) => _buildContent(context, data, l, isDark),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen)),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data,
      AppLocalizations l, bool isDark) {
    final prs =
        (data['prs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final stats =
        (data['stats'] as Map?)?.cast<String, dynamic>() ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _PStat('${stats['total'] ?? 0}', l['totalSessions'],
                AppColors.primaryGreen),
            const SizedBox(width: 12),
            _PStat('${stats['streak'] ?? 0}🔥', l['streak'],
                AppColors.warning),
            const SizedBox(width: 12),
            _PStat('${stats['daysAgo'] ?? 0}', l['daysSince'],
                AppColors.info),
          ]),
          const SizedBox(height: 24),
          Text(l['personalRecords'],
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (prs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  const Icon(Icons.emoji_events,
                      size: 56, color: AppColors.darkTextMuted),
                  const SizedBox(height: 12),
                  Text(l['noPRs']),
                ]),
              ),
            )
          else
            ...prs.map((pr) => _PRTile(pr: pr, isDark: isDark)),
        ],
      ),
    );
  }
}

class _PStat extends StatelessWidget {
  final String v, lbl;
  final Color c;
  const _PStat(this.v, this.lbl, this.c);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text(v,
                style: TextStyle(
                    color: c, fontSize: 22, fontWeight: FontWeight.w700)),
            Text(lbl,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _PRTile extends StatelessWidget {
  final Map<String, dynamic> pr;
  final bool isDark;
  const _PRTile({required this.pr, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(children: [
          const Icon(Icons.emoji_events, color: AppColors.evalS1, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pr['exercise']?.toString() ?? '',
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                  Text(pr['date']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.darkTextSecondary)),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${pr['weight']}kg × ${pr['reps']}',
                style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            Text(
                '1RM: ${(pr['epley'] as double?)?.toStringAsFixed(1) ?? '-'}kg',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkTextSecondary)),
          ]),
        ]),
      );
}
