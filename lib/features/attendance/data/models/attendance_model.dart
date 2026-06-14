// lib/features/attendance/data/models/attendance_model.dart

class AttendanceMark {
  AttendanceMark._();
  static const String gym    = 'gym';
  static const String absent = 'absent';
  static const String rest   = 'rest';

  static String emoji(String mark) {
    switch (mark) {
      case gym:    return '✔';
      case absent: return '✘';
      case rest:   return '🛌';
      default:     return '';
    }
  }
}
