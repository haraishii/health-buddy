import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  void _pickWeek(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose a week', style: ts(18, FontWeight.w700)),
              const SizedBox(height: 8),
              for (final w in ['May 12 – 18', 'May 5 – 11', 'Apr 28 – May 4'])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(w, style: ts(15, w == 'May 12 – 18' ? FontWeight.w700 : FontWeight.w400)),
                  trailing: w == 'May 12 – 18' ? const Icon(Icons.check_rounded, color: AppColors.green) : null,
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          FadeUp(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text('Analytics', style: ts(28, FontWeight.w800).copyWith(letterSpacing: -0.5, height: 1.15)),
                      Text('Track your progress and stay healthier.', style: ts(14, FontWeight.w400, AppColors.muted)),
                    ],
                  ),
                ),
                OutlineChipButton(
                  label: 'May 12 – 18',
                  icon: Icons.calendar_today_outlined,
                  trailing: Icons.keyboard_arrow_down_rounded,
                  onTap: () => _pickWeek(context),
                ),
              ],
            ),
          ),

          // Health Score Trend
          FadeUp(
            delayMs: 60,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text('Health Score Trend', style: ts(16, FontWeight.w700)),
                  Row(
                    children: [
                      const Expanded(
                        flex: 7,
                        child: LineChart(
                          values: [72, 76, 68, 80, 85, 88, 85],
                          labels: _days,
                          maxY: 100,
                          color: AppColors.green,
                          yTicks: [0, 25, 50, 75, 100],
                          showYLabels: true,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          spacing: 4,
                          children: [
                            Reveal(
                              duration: const Duration(milliseconds: 700),
                              delayMs: 200,
                              builder: (context, t) => Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: '${(85 * t).round()}', style: ts(36, FontWeight.w800, AppColors.greenDark).copyWith(height: 1)),
                                  TextSpan(text: ' /100', style: ts(13, FontWeight.w400, AppColors.muted)),
                                ]),
                              ),
                            ),
                            Text('Latest score', style: ts(12, FontWeight.w400, AppColors.muted)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(10)),
                              child: Text('↑ 12%', style: ts(15, FontWeight.w800, AppColors.greenDark)),
                            ),
                            Text('vs last week', style: ts(12, FontWeight.w400, AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Balance + Nutrition
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Expanded(
                  child: FadeUp(
                    delayMs: 120,
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text('Balance Overview', style: ts(15, FontWeight.w700)),
                          const RadarChart(
                            names: ['Nutrition', 'Stress', 'Sleep', 'Exercise'],
                            values: [90, 85, 80, 70],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FadeUp(
                    delayMs: 180,
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 14,
                        children: [
                          Text('Nutrition', style: ts(15, FontWeight.w700)),
                          const _NutriRow('Protein', 0.85, AppColors.green, 300),
                          const _NutriRow('Carbs', 0.60, AppColors.blue, 380),
                          const _NutriRow('Fat', 0.80, AppColors.orange, 460),
                          const _NutriRow('Fiber', 0.40, AppColors.purple, 540),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stress + Exercise
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Expanded(
                  child: FadeUp(
                    delayMs: 240,
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 6,
                        children: [
                          Text('Stress Level', style: ts(15, FontWeight.w700)),
                          Text('1 = low, 10 = high', style: ts(11, FontWeight.w400, AppColors.muted)),
                          const LineChart(
                            values: [7, 6, 8, 5, 4, 3, 4],
                            labels: _dayLetters,
                            maxY: 10,
                            color: AppColors.purple,
                            height: 112,
                            yTicks: [0, 5, 10],
                            delayMs: 450,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF5F1FF), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Weekly avg', style: ts(11, FontWeight.w400, AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('5.3', style: ts(20, FontWeight.w800)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('vs last wk', style: ts(11, FontWeight.w400, AppColors.muted)),
                                    Text('↓ 15%', style: ts(16, FontWeight.w800, AppColors.greenDark)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FadeUp(
                    delayMs: 300,
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 6,
                        children: [
                          Text('Exercise', style: ts(15, FontWeight.w700)),
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(text: '4.2', style: ts(24, FontWeight.w800).copyWith(height: 1.1)),
                              const TextSpan(text: ' days/week'),
                            ]),
                            style: ts(12, FontWeight.w400, AppColors.muted),
                          ),
                          const BarChart(
                            values: [4.7, 3.5, 1.5, 3.2, 5.8, 3.3, 4.6],
                            labels: _dayLetters,
                            maxY: 6,
                            color: AppColors.green,
                          ),
                          const Spacer(),
                          const Divider(height: 8, color: AppColors.track),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Steps (avg)', style: ts(11, FontWeight.w400, AppColors.muted)),
                                    Text('7,842', style: ts(16, FontWeight.w800)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Burned (avg)', style: ts(11, FontWeight.w400, AppColors.muted)),
                                    Text('320 kcal', style: ts(16, FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // AI Insights
          FadeUp(
            delayMs: 360,
            child: AppCard(
              color: AppColors.purpleCard,
              borderColor: AppColors.purpleBorder,
              label: 'Open AI Coach',
              onTap: () => currentTab.value = 2,
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            const IconBadge(Icons.smart_toy_outlined, color: Colors.white, bg: AppColors.purple, size: 32, iconSize: 18),
                            Text('AI Insights', style: ts(16, FontWeight.w700, AppColors.purpleDeep)),
                          ],
                        ),
                        Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Your stress drops '),
                            TextSpan(text: '20%', style: ts(14, FontWeight.w700)),
                            const TextSpan(text: ' on days you exercise.'),
                          ]),
                          style: ts(14).copyWith(height: 1.45),
                        ),
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'Recommendation: ', style: ts(14, FontWeight.w700)),
                            const TextSpan(text: 'walk 20 minutes after class to keep your progress going.'),
                          ]),
                          style: ts(14).copyWith(height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 104, height: 128, child: ParkScene()),
                ],
              ),
            ),
          ),

          // Trends
          FadeUp(
            delayMs: 420,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Text('Trends at a Glance', style: ts(16, FontWeight.w700)),
                  const Row(
                    children: [
                      Expanded(child: _TrendItem(Icons.directions_run_rounded, AppColors.green, AppColors.greenSoft, 'Exercise', '↑ 18%')),
                      Expanded(child: _TrendItem(Icons.sentiment_satisfied_alt_rounded, AppColors.purple, AppColors.purpleSoft, 'Stress', '↓ 15%')),
                      Expanded(child: _TrendItem(Icons.restaurant_rounded, AppColors.orangeDark, AppColors.orangeSoft, 'Healthy meals', '↑ 22%')),
                    ],
                  ),
                  Text('vs last week', textAlign: TextAlign.center, style: ts(12, FontWeight.w400, AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutriRow extends StatelessWidget {
  const _NutriRow(this.label, this.value, this.color, this.delayMs);

  final String label;
  final double value;
  final Color color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ts(13)),
            Text('${(value * 100).round()}%', style: ts(13, FontWeight.w700)),
          ],
        ),
        ProgressBar(value: value, color: color, delayMs: delayMs),
      ],
    );
  }
}

class _TrendItem extends StatelessWidget {
  const _TrendItem(this.icon, this.color, this.bg, this.label, this.value);

  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 4,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        Text(label, style: ts(12, FontWeight.w400, AppColors.muted)),
        Text(value, style: ts(16, FontWeight.w800, AppColors.greenDark)),
      ],
    );
  }
}
