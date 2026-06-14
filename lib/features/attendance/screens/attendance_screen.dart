// lib/features/attendance/screens/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/attendance_provider.dart';
import '../../../shared/widgets/tb_snackbar.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _viewMonth = DateTime.now();

  String get _ym =>
      '${_viewMonth.year}-${_viewMonth.month.toString().padLeft(2, '0')}';

  void _prevMonth() {
    setState(() =>
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));
    ref.read(attendanceProvider.notifier).loadMonth(_ym);
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_viewMonth.year == now.year && _viewMonth.month == now.month) return;
    setState(() =>
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));
    ref.read(attendanceProvider.notifier).loadMonth(_ym);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final attendance = ref.watch(attendanceProvider);
    final stats = ref.read(attendanceProvider.notifier).stats;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrentMonth = _viewMonth.year == DateTime.now().year &&
        _viewMonth.month == DateTime.now().month;

    return Scaffold(
      appBar: AppBar(title: Text(l['attendance'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Month navigator ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  _monthLabel(l),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right,
                      color: isCurrentMonth
                          ? AppColors.darkTextMuted
                          : null),
                  onPressed: isCurrentMonth ? null : _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Stats row ────────────────────────────────────
            Row(
              children: [
                _StatChip(label: l['gymDays'],
                    value: '${stats['gym']}',
                    color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                _StatChip(label: l['absentDays'],
                    value: '${stats['absent']}',
                    color: AppColors.error),
                const SizedBox(width: 8),
                _StatChip(label: l['restDays'],
                    value: '${stats['rest']}',
                    color: AppColors.warning),
                const SizedBox(width: 8),
                _StatChip(label: l['commitment'],
                    value: '${stats['pct']}%',
                    color: AppColors.info),
              ],
            ),
            const SizedBox(height: 16),

            // ── Calendar grid ────────────────────────────────
            _CalendarGrid(
              viewMonth: _viewMonth,
              attendance: attendance,
              isDark: isDark,
              l: l,
              onDayTap: isCurrentMonth ? _onDayTap : null,
            ),
            const SizedBox(height: 16),

            // ── Today mark buttons ───────────────────────────
            if (isCurrentMonth) ...[
              Text(l['tapToMark'],
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MarkButton(
                      label: l['gym'],
                      color: AppColors.primaryGreen,
                      icon: Icons.fitness_center,
                      onTap: () => _markToday('gym'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MarkButton(
                      label: l['absent'],
                      color: AppColors.error,
                      icon: Icons.close,
                      onTap: () => _markToday('absent'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MarkButton(
                      label: l['restMark'],
                      color: AppColors.warning,
                      icon: Icons.hotel,
                      onTap: () => _markToday('rest'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _monthLabel(AppLocalizations l) {
    final months = [
      l['jan'], l['feb'], l['mar'], l['apr'],
      l['may'], l['jun'], l['jul'], l['aug'],
      l['sep'], l['oct'], l['nov'], l['dec'],
    ];
    return '${months[_viewMonth.month - 1]} ${_viewMonth.year}';
  }

  Future<void> _onDayTap(String date, String? current) async {
    final l = AppLocalizations.of(context);
    final options = ['gym', 'absent', 'rest'];
    final labels = [l['gym'], l['absent'], l['restMark']];
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(date,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1),
            ...List.generate(options.length, (i) => ListTile(
                  title: Text(labels[i]),
                  leading: Icon(
                      options[i] == 'gym'
                          ? Icons.fitness_center
                          : options[i] == 'absent'
                              ? Icons.close
                              : Icons.hotel,
                      color: options[i] == 'gym'
                          ? AppColors.primaryGreen
                          : options[i] == 'absent'
                              ? AppColors.error
                              : AppColors.warning),
                  trailing: current == options[i]
                      ? const Icon(Icons.check, color: AppColors.primaryGreen)
                      : null,
                  onTap: () => Navigator.pop(ctx, options[i]),
                )),
            if (current != null)
              ListTile(
                title: Text(l['delete'],
                    style: const TextStyle(color: AppColors.error)),
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                onTap: () => Navigator.pop(ctx, '__remove__'),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    if (chosen == '__remove__') {
      ref.read(attendanceProvider.notifier).removeDay(date);
    } else {
      ref.read(attendanceProvider.notifier).markDay(date, chosen);
    }
    if (mounted) {
      TbSnackbar.show(context, l['saved'], isSuccess: true);
    }
  }

  void _markToday(String mark) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    ref.read(attendanceProvider.notifier).markDay(today, mark);
    final l = AppLocalizations.of(context);
    TbSnackbar.show(context, l['saved'], isSuccess: true);
  }
}

// ── Calendar Grid ─────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime viewMonth;
  final Map<String, String> attendance;
  final bool isDark;
  final AppLocalizations l;
  final void Function(String date, String? current)? onDayTap;

  const _CalendarGrid({
    required this.viewMonth,
    required this.attendance,
    required this.isDark,
    required this.l,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
    final daysInMonth = DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    // Monday=1 ... Sunday=7 → offset (Mon-based)
    int offset = firstDay.weekday - 1;

    final dayHeaders = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Column(
      children: [
        // Day headers
        Row(
          children: dayHeaders.map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: d == 'Fr' || d == 'Sa'
                              ? AppColors.primaryGreen
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
                ),
              )).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: offset + daysInMonth,
          itemBuilder: (ctx, idx) {
            if (idx < offset) return const SizedBox();
            final day = idx - offset + 1;
            final dateStr =
                '${viewMonth.year}-${viewMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            final mark = attendance[dateStr];
            final isToday = dateStr ==
                DateTime.now().toIso8601String().substring(0, 10);

            return GestureDetector(
              onTap: onDayTap != null
                  ? () => onDayTap!(dateStr, mark)
                  : null,
              child: _DayCell(
                day: day,
                mark: mark,
                isToday: isToday,
                isDark: isDark,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String? mark;
  final bool isToday;
  final bool isDark;

  const _DayCell({
    required this.day,
    this.mark,
    required this.isToday,
    required this.isDark,
  });

  Color _bg() {
    switch (mark) {
      case 'gym': return AppColors.primaryGreen;
      case 'absent': return AppColors.error;
      case 'rest': return AppColors.warning;
      default: return isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    }
  }

  String _label() {
    switch (mark) {
      case 'gym': return '✔';
      case 'absent': return '✘';
      case 'rest': return '🛌';
      default: return '$day';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: AppColors.primaryGreen, width: 2)
            : null,
      ),
      child: Center(
        child: mark != null
            ? Text(_label(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700))
            : Text('$day',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isToday
                        ? AppColors.primaryGreen
                        : (isDark
                            ? AppColors.darkText
                            : AppColors.lightText))),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: color.withOpacity(0.8)),
                textAlign: TextAlign.center,
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _MarkButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
