import 'package:flutter/material.dart';

import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_models.dart';
import '../../../../data/api/session.dart';
import '../../../../theme.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/format.dart';
import '../../../../widgets/skeleton.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiBuilder<DaySummary>(
      // Same request as Home, so switching tabs reuses the cached data.
      cacheKey: 'summary:${apiDate(DateTime.now())}',
      load: (api) => api.summary(),
      loading: const SkeletonPage(
        children: [SkeletonCard(lines: 4), SkeletonCard(lines: 4), SkeletonCard(lines: 2), SkeletonCard(lines: 5)],
      ),
      builder: (context, summary) => _ProfileBody(summary: summary),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody({required this.summary});

  final DaySummary summary;

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  // Switch values while a change is being saved, so the toggle moves at once.
  final _pending = <String, bool>{};

  static String _number(double? v) => v == null ? '–' : (v == v.roundToDouble() ? '${v.round()}' : '$v');

  /// Saves a setting; updateProfile already reloads the screens, errors become a toast.
  Future<void> _saveSetting(Future<void> Function(Session s) save) async {
    try {
      await save(SessionScope.of(context));
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _toggle(String key, bool value, Future<void> Function(Session s) save) async {
    setState(() => _pending[key] = value);
    await _saveSetting(save);
    if (mounted) setState(() => _pending.remove(key));
  }

  Future<void> _pickBedtime(ApiUser user) async {
    final parts = user.bedtimeTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      helpText: 'Bedtime reminder',
    );
    if (picked == null || !mounted) return;
    final hhmm = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await _saveSetting((s) => s.updateProfile(bedtimeTime: hhmm));
  }

  Future<void> _pickLanguage(ApiUser user) async {
    const options = [('en', 'English'), ('id', 'Bahasa Indonesia')];
    final picked = await showModalBottomSheet<String>(
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
              Text('Coach language', style: ts(18, FontWeight.w700)),
              Text('Used for tips and AI Coach answers.', style: ts(13, FontWeight.w400, AppColors.muted)),
              const SizedBox(height: 8),
              for (final o in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o.$2, style: ts(15, o.$1 == user.language ? FontWeight.w700 : FontWeight.w400)),
                  trailing: o.$1 == user.language ? const Icon(Icons.check_rounded, color: AppColors.green) : null,
                  onTap: () => Navigator.of(sheetContext).pop(o.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == user.language || !mounted) return;
    await _saveSetting((s) => s.updateProfile(language: picked));
  }

  Widget _section(String title, List<Widget> rows, int delayMs) {
    return FadeUp(
      delayMs: delayMs,
      child: AppCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: ts(16, FontWeight.w700)),
            const SizedBox(height: 4),
            for (var i = 0; i < rows.length; i++)
              Container(
                constraints: const BoxConstraints(minHeight: 52),
                decoration: BoxDecoration(
                  border: i == rows.length - 1 ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                alignment: Alignment.centerLeft,
                child: rows[i],
              ),
          ],
        ),
      ),
    );
  }

  Widget _valueRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: ts(15)),
      Text(value, style: ts(15, FontWeight.w700)),
    ],
  );

  Widget _linkRow(String label, {String? value, VoidCallback? onTap}) => PressScale(
    label: label,
    onTap: onTap ?? () => showToast(context, '$label: coming soon', icon: Icons.info_outline_rounded),
    child: SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(child: Text(label, style: ts(15))),
          if (value != null) Text(value, style: ts(14, FontWeight.w400, AppColors.muted)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );

  Widget _switchRow(String key, String label, bool value, Future<void> Function(Session s, bool v) save) => Row(
    children: [
      Expanded(child: Text(label, style: ts(15))),
      ToggleSwitch(label: label, value: _pending[key] ?? value, onChanged: (v) => _toggle(key, v, (s) => save(s, v))),
    ],
  );

  Widget _connectedRow(String title, String subtitle, Widget trailing) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      spacing: 10,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ts(15)),
              Text(subtitle, style: ts(12, FontWeight.w400, AppColors.muted)),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );

  void _editProfile() => Navigator.of(context).push(slideRoute(const EditProfileScreen()));

  @override
  Widget build(BuildContext context) {
    final user = widget.summary.user;
    final targets = widget.summary.targets;
    final session = SessionScope.of(context);

    String sleepGoal(Targets t) {
      if (t.sleepHoursMin == null) return '–';
      final min = _number(t.sleepHoursMin), max = _number(t.sleepHoursMax);
      return min == max ? '$min h' : '$min–$max h';
    }

    return AppRefresh(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            FadeUp(child: Text('Profile', style: ts(28, FontWeight.w800).copyWith(letterSpacing: -0.5, height: 1.15))),

            FadeUp(
              delayMs: 60,
              child: AppCard(
                radius: 20,
                padding: const EdgeInsets.all(18),
                child: Column(
                  spacing: 16,
                  children: [
                    Row(
                      spacing: 14,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.greenTint, shape: BoxShape.circle),
                          child: Text(
                            user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                            style: ts(26, FontWeight.w800, AppColors.greenDark),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: ts(20, FontWeight.w700), overflow: TextOverflow.ellipsis),
                              Text(
                                [
                                  user.status,
                                  if (user.createdAt != null) 'joined ${fmtMonthYear(user.createdAt!.toLocal())}',
                                ].join(' · '),
                                style: ts(14, FontWeight.w400, AppColors.muted),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.email,
                                style: ts(12.5, FontWeight.w400, AppColors.muted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        OutlineChipButton(label: 'Edit', onTap: _editProfile),
                      ],
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        for (final s in [
                          (user.age?.toString() ?? '–', 'Age'),
                          (_number(user.heightCm), 'Height (cm)'),
                          (_number(user.weightKg), 'Weight (kg)'),
                        ])
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
                              child: Column(
                                children: [
                                  Text(s.$1, style: ts(17, FontWeight.w700)),
                                  Text(s.$2, style: ts(12, FontWeight.w400, AppColors.muted)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            _section(
              'Daily goals',
              targets == null
                  ? [_linkRow('Complete your profile to see your goals', onTap: _editProfile)]
                  : [
                      _valueRow('Sleep', sleepGoal(targets)),
                      _valueRow('Steps', fmtNum(targets.stepsTarget)),
                      _valueRow('Protein', '${fmtNum(targets.proteinG)} g'),
                      _valueRow('Water', fmtLiters(targets.waterMl)),
                      _valueRow('Energy', '${fmtNum(targets.energyKcal)} kcal'),
                    ],
              120,
            ),

            _section('Connected data', [
              _connectedRow(
                'Health Connect / HealthKit',
                'Automatic step sync is coming. Tap Steps on Home to enter them for now.',
                const Pill('Soon', color: AppColors.muted, bg: AppColors.track),
              ),
              _connectedRow(
                'Smartwatch (sleep)',
                'Optional, sleep is logged manually now',
                OutlineChipButton(
                  label: 'Connect',
                  onTap: () => showToast(context, 'Wearable sync is planned for phase 3', icon: Icons.watch_outlined),
                ),
              ),
            ], 180),

            _section('Settings', [
              _switchRow(
                'daily',
                'Daily check-in reminder',
                user.reminderDaily,
                (s, v) => s.updateProfile(reminderDaily: v),
              ),
              Row(
                children: [
                  Expanded(
                    child: PressScale(
                      label: 'Change bedtime',
                      onTap: () => _pickBedtime(user),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Bedtime reminder '),
                            TextSpan(
                              text: '(${fmtClock(user.bedtimeTime)})',
                              style: ts(15, FontWeight.w600, AppColors.greenDark),
                            ),
                          ],
                        ),
                        style: ts(15),
                      ),
                    ),
                  ),
                  ToggleSwitch(
                    label: 'Bedtime reminder',
                    value: _pending['bedtime'] ?? user.reminderBedtime,
                    onChanged: (v) => _toggle('bedtime', v, (s) => s.updateProfile(reminderBedtime: v)),
                  ),
                ],
              ),
              _switchRow(
                'weekly',
                'Weekly AI summary',
                user.weeklySummary,
                (s, v) => s.updateProfile(weeklySummary: v),
              ),
              _linkRow('Privacy & data'),
              _linkRow(
                'Language',
                value: user.language == 'id' ? 'Bahasa Indonesia' : 'English',
                onTap: () => _pickLanguage(user),
              ),
            ], 240),

            FadeUp(
              delayMs: 300,
              child: PressScale(
                label: 'Log out',
                onTap: session.signOut,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3D0D0)),
                  ),
                  child: Text('Log out', style: ts(15, FontWeight.w600, AppColors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
