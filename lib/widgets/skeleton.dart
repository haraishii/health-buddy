import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// A soft light sweep over grey placeholder shapes while data loads (1.2 s loop).
/// Static when the user turned on "reduce motion".
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _c,
        child: ExcludeSemantics(child: widget.child),
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: const [AppColors.track, Color(0xFFF8F9FB), AppColors.track],
            stops: const [0.35, 0.5, 0.65],
            begin: const Alignment(-1, -0.3),
            end: const Alignment(1, 0.3),
            transform: _SlideGradient(_c.value),
          ).createShader(bounds),
          child: child,
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

/// Grey rounded placeholder. Put several inside a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8, this.circle = false});

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.track,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// A card-shaped skeleton: a title bar and [lines] text bars, optionally with a ring on the left.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 3, this.ring = false, this.height});

  final int lines;
  final bool ring;

  /// Fixed height for chart cards.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        const SkeletonBox(width: 120, height: 16),
        for (var i = 0; i < lines; i++) SkeletonBox(width: i.isEven ? double.infinity : 180, height: 12),
      ],
    );
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ring
          ? Row(
              spacing: 18,
              children: [
                const SkeletonBox(height: 112, circle: true),
                Expanded(child: text),
              ],
            )
          : text,
    );
  }
}

/// Page header placeholder (big title + subtitle) used by the tab screens.
class SkeletonHeader extends StatelessWidget {
  const SkeletonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [SkeletonBox(width: 90, height: 12), SkeletonBox(width: 170, height: 26, radius: 10)],
    );
  }
}

/// Standard loading layout for a scrolling tab: header, then the given cards.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({super.key, required this.children, this.header = true});

  final List<Widget> children;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [if (header) const SkeletonHeader(), ...children],
        ),
      ),
    );
  }
}
