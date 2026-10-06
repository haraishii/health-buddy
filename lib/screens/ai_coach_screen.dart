import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/animated.dart';
import '../widgets/common.dart';
import 'log_exercise_screen.dart';
import 'scan_meal_screen.dart';
import 'stress_check_screen.dart';

class _ChatMsg {
  const _ChatMsg(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

/// Sample answers. The MVP keeps these as templates;
/// phase 2 replaces them with calls to an AI model.
const _cannedReplies = {
  'tired': 'Mostly sleep: you averaged 6 h 10 m this week. Try winding down 30 minutes earlier tonight.',
  'eat': 'You are 18 g short of your protein goal. For lunch, try grilled chicken or tofu with rice and vegetables.',
  'stress': 'Try the 1-minute breathing exercise in Stress Check now. Your stress is 20% lower on days you exercise.',
  'week': 'Your Health Score rose 12% to 85. Best day: Saturday (88). Exercise (70) has the most room to grow.',
  'other': 'Thanks! In the full app, the AI model answers this using your data from the last 7 days.',
};

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _messages = <_ChatMsg>[];
  final _input = TextEditingController();
  final _endKey = GlobalKey();
  bool _typing = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _endKey.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(ctx, duration: Motion.push, curve: Motion.standard, alignment: 1);
      }
    });
  }

  void _send(String text, [String key = 'other']) {
    final clean = text.trim();
    if (clean.isEmpty || _typing) return;
    setState(() {
      _messages.add(_ChatMsg(clean, true));
      _typing = true;
      _input.clear();
    });
    _scrollToEnd();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(_ChatMsg(_cannedReplies[key]!, false));
      });
      _scrollToEnd();
    });
  }

  void _showHistory() {
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
              Text('Chat history', style: ts(18, FontWeight.w700)),
              const SizedBox(height: 8),
              for (final h in const [
                ('Why am I feeling tired lately?', 'Today'),
                ('What should I eat before an exam?', 'May 15'),
                ('How do I sleep earlier?', 'May 12'),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.muted),
                  title: Text(h.$1, style: ts(15)),
                  trailing: Text(h.$2, style: ts(13, FontWeight.w400, AppColors.muted)),
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const chips = [
      ('Why am I feeling tired?', 'tired', Icons.bedtime_outlined, AppColors.purple),
      ('What should I eat today?', 'eat', Icons.lunch_dining_outlined, AppColors.green),
      ('How can I reduce my stress?', 'stress', Icons.spa_outlined, AppColors.blue),
      ('Analyze my weekly progress', 'week', Icons.bar_chart_rounded, AppColors.orangeDark),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                FadeUp(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Text(
                              'AI Coach',
                              style: ts(28, FontWeight.w800).copyWith(letterSpacing: -0.5, height: 1.15),
                            ),
                            Text(
                              'Your personal AI wellness assistant',
                              style: ts(14, FontWeight.w400, AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      OutlineChipButton(label: 'History', icon: Icons.history_rounded, onTap: _showHistory),
                    ],
                  ),
                ),

                // Mascot + summary
                FadeUp(
                  delayMs: 60,
                  child: AppCard(
                    color: AppColors.purpleCard,
                    borderColor: AppColors.purpleBorder,
                    radius: 20,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        Row(
                          spacing: 10,
                          children: [
                            const RobotMascot(),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 2,
                                  children: [
                                    Text('Hi Annida!', style: ts(15, FontWeight.w700)),
                                    Text("I'm Health Buddy AI.", style: ts(15, FontWeight.w700, AppColors.greenDark)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'I look at your health data and give personal tips.',
                                      style: ts(13, FontWeight.w400, AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 8,
                            children: [
                              Text('Today at a glance', style: ts(14, FontWeight.w700)),
                              _GlanceRow(
                                Icons.eco_rounded,
                                AppColors.green,
                                'Health Score',
                                '85 /100',
                                AppColors.greenDark,
                              ),
                              _GlanceRow(
                                Icons.sentiment_satisfied_alt_rounded,
                                AppColors.purple,
                                'Stress Level',
                                'Low',
                                AppColors.purpleDark,
                              ),
                              _GlanceRow(
                                Icons.directions_run_rounded,
                                AppColors.blue,
                                'Activity',
                                'Moderate',
                                AppColors.blueDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick questions
                FadeUp(
                  delayMs: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      Text('Ask me anything about your health', style: ts(16, FontWeight.w700)),
                      twoColumns(gap: 8, [
                        for (final c in chips)
                          AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            radius: 14,
                            borderColor: AppColors.borderStrong,
                            onTap: () => _send(c.$1, c.$2),
                            label: c.$1,
                            child: Row(
                              spacing: 8,
                              children: [
                                Icon(c.$3, color: c.$4, size: 22),
                                Expanded(child: Text(c.$1, style: ts(13, FontWeight.w600), maxLines: 2)),
                              ],
                            ),
                          ),
                      ]),
                      Text(
                        'Health Buddy gives lifestyle tips, not medical advice.',
                        style: ts(12, FontWeight.w400, AppColors.muted),
                      ),
                    ],
                  ),
                ),

                // Conversation
                FadeUp(
                  delayMs: 250,
                  offset: const Offset(24, 0),
                  duration: const Duration(milliseconds: 200),
                  child: const _Bubble.user('Why am I feeling tired lately?', time: '9:40'),
                ),
                const FadeUp(delayMs: 450, duration: Duration(milliseconds: 260), child: _FirstReply()),
                for (final m in _messages)
                  FadeUp(
                    key: ObjectKey(m),
                    offset: m.fromUser ? const Offset(24, 0) : const Offset(0, 12),
                    duration: Duration(milliseconds: m.fromUser ? 200 : 260),
                    child: m.fromUser ? _Bubble.user(m.text) : _Bubble.bot(m.text),
                  ),
                if (_typing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const TypingDots(),
                    ),
                  ),
                SizedBox(key: _endKey, height: 1),

                // Quick actions
                Text('Quick Actions', style: ts(16, FontWeight.w700)),
                twoColumns(gap: 8, [
                  _CoachAction(
                    Icons.directions_run_rounded,
                    AppColors.blue,
                    'Log Exercise',
                    () => Navigator.of(context).push(slideRoute(const LogExerciseScreen())),
                  ),
                  _CoachAction(
                    Icons.photo_camera_outlined,
                    AppColors.green,
                    'Scan Meal',
                    () => Navigator.of(context).push(slideRoute(const ScanMealScreen())),
                  ),
                  _CoachAction(
                    Icons.sentiment_satisfied_alt_rounded,
                    AppColors.purple,
                    'Stress Check',
                    () => Navigator.of(context).push(slideRoute(const StressCheckScreen())),
                  ),
                  _CoachAction(
                    Icons.bar_chart_rounded,
                    AppColors.orangeDark,
                    'View Analytics',
                    () => currentTab.value = 1,
                  ),
                ]),
              ],
            ),
          ),
        ),

        // Message input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 5, 5, 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (v) => _send(v),
                    style: ts(15),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Type your message…',
                      hintStyle: ts(15, FontWeight.w400, AppColors.muted),
                    ),
                  ),
                ),
                PressScale(
                  label: 'Send',
                  onTap: () => _send(_input.text),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlanceRow extends StatelessWidget {
  const _GlanceRow(this.icon, this.iconColor, this.label, this.value, this.valueColor);

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Icon(icon, color: iconColor, size: 20),
        Expanded(child: Text(label, style: ts(14))),
        Text(value, style: ts(14, FontWeight.w700, valueColor)),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble.user(this.text, {this.time}) : fromUser = true;
  const _Bubble.bot(this.text) : fromUser = false, time = null;

  final String text;
  final bool fromUser;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * (fromUser ? 0.78 : 0.85)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: fromUser ? AppColors.greenBubble : Colors.white,
        border: Border.all(color: fromUser ? AppColors.greenBubbleBorder : AppColors.border),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(fromUser ? 16 : 4),
          bottomRight: Radius.circular(fromUser ? 4 : 16),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            if (time != null) TextSpan(text: '   $time', style: ts(11, FontWeight.w400, AppColors.muted)),
          ],
        ),
        style: ts(14).copyWith(height: 1.45),
      ),
    );
    return Align(alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft, child: bubble);
  }
}

class _FirstReply extends StatelessWidget {
  const _FirstReply();

  @override
  Widget build(BuildContext context) {
    Widget check(String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.check_circle_rounded, color: AppColors.green, size: 19),
        ),
        Expanded(child: Text(text, style: ts(14).copyWith(height: 1.4))),
      ],
    );
    Widget reason(IconData icon, Color color, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Icon(icon, color: color, size: 19),
        Expanded(child: Text(text, style: ts(14).copyWith(height: 1.4))),
      ],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.88),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('From your last 7 days, these might be why you feel tired:', style: ts(14).copyWith(height: 1.45)),
            reason(Icons.bedtime_outlined, AppColors.purple, 'Your average sleep dropped by 1.5 hours.'),
            reason(Icons.restaurant_outlined, AppColors.orangeDark, 'Your protein intake is below your daily target.'),
            reason(Icons.psychology_outlined, AppColors.blue, 'Your stress was high on 3 days.'),
            const Divider(height: 12, color: AppColors.track),
            Text('My recommendations:', style: ts(14, FontWeight.w700, AppColors.greenDark)),
            check('Sleep before 11:00 PM tonight.'),
            check('Increase protein (target 60 g/day).'),
            check('Take a 20-minute walk after class.'),
            check('Drink 1.8–2 L of water a day.'),
            Align(
              alignment: Alignment.centerRight,
              child: Text('9:41', style: ts(11, FontWeight.w400, AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachAction extends StatelessWidget {
  const _CoachAction(this.icon, this.color, this.label, this.onTap);

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      radius: 14,
      borderColor: AppColors.borderStrong,
      onTap: onTap,
      label: label,
      child: Row(
        spacing: 8,
        children: [
          Icon(icon, color: color, size: 21),
          Expanded(
            child: Text(label, style: ts(14, FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
