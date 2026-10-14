import 'package:flutter/material.dart';

import '../../../../data/api/api_models.dart';
import '../../../../theme.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/charts.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/format.dart';
import '../../../../widgets/skeleton.dart';
import 'scan_meal_screen.dart';

typedef _FoodData = ({DaySummary summary, List<MealLog> meals, Analytics week});

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return ApiBuilder<_FoodData>(
      cacheKey: 'food:${apiDate(today)}',
      load: (api) async {
        final results = await Future.wait<Object>([
          api.summary(),
          api.meals(),
          api.analytics(from: today.subtract(const Duration(days: 6)), to: today),
        ]);
        return (summary: results[0] as DaySummary, meals: results[1] as List<MealLog>, week: results[2] as Analytics);
      },
      loading: const SkeletonPage(
        children: [
          SkeletonCard(ring: true, lines: 3),
          SkeletonCard(lines: 1),
          SkeletonCard(lines: 3),
          SkeletonCard(lines: 3),
        ],
      ),
      builder: (context, data) => _FoodBody(data: data),
    );
  }
}

class _FoodBody extends StatefulWidget {
  const _FoodBody({required this.data});

  final _FoodData data;

  @override
  State<_FoodBody> createState() => _FoodBodyState();
}

class _FoodBodyState extends State<_FoodBody> {
  static const _mealTimes = [('breakfast', 'Breakfast'), ('lunch', 'Lunch'), ('dinner', 'Dinner'), ('snack', 'Snack')];

  // Swiped-away items stay hidden while the delete is saved and the list reloads.
  final _deleted = <int>{};

  void _openScan([String? mealTime]) => Navigator.of(context).push(slideRoute(ScanMealScreen(mealTime: mealTime)));

  Future<void> _delete(MealLog meal) async {
    setState(() => _deleted.add(meal.id));
    final ok = await saveWithFeedback(context, (api) => api.deleteMeal(meal.id));
    if (!mounted) return;
    if (ok) {
      showToast(context, '${meal.name} removed', icon: Icons.delete_outline_rounded);
    } else {
      setState(() => _deleted.remove(meal.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.data.summary;
    final meals = widget.data.meals.where((m) => !_deleted.contains(m.id)).toList();
    final week = widget.data.week;
    final calories = summary.goal('calories');
    final kcal = calories?.current ?? 0;
    final kcalTarget = calories?.target;

    // The first main meal not logged yet, otherwise a snack.
    final next = _mealTimes.firstWhere(
      (t) => t.$1 != 'snack' && meals.every((m) => m.mealTime != t.$1),
      orElse: () => _mealTimes.last,
    );
    final foodTip = week.tips.where((t) => t.topic == 'food and nutrition' || t.topic == 'protein').firstOrNull;

    return AppRefresh(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            FadeUp(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text('Food', style: ts(28, FontWeight.w800).copyWith(letterSpacing: -0.5, height: 1.15)),
                        Text(fmtDayTitle(DateTime.now()), style: ts(14, FontWeight.w400, AppColors.muted)),
                      ],
                    ),
                  ),
                  OutlineChipButton(label: 'Search', icon: Icons.search_rounded, onTap: _openScan),
                ],
              ),
            ),

            // Calories + macros
            FadeUp(
              delayMs: 60,
              child: AppCard(
                padding: const EdgeInsets.all(18),
                radius: 20,
                child: Row(
                  spacing: 18,
                  children: [
                    ScoreRing(
                      fraction: calories?.progress ?? 0,
                      color: AppColors.orange,
                      track: AppColors.orangeTrack,
                      center: (t) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(fmtThousands(kcal * t), style: ts(24, FontWeight.w800).copyWith(height: 1)),
                          Text(
                            kcalTarget == null ? 'kcal today' : 'of ${fmtNum(kcalTarget)} kcal',
                            style: ts(12, FontWeight.w400, AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        spacing: 10,
                        children: [
                          for (final m in [
                            ('protein', 'Protein', AppColors.green, 300),
                            ('carbs', 'Carbs', AppColors.blue, 380),
                            ('fat', 'Fat', AppColors.orange, 460),
                          ])
                            if (summary.goal(m.$1) case final g?) _MacroRow(m.$2, g.current, g.target, m.$3, m.$4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scan Meal call to action
            FadeUp(
              delayMs: 120,
              child: PressScale(
                label: 'Scan Meal',
                onTap: _openScan,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    spacing: 14,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 26),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scan Meal', style: ts(16, FontWeight.w700, Colors.white)),
                            Text(
                              'Photo, barcode or search',
                              style: ts(13, FontWeight.w400, Colors.white.withValues(alpha: 0.92)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),

            // Meal list
            FadeUp(
              delayMs: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  Text('Meals', style: ts(17, FontWeight.w700)),
                  if (meals.isEmpty)
                    AppCard(
                      child: Text(
                        'Nothing logged yet today. Tap Scan Meal or the button below to add your first meal.',
                        style: ts(14, FontWeight.w400, AppColors.muted),
                      ),
                    ),
                  for (final t in _mealTimes)
                    if (meals.where((m) => m.mealTime == t.$1).toList() case final items when items.isNotEmpty)
                      _MealCard(title: t.$2, items: items, onDelete: _delete),
                  if (meals.isNotEmpty)
                    Text(
                      'Swipe an item to the left to remove it.',
                      textAlign: TextAlign.center,
                      style: ts(12, FontWeight.w400, AppColors.muted),
                    ),
                  PressScale(
                    label: 'Add ${next.$2.toLowerCase()}',
                    onTap: () => _openScan(next.$1),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFC9CED6), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          const Icon(Icons.add_rounded, color: AppColors.greenDark),
                          Text('Add ${next.$2.toLowerCase()}', style: ts(15, FontWeight.w600, AppColors.greenDark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            FadeUp(
              delayMs: 240,
              child: AppCard(
                color: AppColors.orangeCard,
                borderColor: AppColors.orangeBorder,
                child: Row(
                  spacing: 12,
                  children: [
                    const IconBadge(
                      Icons.trending_up_rounded,
                      color: AppColors.orangeDark,
                      bg: Colors.white,
                      size: 40,
                      radius: 12,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: week.healthyMealsSentence, style: ts(14, FontWeight.w700)),
                            if (foodTip != null) TextSpan(text: ' ${foodTip.text}'),
                          ],
                        ),
                        style: ts(14).copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow(this.label, this.value, this.goal, this.color, this.delayMs);

  final String label;
  final double value;
  final double? goal;
  final Color color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ts(13)),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: fmtNum(value), style: ts(13, FontWeight.w700)),
                  TextSpan(text: goal == null ? ' g' : '/${fmtNum(goal!)} g'),
                ],
              ),
              style: ts(13, FontWeight.w400, AppColors.muted),
            ),
          ],
        ),
        ProgressBar(value: goal == null || goal == 0 ? 0 : value / goal!, color: color, height: 6, delayMs: delayMs),
      ],
    );
  }
}

/// Icon and colours per food category (presentation only).
(IconData, Color, Color) _categoryStyle(String category) => switch (category) {
  'drink' => (Icons.local_cafe_outlined, AppColors.blue, AppColors.blueSoft),
  'fruit' => (Icons.apple_outlined, AppColors.green, AppColors.greenSoft),
  'vegetable' => (Icons.eco_outlined, AppColors.green, AppColors.greenSoft),
  'snack and fried food' => (Icons.bakery_dining_outlined, AppColors.purple, AppColors.purpleSoft),
  'snack and breakfast' => (Icons.breakfast_dining_outlined, AppColors.orangeDark, AppColors.orangeSoft),
  'staple' => (Icons.rice_bowl_outlined, AppColors.orangeDark, AppColors.orangeSoft),
  'animal-based side dish' => (Icons.set_meal_outlined, AppColors.orangeDark, AppColors.orangeSoft),
  'plant-based side dish' => (Icons.spa_outlined, AppColors.green, AppColors.greenSoft),
  'packaged' => (Icons.qr_code_2_rounded, AppColors.sky, AppColors.skySoft),
  _ => (Icons.lunch_dining_outlined, AppColors.green, AppColors.greenSoft),
};

class _MealCard extends StatelessWidget {
  const _MealCard({required this.title, required this.items, required this.onDelete});

  final String title;
  final List<MealLog> items;
  final ValueChanged<MealLog> onDelete;

  static String _macros(MealLog m) =>
      'P ${fmtNum(m.proteinG)} g · C ${fmtNum(m.carbsG)} g · F ${fmtNum(m.fatG)} g'
      '${m.servings == 1 ? '' : ' · ${fmtNum(m.servings, decimals: 1)}×'}';

  @override
  Widget build(BuildContext context) {
    final kcal = items.fold<double>(0, (sum, m) => sum + m.caloriesKcal);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: ts(15, FontWeight.w700)),
              Text('${fmtNum(kcal)} kcal', style: ts(13, FontWeight.w400, AppColors.muted)),
            ],
          ),
          for (final m in items)
            Dismissible(
              key: ValueKey(m.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onDelete(m),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
              ),
              child: Row(
                spacing: 12,
                children: [
                  Builder(
                    builder: (context) {
                      final (icon, color, bg) = _categoryStyle(m.category);
                      return IconBadge(icon, color: color, bg: bg, size: 48, iconSize: 24, radius: 12);
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: ts(14, FontWeight.w600)),
                        Text(_macros(m), style: ts(12, FontWeight.w400, AppColors.muted)),
                      ],
                    ),
                  ),
                  if (m.labels.isNotEmpty)
                    Builder(
                      builder: (context) {
                        // Healthy first; any "High ..." label is a warning.
                        final label = m.labels.contains('Healthy') ? 'Healthy' : m.labels.first;
                        final warn = label.startsWith('High') && label != 'High protein';
                        return Pill(
                          label,
                          color: warn ? AppColors.orangeText : AppColors.greenDark,
                          bg: warn ? AppColors.orangeSoft : AppColors.greenSoft,
                        );
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
