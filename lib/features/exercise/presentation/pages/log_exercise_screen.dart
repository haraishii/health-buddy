import 'package:flutter/material.dart';

import '../../../../data/api/api_models.dart';
import '../../../../data/api/session.dart';
import '../../../../theme.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/skeleton.dart';
import '../../../profile/presentation/pages/edit_profile_screen.dart';

typedef _ExerciseData = ({List<Activity> activities, DaySummary summary});

class LogExerciseScreen extends StatelessWidget {
  const LogExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ApiBuilder<_ExerciseData>(
          cacheKey: 'exercise:${apiDate(DateTime.now())}',
          load: (api) async {
            final results = await Future.wait<Object>([api.activities(), api.summary()]);
            return (activities: results[0] as List<Activity>, summary: results[1] as DaySummary);
          },
          loading: const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                BackHeader('Log Exercise'),
                Shimmer(
                  child: Column(
                    spacing: 14,
                    children: [SkeletonCard(lines: 4), SkeletonCard(lines: 1), SkeletonCard(lines: 2)],
                  ),
                ),
              ],
            ),
          ),
          builder: (context, data) => data.activities.isEmpty
              ? ErrorState(message: 'No activities in the database yet.', onRetry: SessionScope.of(context).dataChanged)
              : _ExerciseForm(data: data),
        ),
      ),
    );
  }
}

/// Button label and icon per activity group from the database (presentation only).
(String, IconData) _groupStyle(String group) => switch (group) {
  'walk' => ('Walk', Icons.directions_walk_rounded),
  'run' => ('Run', Icons.directions_run_rounded),
  'cycling' => ('Cycling', Icons.directions_bike_rounded),
  'swim' => ('Swim', Icons.pool_rounded),
  'gym' => ('Gym', Icons.fitness_center_rounded),
  'yoga' => ('Yoga', Icons.self_improvement_rounded),
  'sports' => ('Sports', Icons.sports_soccer_rounded),
  'daily' => ('Chores', Icons.cleaning_services_outlined),
  _ => ('Other', Icons.hiking_rounded),
};

const _intensities = [('light', 'Light'), ('moderate', 'Moderate'), ('vigorous', 'Hard')];

class _ExerciseForm extends StatefulWidget {
  const _ExerciseForm({required this.data});

  final _ExerciseData data;

  @override
  State<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<_ExerciseForm> {
  // Activity groups in database order (a set literal keeps insertion order and drops repeats).
  late final List<String> _groups = {for (final a in widget.data.activities) a.group}.toList();

  late String _group = _groups.first;
  late Activity _activity = _pickFor(_group, null);
  int _minutes = 20;
  bool _saving = false;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<Activity> _inGroup(String group) => [
    for (final a in widget.data.activities)
      if (a.group == group) a,
  ];

  /// Keeps the chosen intensity when switching groups if that group has it, otherwise the lightest option.
  Activity _pickFor(String group, String? intensity) {
    final options = _inGroup(group);
    return options.firstWhere((a) => a.intensity == intensity, orElse: () => options.first);
  }

  double? get _weight => widget.data.summary.user.weightKg;

  /// MET x body weight (kg) x duration (hours), the same formula the backend saves.
  double? get _kcal => _weight == null ? null : _activity.met * _weight! * _minutes / 60;

  Future<void> _save() async {
    setState(() => _saving = true);
    final note = _note.text.trim();
    final ok = await saveWithFeedback(
      context,
      (api) => api.addExercise(activityId: _activity.id, minutes: _minutes, note: note.isEmpty ? null : note),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(toastBar('Nice work! $_minutes min ${_activityName(_activity).toLowerCase()} saved.'));
  }

  String _activityName(Activity a) => SessionScope.of(context).user?.language == 'id' ? a.name : (a.nameEn ?? a.name);

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

  Widget _chip(String label, bool selected, VoidCallback onTap) => PressScale(
    label: label,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.greenSoft : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: selected ? AppColors.green : AppColors.borderStrong),
      ),
      child: Text(label, style: ts(13.5, FontWeight.w600, selected ? AppColors.greenDark : AppColors.text)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final options = _inGroup(_group);
    final available = {for (final a in options) a.intensity};
    final sameIntensity = [
      for (final a in options)
        if (a.intensity == _activity.intensity) a,
    ];
    final activeDays = widget.data.summary.weekAverages['exercise_days'] as int? ?? 0;
    final kcal = _kcal;

    return SingleChildScrollView(
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
                      for (final g in _groups)
                        Semantics(
                          selected: g == _group,
                          child: PressScale(
                            label: _groupStyle(g).$1,
                            onTap: () => setState(() {
                              _group = g;
                              _activity = _pickFor(g, _activity.intensity);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: g == _group ? AppColors.greenSoft : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: g == _group ? AppColors.green : AppColors.borderStrong,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 4,
                                children: [
                                  Icon(_groupStyle(g).$2, color: g == _group ? AppColors.greenDark : AppColors.muted),
                                  Text(
                                    _groupStyle(g).$1,
                                    style: ts(14, FontWeight.w600, g == _group ? AppColors.greenDark : AppColors.text),
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
                  Segmented(
                    options: [for (final i in _intensities) available.contains(i.$1) ? i.$2 : '${i.$2} –'],
                    index: _intensities.indexWhere((i) => i.$1 == _activity.intensity),
                    onChanged: (i) {
                      final intensity = _intensities[i].$1;
                      if (!available.contains(intensity)) {
                        showToast(
                          context,
                          '${_groupStyle(_group).$1} has no ${_intensities[i].$2.toLowerCase()} option',
                          icon: Icons.info_outline_rounded,
                        );
                        return;
                      }
                      setState(() => _activity = _pickFor(_group, intensity));
                    },
                  ),
                  if (sameIntensity.length > 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in sameIntensity)
                          _chip(_activityName(a), a.id == _activity.id, () => setState(() => _activity = a)),
                      ],
                    )
                  else
                    Text(
                      '${_activityName(_activity)} · MET ${_activity.met}',
                      style: ts(13, FontWeight.w400, AppColors.muted),
                    ),
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
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated burn', style: ts(13, FontWeight.w400, const Color(0xFF2F6B3F))),
                        if (kcal == null)
                          PressScale(
                            label: 'Add your weight',
                            onTap: () => Navigator.of(context).push(slideRoute(const EditProfileScreen())),
                            child: Text('Add your weight →', style: ts(16, FontWeight.w700, AppColors.greenDark)),
                          )
                        else
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: kcal),
                            duration: const Duration(milliseconds: 400),
                            curve: Motion.standard,
                            builder: (context, v, _) =>
                                Text('${v.round()} kcal', style: ts(26, FontWeight.w800, AppColors.greenDark)),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Last 7 days', style: ts(13, FontWeight.w400, const Color(0xFF2F6B3F))),
                      Text('$activeDays active ${activeDays == 1 ? 'day' : 'days'}', style: ts(18, FontWeight.w700)),
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

          _saving
              ? Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.greenDark, borderRadius: BorderRadius.circular(16)),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  ),
                )
              : PrimaryButton(label: 'Save exercise', onTap: kcal == null ? _needWeight : _save),
        ],
      ),
    );
  }

  void _needWeight() {
    showToast(context, 'Add your weight in your profile first', icon: Icons.info_outline_rounded);
    Navigator.of(context).push(slideRoute(const EditProfileScreen()));
  }
}
