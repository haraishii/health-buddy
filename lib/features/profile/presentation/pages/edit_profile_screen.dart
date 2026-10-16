import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_models.dart';
import '../../../../data/api/session.dart';
import '../../../../theme.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/format.dart';
import '../../../../widgets/skeleton.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';

/// Edit name, status, birth date, sex, height, weight, life stage and steps target.
/// Birth date and sex pick the daily targets; weight is used for calories burned.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ApiBuilder<ApiUser>(
          cacheKey: 'me',
          load: (api) => api.me(),
          loading: const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                BackHeader('Edit profile'),
                Expanded(
                  child: Shimmer(
                    child: Column(spacing: 14, children: [SkeletonCard(lines: 6), SkeletonCard(lines: 4)]),
                  ),
                ),
              ],
            ),
          ),
          builder: (context, user) => _EditProfileForm(user: user),
        ),
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({required this.user});

  final ApiUser user;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  static const _lifeStages = [
    ('general', 'Not pregnant or breastfeeding'),
    ('pregnant_t1', 'Pregnant · trimester 1'),
    ('pregnant_t2', 'Pregnant · trimester 2'),
    ('pregnant_t3', 'Pregnant · trimester 3'),
    ('breastfeeding_0_6m', 'Breastfeeding · 0–6 months'),
    ('breastfeeding_7_12m', 'Breastfeeding · 7–12 months'),
  ];

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _status = TextEditingController(text: widget.user.status);
  late final _height = TextEditingController(text: _num(widget.user.heightCm));
  late final _weight = TextEditingController(text: _num(widget.user.weightKg));
  late final _steps = TextEditingController(text: widget.user.stepsTarget?.toString() ?? '');
  late DateTime? _birthDate = widget.user.birthDate == null ? null : DateTime.parse(widget.user.birthDate!);
  late String? _sex = widget.user.sex;
  late String _lifeStage = widget.user.lifeStage;
  bool _saving = false;
  String? _error;

  static String _num(double? v) => v == null ? '' : (v == v.roundToDouble() ? '${v.round()}' : '$v');

  @override
  void dispose() {
    for (final c in [_name, _status, _height, _weight, _steps]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Birth date',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String? _range(String? v, double min, double max, String unit, {bool required = false}) {
    final s = (v ?? '').trim().replaceAll(',', '.');
    if (s.isEmpty) return required ? 'Required' : null;
    final n = double.tryParse(s);
    if (n == null || n < min || n > max) return 'Enter ${min.round()}–${max.round()} $unit';
    return null;
  }

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final session = SessionScope.of(context);
    final steps = int.tryParse(_steps.text.trim());
    try {
      await session.updateProfile(
        name: _name.text.trim(),
        status: _status.text.trim().isEmpty ? null : _status.text.trim(),
        birthDate: _birthDate,
        sex: _sex,
        heightCm: _parse(_height.text),
        weightKg: _parse(_weight.text),
        lifeStage: _sex == 'F' ? _lifeStage : 'general',
        stepsTarget: steps,
        clearStepsTarget: steps == null && widget.user.stepsTarget != null,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(toastBar('Profile saved. Your targets are updated.'));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Text(text, style: ts(14, FontWeight.w600));

  @override
  Widget build(BuildContext context) {
    final numbers = <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            const BackHeader('Edit profile'),

            FadeUp(
              child: AppCard(
                radius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    Text('About you', style: ts(16, FontWeight.w700)),
                    AuthTextField(
                      label: 'Name',
                      controller: _name,
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                      enabled: !_saving,
                    ),
                    AuthTextField(
                      label: 'Status',
                      controller: _status,
                      hint: 'e.g. Student',
                      icon: Icons.school_outlined,
                      enabled: !_saving,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        _label('Birth date'),
                        PressScale(
                          label: 'Pick birth date',
                          onTap: _saving ? null : _pickBirthDate,
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderStrong),
                            ),
                            child: Row(
                              spacing: 12,
                              children: [
                                const Icon(Icons.cake_outlined, size: 20, color: AppColors.muted),
                                Expanded(
                                  child: Text(
                                    _birthDate == null
                                        ? 'Choose a date'
                                        : '${fmtShortDate(_birthDate!)}, ${_birthDate!.year}',
                                    style: ts(
                                      15,
                                      FontWeight.w400,
                                      _birthDate == null ? AppColors.muted : AppColors.text,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        _label('Sex'),
                        Segmented(
                          options: const ['Male', 'Female'],
                          index: switch (_sex) {
                            'M' => 0,
                            'F' => 1,
                            _ => -1,
                          },
                          onChanged: (i) => setState(() => _sex = i == 0 ? 'M' : 'F'),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    Text('Body', style: ts(16, FontWeight.w700)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Expanded(
                          child: AuthTextField(
                            label: 'Height (cm)',
                            controller: _height,
                            hint: '160',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => _range(v, 50, 250, 'cm'),
                            enabled: !_saving,
                            inputFormatters: numbers,
                          ),
                        ),
                        Expanded(
                          child: AuthTextField(
                            label: 'Weight (kg)',
                            controller: _weight,
                            hint: '55',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => _range(v, 20, 300, 'kg'),
                            enabled: !_saving,
                            inputFormatters: numbers,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Weight is used to estimate calories burned when you log exercise.',
                      style: ts(12.5, FontWeight.w400, AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),

            if (_sex == 'F')
              FadeUp(
                delayMs: 90,
                child: AppCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      Text('Life stage', style: ts(16, FontWeight.w700)),
                      Text(
                        'Pregnancy and breastfeeding change your daily nutrition targets.',
                        style: ts(12.5, FontWeight.w400, AppColors.muted),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in _lifeStages)
                            PressScale(
                              label: s.$2,
                              onTap: () => setState(() => _lifeStage = s.$1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _lifeStage == s.$1 ? AppColors.greenSoft : Colors.white,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: _lifeStage == s.$1 ? AppColors.green : AppColors.borderStrong,
                                  ),
                                ),
                                child: Text(
                                  s.$2,
                                  style: ts(
                                    13.5,
                                    FontWeight.w600,
                                    _lifeStage == s.$1 ? AppColors.greenDark : AppColors.text,
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
              delayMs: 120,
              child: AppCard(
                radius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Text('Goals', style: ts(16, FontWeight.w700)),
                    AuthTextField(
                      label: 'Daily steps target',
                      controller: _steps,
                      hint: 'Recommended target',
                      helper: 'Leave empty to use the recommended target.',
                      icon: Icons.directions_walk_rounded,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (v) => _range(v, 1, 100000, 'steps'),
                      enabled: !_saving,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null) AuthErrorBanner(_error!),
            AuthSubmitButton(label: 'Save profile', loading: _saving, onTap: _save),
          ],
        ),
      ),
    );
  }
}
