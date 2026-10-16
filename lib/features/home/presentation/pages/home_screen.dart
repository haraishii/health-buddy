import 'package:flutter/material.dart';

import '../../../../app/navigation/app_tab_controller.dart';
import '../../../../data/api/api_models.dart';
import '../../../../theme.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/charts.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/format.dart';
import '../../../../widgets/skeleton.dart';
import '../../../exercise/presentation/pages/log_exercise_screen.dart';
import '../../../food/presentation/pages/scan_meal_screen.dart';
import '../../../profile/presentation/pages/edit_profile_screen.dart';
import '../../../stress/presentation/pages/stress_check_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiBuilder<DaySummary>(
      cacheKey: 'summary:${apiDate(DateTime.now())}',
      load: (api) => api.summary(),
      loading: const SkeletonPage(
        children: [
          SkeletonCard(ring: true, lines: 2),
          SkeletonCard(lines: 7),
          SkeletonCard(lines: 3),
          SkeletonCard(lines: 2),
        ],
      ),
      builder: (context, summary) => _HomeBody(summary: summary),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.summary});

  final DaySummary summary;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Good morning,';
    if (h < 15) return 'Good afternoon,';
    if (h < 19) return 'Good evening,';
    return 'Good night,';
  }

  Future<void> _addWater(BuildContext context) async {
    var total = 0;
    final ok = await saveWithFeedback(context, (api) async => total = await api.addWater());
    if (ok && context.mounted) {
      showToast(context, '+250 ml water logged · ${fmtLiters(total.toDouble())} today', icon: Icons.water_drop_rounded);
    }
  }

  Future<void> _logSleep(BuildContext context) async {
    final hours = await showNumberSheet(
      context,
      title: 'Sleep last night',
      unit: 'hours',
      initial: summary.totals.sleepHours,
      min: 0,
      max: 24,
      decimals: true,
    );
    if (hours == null || !context.mounted) return;
    if (await saveWithFeedback(context, (api) => api.setSleep(hours: hours)) && context.mounted) {
      showToast(context, 'Sleep saved: ${fmtHours(hours)}', icon: Icons.bedtime_outlined);
    }
  }

  Future<void> _logSteps(BuildContext context) async {
    final steps = await showNumberSheet(
      context,
      title: 'Steps today',
      unit: 'steps',
      initial: summary.totals.steps?.toDouble(),
      min: 0,
      max: 200000,
      hint: 'Until Health Connect sync is ready, enter the number from your phone.',
    );
    if (steps == null || !context.mounted) return;
    final ok = await saveWithFeedback(context, (api) => api.setSteps(steps: steps.round(), source: 'manual'));
    if (ok && context.mounted) showToast(context, 'Steps saved: ${fmtNum(steps)}', icon: Icons.directions_walk_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final user = summary.user;
    final score = summary.healthScore;

    ({String key, String label, String value, String total, double fraction, Color color})? goal(
      String key,
      String label,
      Color color,
      String Function(double v) fmt,
    ) {
      final g = summary.goal(key);
      if (g == null) return null;
      return (
        key: key,
        label: label,
        value: fmt(g.current),
        total: g.target == null ? '–' : fmt(g.target!),
        fraction: g.progress,
        color: color,
      );
    }

    final goals = [
      goal('steps', 'Steps', AppColors.green, (v) => fmtNum(v)),
      goal('water', 'Water', AppColors.blue, fmtLiters),
      goal('protein', 'Protein', AppColors.orange, (v) => '${fmtNum(v)} g'),
      goal('sleep_last_night', 'Sleep last night', AppColors.purple, fmtHours),
    ].nonNulls.toList();
    final done = goals.where((g) => g.fraction >= 1).length;

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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(), style: ts(14, FontWeight.w400, AppColors.muted)),
                        Text(
                          user.name,
                          style: ts(28, FontWeight.w800).copyWith(letterSpacing: -0.5, height: 1.15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SquareIconButton(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () => showToast(context, 'No new notifications', icon: Icons.notifications_none_rounded),
                  ),
                  const SizedBox(width: 10),
                  PressScale(
                    label: 'Profile',
                    onTap: () => currentTab.value = 4,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.greenTint, shape: BoxShape.circle),
                      child: Text(
                        user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                        style: ts(17, FontWeight.w700, AppColors.greenDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (summary.targetsError != null)
              FadeUp(
                delayMs: 30,
                child: AppCard(
                  color: AppColors.orangeCard,
                  borderColor: AppColors.orangeBorder,
                  radius: 20,
                  label: 'Complete your profile',
                  onTap: () => Navigator.of(context).push(slideRoute(const EditProfileScreen())),
                  child: Row(
                    spacing: 12,
                    children: [
                      const IconBadge(Icons.person_outline_rounded, color: AppColors.orangeDark, bg: Colors.white),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Complete your profile', style: ts(15, FontWeight.w700)),
                            Text(
                              'Add your birth date, sex and weight to get daily targets.',
                              style: ts(13, FontWeight.w400, AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ],
                  ),
                ),
              ),

            // Health Score
            FadeUp(
              delayMs: 60,
              child: AppCard(
                padding: const EdgeInsets.all(18),
                radius: 20,
                child: Row(
                  spacing: 18,
                  children: [
                    ScoreRing(
                      fraction: (score.latest ?? 0) / 100,
                      color: AppColors.green,
                      track: const Color(0xFFE8F5EC),
                      center: (t) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score.latest == null ? '–' : '${(score.latest! * t).round()}',
                            style: ts(32, FontWeight.w800, AppColors.greenDark).copyWith(height: 1),
                          ),
                          Text('/100', style: ts(12, FontWeight.w400, AppColors.muted)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text('Health Score', style: ts(16, FontWeight.w700)),
                          if (score.changePercent != null)
                            Pill(
                              '${fmtChange(score.changePercent)} vs last week',
                              size: 13,
                              color: score.changePercent! < 0 ? AppColors.orangeText : AppColors.greenDark,
                              bg: score.changePercent! < 0 ? AppColors.orangeSoft : AppColors.greenSoft,
                            )
                          else if (score.latest == null)
                            Text(
                              'Log meals, sleep and stress to see your score.',
                              style: ts(13, FontWeight.w400, AppColors.muted),
                            ),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Stress '),
                                TextSpan(
                                  text: summary.stressLevel ?? '–',
                                  style: ts(13, FontWeight.w700, AppColors.purpleDark),
                                ),
                                const TextSpan(text: '   Activity '),
                                TextSpan(
                                  text: summary.activityLevel ?? '–',
                                  style: ts(13, FontWeight.w700, AppColors.blueDark),
                                ),
                              ],
                            ),
                            style: ts(13, FontWeight.w400, AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Today's goals
            FadeUp(
              delayMs: 120,
              child: AppCard(
                padding: const EdgeInsets.all(18),
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Today's goals", style: ts(17, FontWeight.w700)),
                        Text('$done of ${goals.length} done', style: ts(13, FontWeight.w400, AppColors.muted)),
                      ],
                    ),
                    for (var i = 0; i < goals.length; i++)
                      _GoalRow(
                        // Steps and sleep are typed in by the user until phone/watch sync exists.
                        onTap: switch (goals[i].key) {
                          'steps' => () => _logSteps(context),
                          'sleep_last_night' => () => _logSleep(context),
                          _ => null,
                        },
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                spacing: 4,
                                children: [
                                  Text(goals[i].label, style: ts(14)),
                                  if (goals[i].key == 'steps' || goals[i].key == 'sleep_last_night')
                                    const Icon(Icons.edit_outlined, size: 14, color: AppColors.muted),
                                ],
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: goals[i].value, style: ts(14, FontWeight.w700)),
                                    TextSpan(text: ' / ${goals[i].total}'),
                                  ],
                                ),
                                style: ts(14, FontWeight.w400, AppColors.muted),
                              ),
                            ],
                          ),
                          ProgressBar(value: goals[i].fraction, color: goals[i].color, delayMs: 300 + i * 80),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Quick log
            FadeUp(
              delayMs: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  Text('Quick log', style: ts(17, FontWeight.w700)),
                  twoColumns([
                    _QuickTile(
                      icon: Icons.directions_run_rounded,
                      color: AppColors.blue,
                      bg: AppColors.blueSoft,
                      label: 'Log Exercise',
                      onTap: () => Navigator.of(context).push(slideRoute(const LogExerciseScreen())),
                    ),
                    _QuickTile(
                      icon: Icons.photo_camera_outlined,
                      color: AppColors.green,
                      bg: AppColors.greenSoft,
                      label: 'Scan Meal',
                      onTap: () => Navigator.of(context).push(slideRoute(const ScanMealScreen())),
                    ),
                    _QuickTile(
                      icon: Icons.sentiment_satisfied_alt_rounded,
                      color: AppColors.purple,
                      bg: AppColors.purpleSoft,
                      label: 'Stress Check',
                      onTap: () => Navigator.of(context).push(slideRoute(const StressCheckScreen())),
                    ),
                    _QuickTile(
                      icon: Icons.water_drop_outlined,
                      color: AppColors.sky,
                      bg: AppColors.skySoft,
                      label: '+ 250 ml water',
                      onTap: () => _addWater(context),
                    ),
                  ]),
                ],
              ),
            ),

            // Tip AI Coach
            FadeUp(
              delayMs: 240,
              child: AppCard(
                color: AppColors.purpleCard,
                borderColor: AppColors.purpleBorder,
                radius: 20,
                label: 'Open AI Coach',
                onTap: () => currentTab.value = 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    const IconBadge(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      bg: AppColors.purple,
                      size: 40,
                      iconSize: 22,
                      radius: 12,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text('Tip from your AI Coach', style: ts(15, FontWeight.w700, AppColors.purpleDeep)),
                          Text(
                            summary.tip?.text ?? 'You are on track today. Ask me anything about your health.',
                            style: ts(14).copyWith(height: 1.45),
                          ),
                          Text('Ask a question →', style: ts(13, FontWeight.w700, AppColors.purpleDark)),
                        ],
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

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.children, this.onTap});

  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final column = Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 6, children: children);
    return onTap == null ? column : PressScale(onTap: onTap, scale: 0.98, child: column);
  }
}

/// Bottom sheet with one number field; returns the value or null when cancelled.
Future<double?> showNumberSheet(
  BuildContext context, {
  required String title,
  required String unit,
  required double min,
  required double max,
  double? initial,
  bool decimals = false,
  String? hint,
}) {
  final controller = TextEditingController(
    text: initial == null || initial == 0 ? '' : (decimals ? '$initial' : '${initial.round()}'),
  );
  String? error;
  return showModalBottomSheet<double>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        void submit() {
          final v = double.tryParse(controller.text.trim().replaceAll(',', '.'));
          if (v == null || v < min || v > max) {
            setSheetState(() => error = 'Enter a number from ${fmtNum(min)} to ${fmtNum(max)}');
            return;
          }
          Navigator.of(sheetContext).pop(v);
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(title, style: ts(20, FontWeight.w700)),
              if (hint != null) Text(hint, style: ts(13, FontWeight.w400, AppColors.muted)),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(decimal: decimals),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
                style: ts(28, FontWeight.w800),
                decoration: InputDecoration(
                  suffixText: unit,
                  suffixStyle: ts(16, FontWeight.w400, AppColors.muted),
                  errorText: error,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderStrong),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.red, width: 1.5),
                  ),
                ),
              ),
              PrimaryButton(label: 'Save', onTap: submit),
            ],
          ),
        );
      },
    ),
  ).whenComplete(controller.dispose);
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 16,
      onTap: onTap,
      label: label,
      child: Row(
        spacing: 10,
        children: [
          IconBadge(icon, color: color, bg: bg),
          Expanded(
            child: Text(label, style: ts(14, FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
