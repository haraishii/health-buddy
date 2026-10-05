import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'log_exercise_screen.dart';
import 'scan_meal_screen.dart';
import 'stress_check_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _water = 1.2;

  void _addWater() {
    setState(() => _water = (_water + 0.25).clamp(0.0, 3.0));
    showToast(context, '+250 ml water logged', icon: Icons.water_drop_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final goals = <({String label, String value, String total, double fraction, Color color})>[
      (label: 'Steps', value: '6,240', total: '8,000', fraction: 6240 / 8000, color: AppColors.green),
      (label: 'Water', value: '${_water.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')} L', total: '2 L', fraction: _water / 2, color: AppColors.blue),
      (label: 'Protein', value: '42 g', total: '60 g', fraction: 42 / 60, color: AppColors.orange),
      (label: 'Sleep last night', value: '6 h 10 m', total: '8 h', fraction: 370 / 480, color: AppColors.purple),
    ];
    final done = goals.where((g) => g.fraction >= 1).length;

    return SingleChildScrollView(
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
                      Text('Good morning,', style: ts(14, FontWeight.w400, AppColors.muted)),
                      Text('Annida', style: ts(28, FontWeight.w800).copyWith(letterSpacing: -0.5, height: 1.15)),
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
                    child: Text('A', style: ts(17, FontWeight.w700, AppColors.greenDark)),
                  ),
                ),
              ],
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
                    fraction: 0.85,
                    color: AppColors.green,
                    track: const Color(0xFFE8F5EC),
                    center: (t) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${(85 * t).round()}', style: ts(32, FontWeight.w800, AppColors.greenDark).copyWith(height: 1)),
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
                        const Pill('↑ 12% vs last week', size: 13),
                        Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Stress '),
                            TextSpan(text: 'Low', style: ts(13, FontWeight.w700, AppColors.purpleDark)),
                            const TextSpan(text: '   Activity '),
                            TextSpan(text: 'Moderate', style: ts(13, FontWeight.w700, AppColors.blueDark)),
                          ]),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(goals[i].label, style: ts(14)),
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(text: goals[i].value, style: ts(14, FontWeight.w700)),
                                TextSpan(text: ' / ${goals[i].total}'),
                              ]),
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
                    onTap: _addWater,
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
                  const IconBadge(Icons.smart_toy_outlined, color: Colors.white, bg: AppColors.purple, size: 40, iconSize: 22, radius: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text('Tip from your AI Coach', style: ts(15, FontWeight.w700, AppColors.purpleDeep)),
                        Text('You slept 1.5 h less this week. Aim for bed before 11:00 PM tonight.', style: ts(14).copyWith(height: 1.45)),
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
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.color, required this.bg, required this.label, required this.onTap});

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
          Expanded(child: Text(label, style: ts(14, FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
