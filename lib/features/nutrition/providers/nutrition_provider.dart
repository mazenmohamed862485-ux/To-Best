// lib/features/nutrition/providers/nutrition_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/nutrition_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';

final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, AsyncValue<NutritionLog?>>((ref) {
  return NutritionNotifier(ref);
});

final todayNutritionProvider = FutureProvider<NutritionLog?>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return null;
  final db = ref.read(localDbProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final raw = await db.getNutritionLog(user.uid, today);
  if (raw == null) return null;
  return NutritionLog.fromMap(raw);
});

class NutritionNotifier extends StateNotifier<AsyncValue<NutritionLog?>> {
  final Ref _ref;
  static const _uuid = Uuid();

  NutritionNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final user = _ref.read(authProvider).user;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final db = _ref.read(localDbProvider);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final raw = await db.getNutritionLog(user.uid, today);
      state = AsyncValue.data(raw != null ? NutritionLog.fromMap(raw) : null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  NutritionLog _current(String uid) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return state.asData?.value ??
        NutritionLog(uid: uid, date: today, entries: []);
  }

  Future<void> addEntry(FoodEntry entry) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    final log = _current(user.uid);
    final updated = log.copyWith(entries: [...log.entries, entry]);
    await _save(user.uid, updated);
  }

  Future<void> removeEntry(String entryId) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    final log = _current(user.uid);
    final updated = log.copyWith(
        entries: log.entries.where((e) => e.id != entryId).toList());
    await _save(user.uid, updated);
  }

  Future<void> updateWater(double liters) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    final log = _current(user.uid);
    final updated = log.copyWith(waterLiters: liters);
    await _save(user.uid, updated);
  }

  Future<void> _save(String uid, NutritionLog log) async {
    state = AsyncValue.data(log);
    final db = _ref.read(localDbProvider);
    await db.upsertNutritionLog(uid, log.toMap());
    _ref.read(syncServiceProvider).queueNutritionLog(uid, log.toMap());
  }

  FoodEntry buildEntry(Map<String, dynamic> food, double amount, String mealType) {
    final factor = amount / 100;
    return FoodEntry(
      id: _uuid.v4(),
      name: food['name'] as String,
      amount: amount,
      mealType: mealType,
      calories: ((food['cal'] as num) * factor).toDouble(),
      protein: ((food['p'] as num) * factor).toDouble(),
      carbs: ((food['c'] as num) * factor).toDouble(),
      fat: ((food['f'] as num) * factor).toDouble(),
      addedAt: DateTime.now(),
    );
  }
}

// Water provider
final waterProvider = StateNotifierProvider<WaterNotifier, double>((ref) {
  return WaterNotifier(ref);
});

class WaterNotifier extends StateNotifier<double> {
  final Ref _ref;
  WaterNotifier(this._ref) : super(0) {
    _load();
  }

  Future<void> _load() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    final db = _ref.read(localDbProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final raw = await db.getNutritionLog(user.uid, today);
    if (raw != null) {
      state = double.tryParse(raw['waterLiters']?.toString() ?? '0') ?? 0;
    }
  }

  Future<void> add(double liters) async {
    state = state + liters;
    _ref.read(nutritionProvider.notifier).updateWater(state);
  }

  Future<void> setAmount(double liters) async {
    state = liters;
    _ref.read(nutritionProvider.notifier).updateWater(state);
  }

  void reset() {
    state = 0;
    _ref.read(nutritionProvider.notifier).updateWater(0);
  }
}
