// lib/shared/extensions/context_extensions.dart
import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

extension ContextX on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
  ThemeData get theme => Theme.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  MediaQueryData get mq => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

// lib/shared/extensions/date_extensions.dart
extension DateTimeX on DateTime {
  String toDateString() =>
      '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  String toTimeString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String toDisplayDate({bool arabic = true}) {
    final months_ar = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final months_en = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = arabic ? months_ar[month - 1] : months_en[month - 1];
    return arabic ? '$day $m $year' : '$day $m $year';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  int get daysAgo =>
      DateTime.now().difference(this).inDays;
}

// lib/shared/extensions/string_extensions.dart
extension StringX on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;

  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  bool get isValidPhone =>
      RegExp(r'^\+?[0-9]{7,15}$').hasMatch(trim());

  double? toDoubleOrNull() => double.tryParse(trim());
  int? toIntOrNull() => int.tryParse(trim());

  String truncate(int maxLen) =>
      length <= maxLen ? this : '${substring(0, maxLen)}…';
}

// lib/shared/extensions/num_extensions.dart
extension DoubleX on double {
  String toCleanString() {
    if (this == truncateToDouble()) return toInt().toString();
    return toStringAsFixed(1);
  }
}

extension IntX on int {
  String toDurationString() {
    final h = this ~/ 3600;
    final m = (this % 3600) ~/ 60;
    final s = this % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
