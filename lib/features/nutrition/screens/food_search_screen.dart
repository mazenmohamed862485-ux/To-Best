// lib/features/nutrition/screens/food_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/nutrition_model.dart';
import '../providers/nutrition_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/tb_snackbar.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  final String? defaultMealType;
  const FoodSearchScreen({super.key, this.defaultMealType});
  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '100');
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  late String _mealType;

  @override
  void initState() {
    super.initState();
    _mealType = widget.defaultMealType ?? 'breakfast';
    _results = FoodDatabase.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    setState(() {
      _results = q.isEmpty ? FoodDatabase.items : FoodDatabase.search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l['addFood'])),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: l['searchFood'],
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search('');
                            })
                        : null,
                  ),
                ),
                if (_selected != null) ...[
                  const SizedBox(height: 12),
                  _AddFoodPanel(
                    food: _selected!,
                    amountCtrl: _amountCtrl,
                    mealType: _mealType,
                    onMealTypeChanged: (v) => setState(() => _mealType = v),
                    onAdd: _addFood,
                    l: l,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final food = _results[i];
                final isSelected = _selected == food;
                return ListTile(
                  selected: isSelected,
                  selectedColor: AppColors.primaryGreen,
                  selectedTileColor: AppColors.primaryGreen.withOpacity(0.1),
                  title: Text(food['name'] as String,
                      style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '${food['cal']} kcal • P:${food['p']}g C:${food['c']}g F:${food['f']}g',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
                      : null,
                  onTap: () => setState(() {
                    _selected = isSelected ? null : food;
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addFood() {
    if (_selected == null) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 100;
    final entry = ref.read(nutritionProvider.notifier).buildEntry(
          _selected!,
          amount,
          _mealType,
        );
    ref.read(nutritionProvider.notifier).addEntry(entry);
    TbSnackbar.show(context, '${_selected!['name']} ${AppLocalizations.of(context)['saved']}',
        isSuccess: true);
    Navigator.pop(context);
  }
}

class _AddFoodPanel extends StatelessWidget {
  final Map<String, dynamic> food;
  final TextEditingController amountCtrl;
  final String mealType;
  final void Function(String) onMealTypeChanged;
  final VoidCallback onAdd;
  final AppLocalizations l;
  final bool isDark;

  const _AddFoodPanel({
    required this.food,
    required this.amountCtrl,
    required this.mealType,
    required this.onMealTypeChanged,
    required this.onAdd,
    required this.l,
    required this.isDark,
  });

  double get factor => (double.tryParse(amountCtrl.text) ?? 100) / 100;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(food['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l['amount'],
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => (context as Element).markNeedsBuild(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: mealType,
                onChanged: (v) => onMealTypeChanged(v!),
                items: [
                  DropdownMenuItem(value: 'breakfast', child: Text(l['breakfast'])),
                  DropdownMenuItem(value: 'lunch', child: Text(l['lunch'])),
                  DropdownMenuItem(value: 'dinner', child: Text(l['dinner'])),
                  DropdownMenuItem(value: 'snack', child: Text(l['snack'])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${((food['cal'] as num) * factor).toStringAsFixed(0)} kcal • P:${((food['p'] as num) * factor).toStringAsFixed(1)}g',
            style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(l['addFood']),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Meal Plan Screen
class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: AppColors.primaryGreen),
            const SizedBox(height: 16),
            Text(l['mealPlan'], style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('خطة الوجبات الخاصة بك من المدرب',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _MealSuggestionsList(l: l),
          ],
        ),
      ),
    );
  }
}

class _MealSuggestionsList extends StatelessWidget {
  final AppLocalizations l;
  const _MealSuggestionsList({required this.l});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      {'meal': l['breakfast'], 'desc': 'شوفان + بيض + موز', 'cals': '450'},
      {'meal': l['lunch'], 'desc': 'أرز + دجاج + بروكلي', 'cals': '600'},
      {'meal': l['snack'], 'desc': 'زبادي يوناني + لوز', 'cals': '200'},
      {'meal': l['dinner'], 'desc': 'تونة + خبز + خضروات', 'cals': '400'},
    ];
    return Column(
      children: suggestions.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['meal']!,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(s['desc']!, style: const TextStyle(fontSize: 12)),
            ]),
            const Spacer(),
            Text('${s['cals']} kcal',
                style: const TextStyle(
                    color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
          ],
        ),
      )).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Water Tracker Screen
class WaterTrackerScreen extends ConsumerWidget {
  const WaterTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final water = ref.watch(waterProvider);
    final user = ref.watch(authProvider).user;
    final goal = user?.dailyWater ?? 2.5;
    final pct = (water / goal).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Water circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.info.withOpacity(0.3), width: 4),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 12,
                    backgroundColor: AppColors.info.withOpacity(0.15),
                    color: AppColors.info,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, color: AppColors.info, size: 32),
                    Text('${water.toStringAsFixed(1)}L',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.info)),
                    Text('/ ${goal.toStringAsFixed(1)}L',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.darkTextSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Quick add buttons
          Text(l['addFood'], style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [0.1, 0.2, 0.25, 0.3, 0.5, 1.0].map((ml) {
              return ElevatedButton(
                onPressed: () =>
                    ref.read(waterProvider.notifier).add(ml),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info.withOpacity(0.15),
                  foregroundColor: AppColors.info,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.info, width: 0.5),
                ),
                child: Text('+${ml}L'),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Custom input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${l['waterGoal']} (L)',
                    hintText: '0.0',
                  ),
                  onChanged: (v) {
                    final d = double.tryParse(v);
                    if (d != null)
                      ref.read(waterProvider.notifier).add(d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.read(waterProvider.notifier).reset(),
            icon: const Icon(Icons.restart_alt, color: AppColors.error),
            label: Text('Reset',
                style: const TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
