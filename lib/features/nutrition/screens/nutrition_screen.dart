// lib/features/nutrition/screens/nutrition_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tb_snackbar.dart';
import '../../../shared/widgets/tb_button.dart';
import '../providers/nutrition_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/models/nutrition_model.dart';
import 'food_search_screen.dart';
import 'meal_plan_screen.dart';
import 'water_tracker_screen.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});
  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l['nutrition']),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: l['loggedMeals']),
            Tab(text: l['mealPlan']),
            Tab(text: l['water']),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _DailyLogTab(l: l, isDark: isDark),
          const MealPlanScreen(),
          const WaterTrackerScreen(),
        ],
      ),
    );
  }
}

// ── Daily Log Tab ─────────────────────────────────────────────
class _DailyLogTab extends ConsumerWidget {
  final AppLocalizations l;
  final bool isDark;
  const _DailyLogTab({required this.l, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final todayLogAsync = ref.watch(todayNutritionProvider);
    final goals = NutritionGoals(
      calories: user?.dailyCalories ?? 2000,
      protein: user?.dailyProtein ?? 150,
      carbs: user?.dailyCarbs ?? 200,
      fat: user?.dailyFat ?? 70,
    );

    return todayLogAsync.when(
      data: (log) => _buildContent(context, ref, log, goals),
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      NutritionLog? log, NutritionGoals goals) {
    final totals = log?.totals ?? NutritionTotals.empty();
    final water = log?.waterLiters ?? 0;

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () => ref.refresh(todayNutritionProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Macro rings
            _MacroSummary(totals: totals, goals: goals, isDark: isDark, l: l),
            const SizedBox(height: 16),

            // Water summary
            _WaterSummary(liters: water, goal: 2.5, l: l, isDark: isDark),
            const SizedBox(height: 16),

            // Add food button
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l['addFood']),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 16),

            // Meals by type
            ...[
              NutritionModel.mealTypes.breakfast,
              NutritionModel.mealTypes.lunch,
              NutritionModel.mealTypes.dinner,
              NutritionModel.mealTypes.snack,
            ].map((mealType) => _MealTypeSection(
                  mealType: mealType,
                  entries: log?.entriesForType(mealType) ?? [],
                  isDark: isDark,
                  l: l,
                  ref: ref,
                )),
          ],
        ),
      ),
    );
  }
}

// Macro Summary with progress bars
class _MacroSummary extends StatelessWidget {
  final NutritionTotals totals;
  final NutritionGoals goals;
  final bool isDark;
  final AppLocalizations l;
  const _MacroSummary({
    required this.totals,
    required this.goals,
    required this.isDark,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final remCal = (goals.calories - totals.calories).clamp(0, 9999).toInt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.12),
            AppColors.primaryGreen.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Calories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l['calories'],
                    style: const TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                Text('${totals.calories.toInt()}',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(l['target'],
                    style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                Text('${goals.calories.toInt()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(l['remaining'],
                    style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                Text('$remCal',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: remCal > 0 ? AppColors.success : AppColors.error)),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goals.calories > 0
                  ? (totals.calories / goals.calories).clamp(0, 1)
                  : 0,
              minHeight: 8,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              color: totals.calories > goals.calories
                  ? AppColors.error
                  : AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          // Macros row
          Row(
            children: [
              _MacroBar(label: l['protein'], current: totals.protein,
                  goal: goals.protein, color: AppColors.info, unit: 'g'),
              const SizedBox(width: 8),
              _MacroBar(label: l['carbs'], current: totals.carbs,
                  goal: goals.carbs, color: AppColors.warning, unit: 'g'),
              const SizedBox(width: 8),
              _MacroBar(label: l['fat'], current: totals.fat,
                  goal: goals.fat, color: AppColors.error, unit: 'g'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;
  final String unit;
  const _MacroBar({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('${current.toInt()} / ${goal.toInt()}$unit',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal > 0 ? (current / goal).clamp(0, 1) : 0,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.2),
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

class _WaterSummary extends StatelessWidget {
  final double liters;
  final double goal;
  final AppLocalizations l;
  final bool isDark;
  const _WaterSummary({
    required this.liters,
    required this.goal,
    required this.l,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: AppColors.info, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${liters.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)} L',
                    style: const TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: goal > 0 ? (liters / goal).clamp(0, 1) : 0,
                  backgroundColor: AppColors.info.withOpacity(0.2),
                  color: AppColors.info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTypeSection extends StatelessWidget {
  final String mealType;
  final List<FoodEntry> entries;
  final bool isDark;
  final AppLocalizations l;
  final WidgetRef ref;
  const _MealTypeSection({
    required this.mealType,
    required this.entries,
    required this.isDark,
    required this.l,
    required this.ref,
  });

  String _mealLabel() {
    switch (mealType) {
      case 'breakfast': return l['breakfast'];
      case 'lunch': return l['lunch'];
      case 'dinner': return l['dinner'];
      default: return l['snack'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cals = entries.fold<double>(0, (s, e) => s + e.calories);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_mealLabel(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(width: 8),
              Text('${cals.toInt()} kcal',
                  style: const TextStyle(
                      color: AppColors.primaryGreen, fontSize: 12)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppColors.primaryGreen, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodSearchScreen(defaultMealType: mealType),
                  ),
                ),
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Text(l['noFoodToday'],
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted)),
            )
          else
            ...entries.map((e) => _FoodEntryTile(entry: e, isDark: isDark, ref: ref)),
        ],
      ),
    );
  }
}

class _FoodEntryTile extends StatelessWidget {
  final FoodEntry entry;
  final bool isDark;
  final WidgetRef ref;
  const _FoodEntryTile({required this.entry, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${entry.amount}g • P:${entry.protein.toInt()}g C:${entry.carbs.toInt()}g F:${entry.fat.toInt()}g',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)),
              ],
            ),
          ),
          Text('${entry.calories.toInt()} kcal',
              style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.error),
            onPressed: () => ref.read(nutritionProvider.notifier).removeEntry(entry.id),
          ),
        ],
      ),
    );
  }
}
