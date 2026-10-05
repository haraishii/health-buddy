import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _toggles = <String, bool>{
    'Daily check-in reminder': true,
    'Bedtime reminder (10:30 PM)': true,
    'Weekly AI summary': false,
  };

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
        children: [Text(label, style: ts(15)), Text(value, style: ts(15, FontWeight.w700))],
      );

  Widget _linkRow(String label, {String? value}) => PressScale(
        label: label,
        onTap: () => showToast(context, '$label: coming soon', icon: Icons.info_outline_rounded),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                        child: Text('A', style: ts(26, FontWeight.w800, AppColors.greenDark)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Annida', style: ts(20, FontWeight.w700)),
                            Text('Student · joined May 2026', style: ts(14, FontWeight.w400, AppColors.muted)),
                          ],
                        ),
                      ),
                      OutlineChipButton(
                        label: 'Edit',
                        onTap: () => showToast(context, 'Edit profile: coming soon', icon: Icons.info_outline_rounded),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      for (final s in const [('[age]', 'Age'), ('[cm]', 'Height'), ('[kg]', 'Weight')])
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

          _section('Daily goals', [
            _valueRow('Sleep', '8 h'),
            _valueRow('Steps', '8,000'),
            _valueRow('Protein', '60 g'),
            _valueRow('Water', '2 L'),
          ], 120),

          _section('Connected data', [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Health Connect / HealthKit', style: ts(15)),
                        Text('Steps and activity, synced automatically', style: ts(12, FontWeight.w400, AppColors.muted)),
                      ],
                    ),
                  ),
                  const Pill('Connected'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Smartwatch (sleep)', style: ts(15)),
                        Text('Optional, sleep is logged manually now', style: ts(12, FontWeight.w400, AppColors.muted)),
                      ],
                    ),
                  ),
                  OutlineChipButton(
                    label: 'Connect',
                    onTap: () => showToast(context, 'Wearable sync is planned for phase 3', icon: Icons.watch_outlined),
                  ),
                ],
              ),
            ),
          ], 180),

          _section('Settings', [
            for (final e in _toggles.entries)
              Row(
                children: [
                  Expanded(child: Text(e.key, style: ts(15))),
                  ToggleSwitch(
                    label: e.key,
                    value: e.value,
                    onChanged: (v) => setState(() => _toggles[e.key] = v),
                  ),
                ],
              ),
            _linkRow('Privacy & data'),
            _linkRow('Language', value: 'English'),
          ], 240),

          FadeUp(
            delayMs: 300,
            child: PressScale(
              label: 'Log out',
              onTap: () => showToast(context, 'Logged out (demo)', icon: Icons.logout_rounded),
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
    );
  }
}
