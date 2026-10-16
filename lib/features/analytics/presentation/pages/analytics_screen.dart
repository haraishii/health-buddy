import 'package:flutter/material.dart';

import '../../../../app/navigation/app_tab_controller.dart';
import '../../../../data/api/api_models.dart';
import '../../../../theme.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/charts.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/format.dart';
import '../../../../widgets/skeleton.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  /// Monday of the shown week.
  DateTime _week = weekStart(DateTime.now());

  void _pickWeek() {
    final current = weekStart(DateTime.now());
    final weeks = [for (var i = 0; i < 6; i++) current.subtract(Duration(days: 7 * i))];
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
              for (final w in weeks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    w == current ? 'This week · ${_label(w)}' : _label(w),
                    style: ts(15, w == _week ? FontWeight.w700 : FontWeight.w400),
                  ),
                  trailing: w == _week ? const Icon(Icons.check_rounded, color: AppColors.green) : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    setState(() => _week = w);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(DateTime monday) => fmtRange(monday, monday.add(const Duration(days: 6)));

  @override
  Widget build(BuildContext context) {
    final to = _week.add(const Duration(days: 6));
    final header = FadeUp(
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
            label: _label(_week),
            icon: Icons.calendar_today_outlined,
            trailing: Icons.keyboard_arrow_down_rounded,
            onTap: _pickWeek,
          ),
        ],
      ),
    );

    return ApiBuilder<Analytics>(
      cacheKey: 'analytics:${apiDate(_week)}',
      load: (api) => api.analytics(from: _week, to: to),
      loading: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: header),
          const Expanded(
            child: SkeletonPage(
              header: false,
              children: [
                SkeletonCard(height: 200),
                SkeletonCard(height: 210),
                SkeletonCard(height: 260),
                SkeletonCard(lines: 3),
              ],
            ),
          ),
        ],
      ),
      builder: (context, data) => _AnalyticsBody(data: data, header: header),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.data, required this.header});

  final Analytics data;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final dates = [for (final d in data.days) parseApiDate(d.date)];
    final dayNames = [for (final d in dates) fmtWeekdayShort(d)];
    final dayLetters = [for (final d in dates) fmtWeekdayLetter(d)];
    final score = data.healthScore;
    final balance = score.balance;
    final nutrition = data.nutritionPercent;
    final stressAvg = data.average('stress');
    final stressChange = data.change('stress_change_percent');
    final exerciseMinutes = [for (final d in data.days) d.exerciseMinutes.toDouble()];
    final maxMinutes = exerciseMinutes.fold<double>(30, (m, v) => v > m ? v : m);
    final steps = data.average('steps');

    Color changeColor(double? pct, {bool lowerIsBetter = false}) {
      if (pct == null || pct == 0) return AppColors.muted;
      return (pct < 0) == lowerIsBetter ? AppColors.greenDark : AppColors.orangeText;
    }

    return AppRefresh(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            header,

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
                        Expanded(
                          flex: 7,
                          child: LineChart(
                            values: [for (final s in data.scores) s.score ?? double.nan],
                            labels: dayNames,
                            maxY: 100,
                            color: AppColors.green,
                            yTicks: const [0, 25, 50, 75, 100],
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
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: score.latest == null ? '–' : '${(score.latest! * t).round()}',
                                        style: ts(36, FontWeight.w800, AppColors.greenDark).copyWith(height: 1),
                                      ),
                                      TextSpan(text: ' /100', style: ts(13, FontWeight.w400, AppColors.muted)),
                                    ],
                                  ),
                                ),
                              ),
                              Text('Latest score', style: ts(12, FontWeight.w400, AppColors.muted)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (score.changePercent ?? 0) < 0 ? AppColors.orangeSoft : AppColors.greenSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  fmtChange(score.changePercent),
                                  style: ts(15, FontWeight.w800, changeColor(score.changePercent)),
                                ),
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
                            RadarChart(
                              names: const ['Nutrition', 'Stress', 'Sleep', 'Exercise'],
                              values: [
                                balance.nutrition ?? 0,
                                balance.stress ?? 0,
                                balance.sleep ?? 0,
                                balance.exercise ?? 0,
                              ],
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
                            if (nutrition.isEmpty)
                              Text(
                                'Complete your profile to compare with your daily targets.',
                                style: ts(13, FontWeight.w400, AppColors.muted),
                              )
                            else ...[
                              _NutriRow('Protein', (nutrition['protein'] ?? 0) / 100, AppColors.green, 300),
                              _NutriRow('Carbs', (nutrition['carbs'] ?? 0) / 100, AppColors.blue, 380),
                              _NutriRow('Fat', (nutrition['fat'] ?? 0) / 100, AppColors.orange, 460),
                              _NutriRow('Fiber', (nutrition['fiber'] ?? 0) / 100, AppColors.purple, 540),
                            ],
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
                            LineChart(
                              values: [for (final d in data.days) d.stressAvg ?? double.nan],
                              labels: dayLetters,
                              maxY: 10,
                              color: AppColors.purple,
                              height: 112,
                              yTicks: const [0, 5, 10],
                              delayMs: 450,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F1FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Weekly avg',
                                          style: ts(11, FontWeight.w400, AppColors.muted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          stressAvg == null ? '–' : stressAvg.toStringAsFixed(1),
                                          style: ts(20, FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('vs last wk', style: ts(11, FontWeight.w400, AppColors.muted)),
                                      Text(
                                        fmtChange(stressChange),
                                        style: ts(16, FontWeight.w800, changeColor(stressChange, lowerIsBetter: true)),
                                      ),
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
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${data.averages['exercise_days'] ?? 0}',
                                    style: ts(24, FontWeight.w800).copyWith(height: 1.1),
                                  ),
                                  const TextSpan(text: ' active days'),
                                ],
                              ),
                              style: ts(12, FontWeight.w400, AppColors.muted),
                            ),
                            Text('Minutes per day', style: ts(11, FontWeight.w400, AppColors.muted)),
                            BarChart(
                              values: exerciseMinutes,
                              labels: dayLetters,
                              maxY: maxMinutes,
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
                                      Text(steps == null ? '–' : fmtNum(steps), style: ts(16, FontWeight.w800)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Burned (avg)', style: ts(11, FontWeight.w400, AppColors.muted)),
                                      Text(
                                        '${fmtNum(data.average('calories_burned') ?? 0)} kcal',
                                        style: ts(16, FontWeight.w800),
                                      ),
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
                              const IconBadge(
                                Icons.smart_toy_outlined,
                                color: Colors.white,
                                bg: AppColors.purple,
                                size: 32,
                                iconSize: 18,
                              ),
                              Text('AI Insights', style: ts(16, FontWeight.w700, AppColors.purpleDeep)),
                            ],
                          ),
                          if (data.insightSentences.isEmpty && data.recommendation == null)
                            Text(
                              'Not enough data this week yet. Keep logging and insights will appear here.',
                              style: ts(14).copyWith(height: 1.45),
                            ),
                          for (final sentence in data.insightSentences.take(2))
                            Text(sentence, style: ts(14).copyWith(height: 1.45)),
                          if (data.recommendation != null)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Recommendation: ', style: ts(14, FontWeight.w700)),
                                  TextSpan(text: data.recommendation),
                                ],
                              ),
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
                    Row(
                      children: [
                        Expanded(
                          child: _TrendItem(
                            Icons.directions_run_rounded,
                            AppColors.green,
                            AppColors.greenSoft,
                            'Exercise',
                            fmtChange(data.change('exercise_change_percent')),
                            changeColor(data.change('exercise_change_percent')),
                          ),
                        ),
                        Expanded(
                          child: _TrendItem(
                            Icons.sentiment_satisfied_alt_rounded,
                            AppColors.purple,
                            AppColors.purpleSoft,
                            'Stress',
                            fmtChange(stressChange),
                            changeColor(stressChange, lowerIsBetter: true),
                          ),
                        ),
                        Expanded(
                          child: _TrendItem(
                            Icons.restaurant_rounded,
                            AppColors.orangeDark,
                            AppColors.orangeSoft,
                            'Healthy meals',
                            fmtChange(data.change('healthy_meals_change_pct')),
                            changeColor(data.change('healthy_meals_change_pct')),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'vs the week before',
                      textAlign: TextAlign.center,
                      style: ts(12, FontWeight.w400, AppColors.muted),
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
  const _TrendItem(this.icon, this.color, this.bg, this.label, this.value, this.valueColor);

  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final String value;
  final Color valueColor;

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
        Text(value, style: ts(16, FontWeight.w800, valueColor)),
      ],
    );
  }
}
