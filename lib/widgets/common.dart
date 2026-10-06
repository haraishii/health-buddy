import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Active tab in the tab bar (0 Home, 1 Analytics, 2 AI Coach, 3 Food, 4 Profile).
final ValueNotifier<int> currentTab = ValueNotifier<int>(0);

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Format 1420 -> "1,420".
String fmtThousands(num value) {
  final s = value.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Runs a 0 -> 1 animation once (after a delay) and calls builder(t).
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.builder,
    this.duration = Motion.chart,
    this.delayMs = 0,
    this.curve = Motion.standard,
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;
  final int delayMs;
  final Curve curve;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final CurvedAnimation _a = CurvedAnimation(parent: _c, curve: widget.curve);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _c.value = 1;
    } else {
      _timer = Timer(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _a, builder: (context, _) => widget.builder(context, _a.value));
  }
}

/// Enters with fade + slide (default: up 12 px, 320 ms).
class FadeUp extends StatelessWidget {
  const FadeUp({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offset = const Offset(0, 12),
    this.duration = Motion.enter,
  });

  final Widget child;
  final int delayMs;
  final Offset offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      duration: duration,
      delayMs: delayMs,
      builder: (context, t) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: offset * (1 - t), child: child),
      ),
    );
  }
}

/// Press effect: scale 0.97 for 100 ms.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap, this.label, this.scale = 0.97});

  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: _down ? widget.scale : 1, duration: Motion.fast, child: widget.child),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.card,
    this.borderColor = AppColors.border,
    this.radius = 18,
    this.onTap,
    this.label,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return PressScale(onTap: onTap, label: label, child: card);
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    required this.color,
    required this.bg,
    this.size = 36,
    this.iconSize = 20,
    this.radius = 10,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = AppColors.greenDark, this.bg = AppColors.greenSoft, this.size = 12});

  final String text;
  final Color color;
  final Color bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: ts(size, FontWeight.w700, color)),
    );
  }
}

/// Progress bar that fills 0 -> value (600 ms) and animates when the value changes.
class ProgressBar extends StatefulWidget {
  const ProgressBar({super.key, required this.value, required this.color, this.height = 8, this.delayMs = 300});

  final double value;
  final Color color;
  final double height;
  final int delayMs;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  double _shown = 0;
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        setState(() {
          _ready = true;
          _shown = widget.value;
        });
      }
    });
  }

  @override
  void didUpdateWidget(ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready) _shown = widget.value;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(99);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _shown),
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 600),
      curve: Motion.standard,
      builder: (context, v, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(color: AppColors.track, borderRadius: r),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v.clamp(0.0, 1.0),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(color: widget.color, borderRadius: r),
          ),
        ),
      ),
    );
  }
}

/// Square 44 x 44 icon button (notifications, back, etc.).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({super.key, required this.icon, required this.label, this.onTap, this.size = 44});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      label: label,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Icon(icon, size: 20, color: AppColors.text),
      ),
    );
  }
}

/// Outlined button with icon + label (History, date, Search).
class OutlineChipButton extends StatelessWidget {
  const OutlineChipButton({super.key, required this.label, this.icon, this.trailing, this.onTap});

  final String label;
  final IconData? icon;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            if (icon != null) Icon(icon, size: 17, color: AppColors.text),
            Text(label, style: ts(13.5, FontWeight.w600)),
            if (trailing != null) Icon(trailing, size: 18, color: AppColors.text),
          ],
        ),
      ),
    );
  }
}

/// Segmented control (Photo / Barcode / Search, Light / Moderate / Hard).
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.options, required this.index, required this.onChanged});

  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(14)),
      child: Row(
        spacing: 4,
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? AppColors.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: i == index
                          ? const [BoxShadow(color: Color(0x1F111827), blurRadius: 3, offset: Offset(0, 1))]
                          : const [],
                    ),
                    child: Text(
                      options[i],
                      style: ts(
                        14,
                        i == index ? FontWeight.w700 : FontWeight.w500,
                        i == index ? AppColors.text : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Green toggle switch (200 ms).
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Motion.standard,
          width: 52,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AppColors.green : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(99),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Motion.standard,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width green primary button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.green,
    this.height = 54,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: ts(16, FontWeight.w700, Colors.white)),
      ),
    );
  }
}

/// Header for pushed screens: back button + title.
class BackHeader extends StatelessWidget {
  const BackHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        SquareIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          label: 'Back',
          onTap: () => Navigator.of(context).maybePop(),
        ),
        Text(title, style: ts(22, FontWeight.w800)),
      ],
    );
  }
}

/// Two equal-width columns, row by row.
Widget twoColumns(List<Widget> items, {double gap = 10}) {
  final rows = <Widget>[];
  for (var i = 0; i < items.length; i += 2) {
    rows.add(
      Row(
        spacing: gap,
        children: [
          Expanded(child: items[i]),
          Expanded(child: i + 1 < items.length ? items[i + 1] : const SizedBox()),
        ],
      ),
    );
  }
  return Column(spacing: gap, children: rows);
}

/// Push transition from the right (300 ms).
Route<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: Motion.push,
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final a = CurvedAnimation(parent: animation, curve: Motion.standard, reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(a),
        child: child,
      );
    },
  );
}

/// Dark toast with a check icon (slides up 250 ms, hides after 2.4 s).
void showToast(BuildContext context, String message, {IconData icon = Icons.check_circle_rounded}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(toastBar(message, icon: icon));
}

SnackBar toastBar(String message, {IconData icon = Icons.check_circle_rounded}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.text,
    duration: const Duration(milliseconds: 2400),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    content: Row(
      spacing: 10,
      children: [
        Icon(icon, color: AppColors.greenGlow, size: 20),
        Expanded(child: Text(message, style: ts(14, FontWeight.w500, Colors.white))),
      ],
    ),
  );
}
