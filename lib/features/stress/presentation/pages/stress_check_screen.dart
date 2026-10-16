import 'package:flutter/material.dart';

import '../../../../data/api/api_models.dart';
import '../../../../data/api/session.dart';
import '../../../../theme.dart';
import '../../../../widgets/animated.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/skeleton.dart';

class StressCheckScreen extends StatelessWidget {
  const StressCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ApiBuilder<StressInfo>(
          cacheKey: 'stress-info',
          load: (api) => api.stressInfo(),
          loading: const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                BackHeader('Stress Check'),
                Shimmer(
                  child: Column(
                    spacing: 14,
                    children: [SkeletonCard(lines: 5), SkeletonCard(lines: 2), SkeletonCard(lines: 3)],
                  ),
                ),
              ],
            ),
          ),
          builder: (context, info) => _StressForm(info: info),
        ),
      ),
    );
  }
}

class _StressForm extends StatefulWidget {
  const _StressForm({required this.info});

  final StressInfo info;

  @override
  State<_StressForm> createState() => _StressFormState();
}

class _StressFormState extends State<_StressForm> {
  int _level = 5;
  final _factors = <String>{};
  bool _breathing = false;
  bool _saving = false;

  (String, IconData) get _mood {
    final category = widget.info.bandFor(_level)?.category;
    return switch (category) {
      'Low' => ('Low stress', Icons.sentiment_very_satisfied_rounded),
      'High' => ('High stress', Icons.sentiment_dissatisfied_rounded),
      'Medium' => ('Medium stress', Icons.sentiment_neutral_rounded),
      _ => ('', Icons.sentiment_neutral_rounded),
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await saveWithFeedback(context, (api) => api.addStress(level: _level, factorIds: _factors.toList()));
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(toastBar('Saved. Your Analytics will update.'));
  }

  @override
  Widget build(BuildContext context) {
    final mood = _mood;
    final english = SessionScope.of(context).user?.language != 'id';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          const BackHeader('Stress Check'),

          FadeUp(
            child: AppCard(
              radius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  Text('How stressed do you feel right now?', style: ts(17, FontWeight.w700)),
                  Row(
                    spacing: 12,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(color: AppColors.purpleSoft, shape: BoxShape.circle),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                          child: Icon(mood.$2, key: ValueKey(mood.$2), color: AppColors.purple, size: 34),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_level',
                                  style: ts(28, FontWeight.w800, AppColors.purpleDark).copyWith(height: 1),
                                ),
                                TextSpan(text: ' /10', style: ts(15, FontWeight.w500, AppColors.muted)),
                              ],
                            ),
                          ),
                          Text(mood.$1, style: ts(14, FontWeight.w400, AppColors.muted)),
                        ],
                      ),
                    ],
                  ),
                  GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.15,
                    children: [
                      for (var i = 1; i <= 10; i++)
                        Semantics(
                          selected: i == _level,
                          child: PressScale(
                            label: 'Stress level $i',
                            scale: 0.92,
                            onTap: () => setState(() => _level = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i == _level ? AppColors.purpleDark : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: i == _level ? AppColors.purpleDark : AppColors.borderStrong),
                              ),
                              child: Text(
                                '$i',
                                style: ts(15, FontWeight.w700, i == _level ? Colors.white : AppColors.text),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 = calm', style: ts(12, FontWeight.w400, AppColors.muted)),
                      Text('10 = very stressed', style: ts(12, FontWeight.w400, AppColors.muted)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text("What's on your mind?", style: ts(17, FontWeight.w700)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final factor in widget.info.factors)
                        PressScale(
                          label: english ? factor.nameEn : factor.name,
                          onTap: () => setState(
                            () => _factors.contains(factor.id) ? _factors.remove(factor.id) : _factors.add(factor.id),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _factors.contains(factor.id) ? AppColors.purpleSoft : Colors.white,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: _factors.contains(factor.id) ? AppColors.purple : AppColors.borderStrong,
                              ),
                            ),
                            child: Text(
                              english ? factor.nameEn : factor.name,
                              style: ts(
                                14,
                                FontWeight.w600,
                                _factors.contains(factor.id) ? AppColors.purpleDeep : AppColors.text,
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
              color: AppColors.purpleCard,
              borderColor: AppColors.purpleBorder,
              padding: const EdgeInsets.all(18),
              child: Column(
                spacing: 12,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('1-minute breathing', style: ts(17, FontWeight.w700)),
                  ),
                  BreathingCircle(running: _breathing),
                  Text(
                    'Breathe in for 4 s as it grows, out for 4 s as it shrinks.',
                    textAlign: TextAlign.center,
                    style: ts(14, FontWeight.w400, const Color(0xFF4C1D95)),
                  ),
                  PressScale(
                    label: _breathing ? 'Stop' : 'Start breathing',
                    onTap: () => setState(() => _breathing = !_breathing),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.purpleDark, borderRadius: BorderRadius.circular(99)),
                      child: Text(
                        _breathing ? 'Stop' : 'Start breathing',
                        style: ts(15, FontWeight.w700, Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              : PrimaryButton(label: 'Save check-in', onTap: _save),
        ],
      ),
    );
  }
}
