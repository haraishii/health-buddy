import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'scan_meal_screen.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  void _openScan(BuildContext context) => Navigator.of(context).push(slideRoute(const ScanMealScreen()));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      Text('Today, Sunday May 18', style: ts(14, FontWeight.w400, AppColors.muted)),
                    ],
                  ),
                ),
                OutlineChipButton(label: 'Search', icon: Icons.search_rounded, onTap: () => _openScan(context)),
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
                    fraction: 1420 / 1900,
                    color: AppColors.orange,
                    track: AppColors.orangeTrack,
                    center: (t) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmtThousands(1420 * t), style: ts(24, FontWeight.w800).copyWith(height: 1)),
                        Text('of 1,900 kcal', style: ts(12, FontWeight.w400, AppColors.muted)),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      spacing: 10,
                      children: [
                        _MacroRow('Protein', 42, 60, AppColors.green, 300),
                        _MacroRow('Carbs', 168, 250, AppColors.blue, 380),
                        _MacroRow('Fat', 48, 60, AppColors.orange, 460),
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
              onTap: () => _openScan(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  spacing: 14,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 26),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Meal', style: ts(16, FontWeight.w700, Colors.white)),
                          Text('Photo, barcode or search', style: ts(13, FontWeight.w400, Colors.white.withValues(alpha: 0.92))),
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
                const _MealCard(title: 'Breakfast', kcal: 320, items: [
                  _FoodItem('Oatmeal with banana', 'P 9 g · C 58 g · F 6 g', Icons.breakfast_dining_outlined, AppColors.orangeDark, AppColors.orangeSoft,
                      tag: 'Healthy'),
                ]),
                const _MealCard(title: 'Lunch', kcal: 640, items: [
                  _FoodItem('Chicken rice bowl', 'P 28 g · C 82 g · F 18 g', Icons.lunch_dining_outlined, AppColors.green, AppColors.greenSoft),
                  _FoodItem('Iced tea, less sugar', 'C 18 g', Icons.local_cafe_outlined, AppColors.blue, AppColors.blueSoft),
                ]),
                const _MealCard(title: 'Snack', kcal: 460, items: [
                  _FoodItem('Fried snacks', 'P 5 g · C 10 g · F 24 g', Icons.bakery_dining_outlined, AppColors.purple, AppColors.purpleSoft,
                      tag: 'High fat', warn: true),
                ]),
                PressScale(
                  label: 'Add dinner',
                  onTap: () => _openScan(context),
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
                        Text('Add dinner', style: ts(15, FontWeight.w600, AppColors.greenDark)),
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
                  const IconBadge(Icons.trending_up_rounded, color: AppColors.orangeDark, bg: Colors.white, size: 40, radius: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '22% more healthy meals', style: ts(14, FontWeight.w700)),
                        const TextSpan(text: ' than last week. Add protein at dinner to hit your goal.'),
                      ]),
                      style: ts(14).copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow(this.label, this.value, this.goal, this.color, this.delayMs);

  final String label;
  final int value;
  final int goal;
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
              TextSpan(children: [
                TextSpan(text: '$value', style: ts(13, FontWeight.w700)),
                TextSpan(text: '/$goal g'),
              ]),
              style: ts(13, FontWeight.w400, AppColors.muted),
            ),
          ],
        ),
        ProgressBar(value: value / goal, color: color, height: 6, delayMs: delayMs),
      ],
    );
  }
}

class _FoodItem {
  const _FoodItem(this.name, this.macros, this.icon, this.color, this.bg, {this.tag, this.warn = false});

  final String name;
  final String macros;
  final IconData icon;
  final Color color;
  final Color bg;
  final String? tag;
  final bool warn;
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.title, required this.kcal, required this.items});

  final String title;
  final int kcal;
  final List<_FoodItem> items;

  @override
  Widget build(BuildContext context) {
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
              Text('$kcal kcal', style: ts(13, FontWeight.w400, AppColors.muted)),
            ],
          ),
          for (final f in items)
            Row(
              spacing: 12,
              children: [
                IconBadge(f.icon, color: f.color, bg: f.bg, size: 48, iconSize: 24, radius: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, style: ts(14, FontWeight.w600)),
                      Text(f.macros, style: ts(12, FontWeight.w400, AppColors.muted)),
                    ],
                  ),
                ),
                if (f.tag != null)
                  Pill(
                    f.tag!,
                    color: f.warn ? AppColors.orangeText : AppColors.greenDark,
                    bg: f.warn ? AppColors.orangeSoft : AppColors.greenSoft,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
