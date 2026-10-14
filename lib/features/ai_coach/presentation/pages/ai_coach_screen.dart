import 'package:flutter/material.dart';

import '../../../../app/navigation/app_tab_controller.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_models.dart';
import '../../../../data/api/session.dart';
import '../../../../theme.dart';
import '../../../../widgets/animated.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/format.dart';
import '../../../../widgets/skeleton.dart';
import '../../../exercise/presentation/pages/log_exercise_screen.dart';
import '../../../food/presentation/pages/scan_meal_screen.dart';
import '../../../stress/presentation/pages/stress_check_screen.dart';

typedef _CoachData = ({DaySummary summary, CoachContent content, List<ChatMessage> history});

/// Icon and colour per coach topic (presentation only).
(IconData, Color) _topicStyle(String topic) => switch (topic) {
  'sleep' => (Icons.bedtime_outlined, AppColors.purple),
  'food and nutrition' || 'protein' => (Icons.lunch_dining_outlined, AppColors.green),
  'stress' => (Icons.spa_outlined, AppColors.blue),
  'drinking water' => (Icons.water_drop_outlined, AppColors.sky),
  'activity' => (Icons.directions_run_rounded, AppColors.blueDark),
  _ => (Icons.bar_chart_rounded, AppColors.orangeDark),
};

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiBuilder<_CoachData>(
      cacheKey: 'coach:${apiDate(DateTime.now())}',
      load: (api) async {
        final results = await Future.wait<Object>([api.summary(), api.coachContent(), api.coachHistory()]);
        return (
          summary: results[0] as DaySummary,
          content: results[1] as CoachContent,
          history: results[2] as List<ChatMessage>,
        );
      },
      loading: const SkeletonPage(children: [SkeletonCard(lines: 5), SkeletonCard(lines: 3), SkeletonCard(lines: 2)]),
      builder: (context, data) => _CoachBody(data: data),
    );
  }
}

class _CoachBody extends StatefulWidget {
  const _CoachBody({required this.data});

  final _CoachData data;

  @override
  State<_CoachBody> createState() => _CoachBodyState();
}

class _CoachBodyState extends State<_CoachBody> {
  // Messages sent in this visit; the history from the server comes first.
  final _messages = <ChatMessage>[];
  final _input = TextEditingController();
  final _endKey = GlobalKey();
  bool _typing = false;

  @override
  void didUpdateWidget(_CoachBody old) {
    super.didUpdateWidget(old);
    // After a reload the server history already contains what was sent here.
    final known = {for (final m in widget.data.history) m.id};
    _messages.removeWhere((m) => known.contains(m.id));
  }

  @override
  void dispose() {
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

  String _questionText(QuickQuestion q) => widget.data.summary.user.language == 'id' ? q.text : (q.textEn ?? q.text);

  Future<void> _send({String? text, QuickQuestion? question}) async {
    final clean = (text ?? '').trim();
    if ((clean.isEmpty && question == null) || _typing) return;
    final pending = ChatMessage(
      id: -1,
      role: 'user',
      text: question == null ? clean : _questionText(question),
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(pending);
      _typing = true;
      _input.clear();
    });
    _scrollToEnd();
    try {
      final result = await SessionScope.of(context).api
          .askCoach(questionId: question?.id, text: question == null ? clean : null);
      if (!mounted) return;
      setState(() {
        _messages
          ..remove(pending)
          ..addAll([result.question, result.answer]);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _messages.remove(pending));
      showToast(context, e.message, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _typing = false);
      _scrollToEnd();
    }
  }

  void _showHistory(List<ChatMessage> all) {
    final questions = all.where((m) => m.fromUser && m.id > 0).toList().reversed.toList();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Chat history', style: ts(18, FontWeight.w700)),
                const SizedBox(height: 8),
                if (questions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No questions yet. Ask me anything below.',
                      style: ts(14, FontWeight.w400, AppColors.muted),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final q in questions)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.muted),
                            title: Text(q.text, style: ts(15)),
                            trailing: Text(_dayLabel(q.createdAt), style: ts(13, FontWeight.w400, AppColors.muted)),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _scrollToEnd();
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day ? 'Today' : fmtShortDate(d);
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.data.summary;
    final score = summary.healthScore.latest;
    final quick = widget.data.content.quickQuestions;
    final defaults = quick.where((q) => q.isDefault).toList();
    final more = quick.where((q) => !q.isDefault).toList();
    final conversation = [...widget.data.history, ..._messages];

    return Column(
      children: [
        Expanded(
          child: AppRefresh(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                        OutlineChipButton(
                          label: 'History',
                          icon: Icons.history_rounded,
                          onTap: () => _showHistory(conversation),
                        ),
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
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    spacing: 2,
                                    children: [
                                      Text('Hi ${summary.user.name}!', style: ts(15, FontWeight.w700)),
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
                                  score == null ? '–' : '${score.round()} /100',
                                  AppColors.greenDark,
                                ),
                                _GlanceRow(
                                  Icons.sentiment_satisfied_alt_rounded,
                                  AppColors.purple,
                                  'Stress Level',
                                  summary.stressLevel ?? '–',
                                  AppColors.purpleDark,
                                ),
                                _GlanceRow(
                                  Icons.directions_run_rounded,
                                  AppColors.blue,
                                  'Activity',
                                  summary.activityLevel ?? '–',
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
                          for (final q in defaults)
                            AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              radius: 14,
                              borderColor: AppColors.borderStrong,
                              onTap: () => _send(question: q),
                              label: _questionText(q),
                              child: Row(
                                spacing: 8,
                                children: [
                                  Icon(_topicStyle(q.topic).$1, color: _topicStyle(q.topic).$2, size: 22),
                                  Expanded(child: Text(_questionText(q), style: ts(13, FontWeight.w600), maxLines: 2)),
                                ],
                              ),
                            ),
                        ]),
                        if (more.isNotEmpty)
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: more.length,
                              separatorBuilder: (context, i) => const SizedBox(width: 8),
                              itemBuilder: (context, i) => PressScale(
                                label: _questionText(more[i]),
                                onTap: () => _send(question: more[i]),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(color: AppColors.borderStrong),
                                  ),
                                  child: Text(_questionText(more[i]), style: ts(13, FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                        Text(
                          'Health Buddy gives lifestyle tips, not medical advice.',
                          style: ts(12, FontWeight.w400, AppColors.muted),
                        ),
                      ],
                    ),
                  ),

                  // Conversation
                  for (final m in conversation)
                    FadeUp(
                      key: ObjectKey(m),
                      offset: m.fromUser ? const Offset(24, 0) : const Offset(0, 12),
                      duration: Duration(milliseconds: m.fromUser ? 200 : 260),
                      child: m.fromUser
                          ? _Bubble.user(m.text, time: fmtTime(m.createdAt))
                          : m.reply != null
                          ? _ReplyBubble(reply: m.reply!, time: fmtTime(m.createdAt))
                          : _Bubble.bot(m.text),
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
                    maxLength: 500,
                    onSubmitted: (v) => _send(text: v),
                    style: ts(15),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Type your message…',
                      hintStyle: ts(15, FontWeight.w400, AppColors.muted),
                    ).copyWith(counterText: ''),
                  ),
                ),
                PressScale(
                  label: 'Send',
                  onTap: () => _send(text: _input.text),
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

/// A structured coach answer: intro, data points with topic icons, recommendations and a referral.
class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({required this.reply, required this.time});

  final CoachReply reply;
  final String time;

  @override
  Widget build(BuildContext context) {
    Widget row(Widget icon, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: icon),
        Expanded(child: Text(text, style: ts(14).copyWith(height: 1.4))),
      ],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.88),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: reply.kind == 'restricted' ? AppColors.purpleCard : Colors.white,
          border: Border.all(color: reply.kind == 'restricted' ? AppColors.purpleBorder : AppColors.border),
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
            Text(reply.text, style: ts(14).copyWith(height: 1.45)),
            for (final p in reply.points)
              row(Icon(_topicStyle(p.topic).$1, color: _topicStyle(p.topic).$2, size: 19), p.text),
            if (reply.recommendations.isNotEmpty) ...[
              const Divider(height: 12, color: AppColors.track),
              Text(reply.recommendationsTitle ?? '', style: ts(14, FontWeight.w700, AppColors.greenDark)),
              for (final r in reply.recommendations)
                row(const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 19), r),
            ],
            if (reply.referral != null && reply.referral!.isNotEmpty)
              row(const Icon(Icons.support_agent_rounded, color: AppColors.purpleDark, size: 19), reply.referral!),
            Align(
              alignment: Alignment.centerRight,
              child: Text(time, style: ts(11, FontWeight.w400, AppColors.muted)),
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
