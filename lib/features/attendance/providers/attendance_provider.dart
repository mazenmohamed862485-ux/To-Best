// lib/features/attendance/providers/attendance_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, Map<String, String>>((ref) {
  return AttendanceNotifier(ref);
});

class AttendanceNotifier extends StateNotifier<Map<String, String>> {
  final Ref _ref;
  String _currentYM = '';

  AttendanceNotifier(this._ref) : super({}) {
    _loadCurrentMonth();
  }

  String get _ym {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadCurrentMonth() async {
    _currentYM = _ym;
    await loadMonth(_currentYM);
  }

  Future<void> loadMonth(String yearMonth) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    _currentYM = yearMonth;
    final db = _ref.read(localDbProvider);
    final data = await db.getAttendanceForMonth(user.uid, yearMonth);
    state = data;
  }

  Future<void> markDay(String date, String mark) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    state = {...state, date: mark};
    _ref.read(syncServiceProvider).queueAttendance(user.uid, date, mark);
  }

  Future<void> removeDay(String date) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    final updated = Map<String, String>.from(state);
    updated.remove(date);
    state = updated;
  }

  Map<String, int> get stats {
    int gym = 0, absent = 0, rest = 0;
    for (final v in state.values) {
      if (v == 'gym') gym++;
      else if (v == 'absent') absent++;
      else if (v == 'rest') rest++;
    }
    final total = gym + absent;
    final pct = total > 0 ? (gym / total * 100).round() : 0;
    return {'gym': gym, 'absent': absent, 'rest': rest, 'pct': pct};
  }

  String get currentYM => _currentYM;
}
