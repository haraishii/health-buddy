import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// A repeating controller (disabled when "reduce motion" is on).
mixin _LoopMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController loop = AnimationController(
    vsync: this,
    duration: loopDuration,
  );
  Duration get loopDuration;
  bool get autoStart => true;
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    if (autoStart && !reduceMotion(context)) loop.repeat();
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

/* ───────────── Robot mascot: floats every 3 s, blinks every 4 s ───────────── */

class RobotMascot extends StatefulWidget {
  const RobotMascot({super.key, this.width = 84});

  final double width;

  @override
  State<RobotMascot> createState() => _RobotMascotState();
}

class _RobotMascotState extends State<RobotMascot>
    with SingleTickerProviderStateMixin, _LoopMixin<RobotMascot> {
  // One 12 s cycle: 4 floats (3 s each) and 3 blinks (every 4 s).
  @override
  Duration get loopDuration => const Duration(seconds: 12);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          final v = loop.value;
          final floatY = -3 + 3 * math.cos(v * 4 * 2 * math.pi); // 0 .. -6 px
          final blinkPhase = (v * 3) % 1.0;
          final eyes = (blinkPhase > 0.92 && blinkPhase < 0.98) ? 0.12 : 1.0;
          return Transform.translate(
            offset: Offset(0, floatY),
            child: SizedBox(
              width: widget.width,
              height: widget.width * 96 / 84,
              child: CustomPaint(painter: _RobotPainter(eyes)),
            ),
          );
        },
      ),
    );
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter(this.eyeScale);

  final double eyeScale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 84);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.borderStrong;
    final white = Paint()..color = Colors.white;

    canvas.drawLine(
      const Offset(42, 6),
      const Offset(42, 18),
      Paint()
        ..color = const Color(0xFF9CA3AF)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(42, 6), 5, Paint()..color = AppColors.green);

    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 18, 68, 50),
      const Radius.circular(22),
    );
    canvas.drawRRect(head, white);
    canvas.drawRRect(head, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 27, 52, 30),
        const Radius.circular(15),
      ),
      Paint()..color = AppColors.dark,
    );

    final eye = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.greenGlow;
    for (final cx in [33.0, 51.0]) {
      canvas.save();
      canvas.translate(cx, 43);
      canvas.scale(1, eyeScale);
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(0, 3), radius: 6),
        math.pi,
        math.pi,
        false,
        eye,
      );
      canvas.restore();
    }

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(20, 70, 44, 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(body, white);
    canvas.drawRRect(body, outline);
    final heart = Path()
      ..moveTo(42, 89)
      ..cubicTo(38, 86.5, 35, 84, 35, 80.6)
      ..cubicTo(35, 78.4, 36.7, 77, 38.6, 77)
      ..cubicTo(40.1, 77, 41.3, 77.9, 42, 79.1)
      ..cubicTo(42.7, 77.9, 43.9, 77, 45.4, 77)
      ..cubicTo(47.3, 77, 49, 78.4, 49, 80.6)
      ..cubicTo(49, 84, 46, 86.5, 42, 89)
      ..close();
    canvas.drawPath(heart, Paint()..color = AppColors.green);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RobotPainter old) => old.eyeScale != eyeScale;
}

/* ───────────── "Typing" dots (1.2 s loop) ───────────── */

class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin, _LoopMixin<TypingDots> {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1200);

  double _bump(double p) {
    if (p < 0.4) return p / 0.4;
    if (p < 0.8) return (0.8 - p) / 0.4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Health Buddy is typing',
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(
                builder: (context) {
                  final b = _bump((loop.value - i * 0.125) % 1.0);
                  return Transform.translate(
                    offset: Offset(0, -3 * b),
                    child: Opacity(
                      opacity: 0.3 + 0.7 * b,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/* ───────────── Breathing circle: 4 s grow, 4 s shrink ───────────── */

class BreathingCircle extends StatefulWidget {
  const BreathingCircle({super.key, required this.running});

  final bool running;

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with SingleTickerProviderStateMixin, _LoopMixin<BreathingCircle> {
  @override
  Duration get loopDuration => const Duration(seconds: 8);

  @override
  bool get autoStart => false;

  @override
  void didUpdateWidget(BreathingCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running == oldWidget.running) return;
    if (widget.running) {
      loop.repeat();
    } else {
      loop.animateTo(0, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final v = loop.value;
        final grow = 0.5 - 0.5 * math.cos(v * 2 * math.pi);
        final label = !widget.running
            ? 'Ready'
            : (v < 0.5 ? 'Breathe in' : 'Breathe out');
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Center(
                child: Transform.scale(
                  scale: 1 + 0.35 * grow,
                  child: Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.purpleLight,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(label, style: ts(16, FontWeight.w700, AppColors.purpleDeep)),
          ],
        );
      },
    );
  }
}

/* ───────────── Camera scan line (1.6 s loop) ───────────── */

class ScanLine extends StatefulWidget {
  const ScanLine({super.key});

  @override
  State<ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<ScanLine>
    with SingleTickerProviderStateMixin, _LoopMixin<ScanLine> {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1600);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final y = 0.5 - 0.5 * math.cos(loop.value * 2 * math.pi);
        return Align(
          alignment: Alignment(0, -0.76 + 1.52 * y),
          child: FractionallySizedBox(
            widthFactor: 0.72,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                color: AppColors.greenGlow,
                boxShadow: [
                  BoxShadow(color: AppColors.greenGlow, blurRadius: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tab icon that bounces 1 → 1.15 → 1 (250 ms) when selected.
class BounceOnSelect extends StatefulWidget {
  const BounceOnSelect({
    super.key,
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  State<BounceOnSelect> createState() => _BounceOnSelectState();
}

class _BounceOnSelectState extends State<BounceOnSelect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void didUpdateWidget(BounceOnSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected && !reduceMotion(context))
      _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.15 * math.sin(_c.value * math.pi),
        child: child,
      ),
      child: widget.child,
    );
  }
}
