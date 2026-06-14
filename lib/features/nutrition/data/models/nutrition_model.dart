// lib/features/nutrition/data/models/nutrition_model.dart

class FoodEntry {
  final String id;
  final String name;
  final double amount; // grams
  final String mealType;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final DateTime addedAt;

  const FoodEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    required this.addedAt,
  });

  FoodEntry scaledTo(double newAmount) {
    final factor = newAmount / amount;
    return FoodEntry(
      id: id,
      name: name,
      amount: newAmount,
      mealType: mealType,
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'mealType': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'addedAt': addedAt.toIso8601String(),
      };

  factory FoodEntry.fromMap(Map<String, dynamic> m) => FoodEntry(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        amount: double.tryParse(m['amount']?.toString() ?? '0') ?? 0,
        mealType: m['mealType']?.toString() ?? 'snack',
        calories: double.tryParse(m['calories']?.toString() ?? '0') ?? 0,
        protein: double.tryParse(m['protein']?.toString() ?? '0') ?? 0,
        carbs: double.tryParse(m['carbs']?.toString() ?? '0') ?? 0,
        fat: double.tryParse(m['fat']?.toString() ?? '0') ?? 0,
        fiber: double.tryParse(m['fiber']?.toString() ?? '0') ?? 0,
        addedAt: DateTime.tryParse(m['addedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class NutritionTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  const NutritionTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory NutritionTotals.empty() =>
      const NutritionTotals(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0);

  NutritionTotals operator +(NutritionTotals other) => NutritionTotals(
        calories: calories + other.calories,
        protein: protein + other.protein,
        carbs: carbs + other.carbs,
        fat: fat + other.fat,
        fiber: fiber + other.fiber,
      );
}

class NutritionGoals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class NutritionLog {
  final String uid;
  final String date;
  final List<FoodEntry> entries;
  final double waterLiters;

  const NutritionLog({
    required this.uid,
    required this.date,
    required this.entries,
    this.waterLiters = 0,
  });

  NutritionTotals get totals {
    return entries.fold(
      NutritionTotals.empty(),
      (sum, e) => NutritionTotals(
        calories: sum.calories + e.calories,
        protein: sum.protein + e.protein,
        carbs: sum.carbs + e.carbs,
        fat: sum.fat + e.fat,
        fiber: sum.fiber + e.fiber,
      ),
    );
  }

  List<FoodEntry> entriesForType(String mealType) =>
      entries.where((e) => e.mealType == mealType).toList();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'date': date,
        'entries': entries.map((e) => e.toMap()).toList(),
        'waterLiters': waterLiters,
      };

  factory NutritionLog.fromMap(Map<String, dynamic> m) {
    final rawEntries = m['entries'];
    final entries = rawEntries is List
        ? rawEntries
            .map((e) => FoodEntry.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <FoodEntry>[];
    return NutritionLog(
      uid: m['uid']?.toString() ?? '',
      date: m['date']?.toString() ?? '',
      entries: entries,
      waterLiters:
          double.tryParse(m['waterLiters']?.toString() ?? '0') ?? 0,
    );
  }

  NutritionLog copyWith({
    List<FoodEntry>? entries,
    double? waterLiters,
  }) =>
      NutritionLog(
        uid: uid,
        date: date,
        entries: entries ?? this.entries,
        waterLiters: waterLiters ?? this.waterLiters,
      );
}

// Built-in food database (100g basis)
class FoodDatabase {
  static const List<Map<String, dynamic>> items = [
    {'name': 'Chicken Breast (cooked)', 'cal': 165, 'p': 31, 'c': 0, 'f': 3.6},
    {'name': 'Eggs (whole)', 'cal': 155, 'p': 13, 'c': 1.1, 'f': 11},
    {'name': 'Egg White', 'cal': 52, 'p': 11, 'c': 0.7, 'f': 0.2},
    {'name': 'Tuna (canned)', 'cal': 116, 'p': 26, 'c': 0, 'f': 1},
    {'name': 'Salmon', 'cal': 208, 'p': 20, 'c': 0, 'f': 13},
    {'name': 'Beef (lean)', 'cal': 250, 'p': 26, 'c': 0, 'f': 15},
    {'name': 'White Rice (cooked)', 'cal': 130, 'p': 2.7, 'c': 28, 'f': 0.3},
    {'name': 'Brown Rice (cooked)', 'cal': 112, 'p': 2.6, 'c': 23, 'f': 0.9},
    {'name': 'Oats (dry)', 'cal': 389, 'p': 17, 'c': 66, 'f': 7},
    {'name': 'Sweet Potato', 'cal': 86, 'p': 1.6, 'c': 20, 'f': 0.1},
    {'name': 'Potato (boiled)', 'cal': 87, 'p': 1.9, 'c': 20, 'f': 0.1},
    {'name': 'Bread (white)', 'cal': 265, 'p': 9, 'c': 49, 'f': 3.2},
    {'name': 'Pasta (cooked)', 'cal': 131, 'p': 5, 'c': 25, 'f': 1.1},
    {'name': 'Greek Yogurt (0%)', 'cal': 59, 'p': 10, 'c': 3.6, 'f': 0.4},
    {'name': 'Milk (whole)', 'cal': 61, 'p': 3.2, 'c': 4.8, 'f': 3.3},
    {'name': 'Cottage Cheese', 'cal': 98, 'p': 11, 'c': 3.4, 'f': 4.3},
    {'name': 'Banana', 'cal': 89, 'p': 1.1, 'c': 23, 'f': 0.3},
    {'name': 'Apple', 'cal': 52, 'p': 0.3, 'c': 14, 'f': 0.2},
    {'name': 'Orange', 'cal': 47, 'p': 0.9, 'c': 12, 'f': 0.1},
    {'name': 'Avocado', 'cal': 160, 'p': 2, 'c': 9, 'f': 15},
    {'name': 'Almonds', 'cal': 579, 'p': 21, 'c': 22, 'f': 50},
    {'name': 'Peanut Butter', 'cal': 588, 'p': 25, 'c': 20, 'f': 50},
    {'name': 'Olive Oil', 'cal': 884, 'p': 0, 'c': 0, 'f': 100},
    {'name': 'Lentils (cooked)', 'cal': 116, 'p': 9, 'c': 20, 'f': 0.4},
    {'name': 'Broccoli', 'cal': 34, 'p': 2.8, 'c': 7, 'f': 0.4},
    {'name': 'Spinach', 'cal': 23, 'p': 2.9, 'c': 3.6, 'f': 0.4},
    {'name': 'Whey Protein (1 scoop=30g)', 'cal': 120, 'p': 24, 'c': 3, 'f': 1},
    {'name': 'دجاج مشوي', 'cal': 165, 'p': 31, 'c': 0, 'f': 3.6},
    {'name': 'أرز أبيض مطبوخ', 'cal': 130, 'p': 2.7, 'c': 28, 'f': 0.3},
    {'name': 'بيض كامل', 'cal': 155, 'p': 13, 'c': 1.1, 'f': 11},
    {'name': 'خبز توست', 'cal': 265, 'p': 9, 'c': 49, 'f': 3.2},
    {'name': 'لبن زبادي يوناني', 'cal': 59, 'p': 10, 'c': 3.6, 'f': 0.4},
    {'name': 'بطاطا حلوة', 'cal': 86, 'p': 1.6, 'c': 20, 'f': 0.1},
    {'name': 'شوفان جاف', 'cal': 389, 'p': 17, 'c': 66, 'f': 7},
    {'name': 'سمك تونا معلب', 'cal': 116, 'p': 26, 'c': 0, 'f': 1},
    {'name': 'موز', 'cal': 89, 'p': 1.1, 'c': 23, 'f': 0.3},
    {'name': 'لوز', 'cal': 579, 'p': 21, 'c': 22, 'f': 50},
  ];

  static List<Map<String, dynamic>> search(String query) {
    final q = query.toLowerCase();
    return items
        .where((f) => f['name'].toString().toLowerCase().contains(q))
        .toList();
  }
}

class NutritionModel {
  static const mealTypes = _MealTypes();
}

class _MealTypes {
  const _MealTypes();
  String get breakfast => 'breakfast';
  String get lunch => 'lunch';
  String get dinner => 'dinner';
  String get snack => 'snack';
  List<String> get all => ['breakfast', 'lunch', 'dinner', 'snack'];
}
