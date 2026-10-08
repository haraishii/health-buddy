import 'package:flutter/material.dart';

import '../../../../theme.dart';
import '../../../../widgets/common.dart';

class LogExerciseScreen extends StatefulWidget {
  const LogExerciseScreen({super.key});

  @override
  State<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends State<LogExerciseScreen> {
  // Approximate MET values for the calorie estimate (sample body weight 55 kg).
  static const _activities = [
    ('Walk', Icons.directions_walk_rounded, 3.5),
    ('Run', Icons.directions_run_rounded, 8.0),
    ('Cycling', Icons.directions_bike_rounded, 6.0),
    ('Gym', Icons.fitness_center_rounded, 5.0),
    ('Yoga', Icons.self_improvement_rounded, 2.5),
    ('Sports', Icons.sports_soccer_rounded, 7.0),
  ];
  static const _intensity = ['Light', 'Moderate', 'Hard'];
  static const _intensityFactor = [0.8, 1.0, 1.25];

  int _activity = 0;
  int _minutes = 20;
  int _level = 1;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _kcal => (_activities[_activity].$3 * _intensityFactor[_level] * 55 * _minutes / 60).round();

  void _save() {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(toastBar('Nice work! $_minutes min ${_activities[_activity].$1.toLowerCase()} saved.'));
  }

  Widget _stepButton(IconData icon, String label, VoidCallback onTap, {bool filled = false}) {
    return PressScale(
      label: label,
      scale: 0.92,
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: filled ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: filled ? null : Border.all(color: AppColors.borderStrong),
        ),
        child: Icon(icon, color: filled ? Colors.white : AppColors.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              const BackHeader('Log Exercise'),

              FadeUp(
                child: AppCard(
                  radius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Text('Activity', style: ts(17, FontWeight.w700)),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.25,
                        children: [
                          for (var i = 0; i < _activities.length; i++)
                            Semantics(
                              selected: i == _activity,
                              child: PressScale(
                                label: _activities[i].$1,
                                onTap: () => setState(() => _activity = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: i == _activity ? AppColors.greenSoft : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: i == _activity ? AppColors.green : AppColors.borderStrong,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 4,
                                    children: [
                                      Icon(
                                        _activities[i].$2,
                                        color: i == _activity ? AppColors.greenDark : AppColors.muted,
                                      ),
                                      Text(
                                        _activities[i].$1,
                                        style: ts(
                                          14,
                                          FontWeight.w600,
                                          i == _activity ? AppColors.greenDark : AppColors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              FadeUp(
                delayMs: 60,
                child: AppCard(
                  radius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Text('Duration', style: ts(17, FontWeight.w700)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _stepButton(
                            Icons.remove_rounded,
                            'Decrease 5 minutes',
                            () => setState(() => _minutes = (_minutes - 5).clamp(5, 180)),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            spacing: 6,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (child, a) => FadeTransition(
                                  opacity: a,
                                  child: SlideTransition(
                                    position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  '$_minutes',
                                  key: ValueKey(_minutes),
                                  style: ts(44, FontWeight.w800).copyWith(height: 1),
                                ),
                              ),
                              Text('min', style: ts(16, FontWeight.w400, AppColors.muted)),
                            ],
                          ),
                          _stepButton(
                            Icons.add_rounded,
                            'Increase 5 minutes',
                            () => setState(() => _minutes = (_minutes + 5).clamp(5, 180)),
                            filled: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              FadeUp(
                delayMs: 120,
                child: AppCard(
                  radius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Text('Intensity', style: ts(17, FontWeight.w700)),
                      Segmented(options: _intensity, index: _level, onChanged: (i) => setState(() => _level = i)),
                    ],
                  ),
                ),
              ),

              FadeUp(
                delayMs: 180,
                child: AppCard(
                  radius: 20,
                  color: AppColors.greenSoft,
                  borderColor: AppColors.greenBubbleBorder,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated burn', style: ts(13, FontWeight.w400, const Color(0xFF2F6B3F))),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: _kcal.toDouble()),
                            duration: const Duration(milliseconds: 400),
                            curve: Motion.standard,
                            builder: (context, v, _) =>
                                Text('${v.round()} kcal', style: ts(26, FontWeight.w800, AppColors.greenDark)),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('This week', style: ts(13, FontWeight.w400, const Color(0xFF2F6B3F))),
                          Text('4 active days', style: ts(18, FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  Text('Note (optional)', style: ts(14, FontWeight.w600)),
                  TextField(
                    controller: _note,
                    style: ts(15),
                    decoration: InputDecoration(
                      hintText: 'e.g. walked home after class',
                      hintStyle: ts(15, FontWeight.w400, AppColors.muted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderStrong),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),

              PrimaryButton(label: 'Save exercise', onTap: _save),
            ],
          ),
        ),
      ),
    );
  }
}
