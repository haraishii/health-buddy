import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/animated.dart';
import '../widgets/common.dart';

class StressCheckScreen extends StatefulWidget {
  const StressCheckScreen({super.key});

  @override
  State<StressCheckScreen> createState() => _StressCheckScreenState();
}

class _StressCheckScreenState extends State<StressCheckScreen> {
  int _level = 4;
  final _factors = <String>{'Exams'};
  bool _breathing = false;

  static const _factorNames = ['Exams', 'Assignments', 'Sleep', 'Friends', 'Family', 'Money'];

  (String, IconData) get _mood {
    if (_level <= 3) return ('Calm', Icons.sentiment_very_satisfied_rounded);
    if (_level <= 6) return ('A bit tense', Icons.sentiment_neutral_rounded);
    return ('Stressed', Icons.sentiment_dissatisfied_rounded);
  }

  void _save() {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(toastBar('Saved. Your Analytics will update.'));
  }

  @override
  Widget build(BuildContext context) {
    final mood = _mood;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                                    border: Border.all(
                                      color: i == _level ? AppColors.purpleDark : AppColors.borderStrong,
                                    ),
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
                          for (final f in _factorNames)
                            PressScale(
                              label: f,
                              onTap: () => setState(() => _factors.contains(f) ? _factors.remove(f) : _factors.add(f)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _factors.contains(f) ? AppColors.purpleSoft : Colors.white,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: _factors.contains(f) ? AppColors.purple : AppColors.borderStrong,
                                  ),
                                ),
                                child: Text(
                                  f,
                                  style: ts(
                                    14,
                                    FontWeight.w600,
                                    _factors.contains(f) ? AppColors.purpleDeep : AppColors.text,
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
                          decoration: BoxDecoration(
                            color: AppColors.purpleDark,
                            borderRadius: BorderRadius.circular(99),
                          ),
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

              PrimaryButton(label: 'Save check-in', onTap: _save),
            ],
          ),
        ),
      ),
    );
  }
}
