// lib/features/progress/providers/progress_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/workout/providers/workout_provider.dart';

final progressProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return {};
  final repo = ref.read(workoutRepositoryProvider);
  final prs = await repo.getLatestPRs(user.uid);
  final volume = await repo.getVolumeChartData(user.uid);
  final stats = await repo.getStats(user.uid);
  return {'prs': prs, 'volume': volume, 'stats': stats};
});
