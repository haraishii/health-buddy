import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

void _drawLabel(Canvas canvas, String text, Offset anchor, TextStyle style, {TextAlign align = TextAlign.center}) {
  final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
  final dx = switch (align) {
    TextAlign.right || TextAlign.end => anchor.dx - tp.width,
    TextAlign.left || TextAlign.start => anchor.dx,
    _ => anchor.dx - tp.width / 2,
  };
  tp.paint(canvas, Offset(dx, anchor.dy - tp.height / 2));
}

/* ───────────────────────── Score ring ───────────────────────── */

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.track,
    required this.center,
    this.size = 112,
    this.stroke = 10,
    this.delayMs = 150,
  });

  final double fraction;
  final Color color;
  final Color track;
  final Widget Function(double t) center;
  final double size;
  final double stroke;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      delayMs: delayMs,
      builder: (context, t) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(fraction * t, color, track, stroke),
          child: Center(child: center(t)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.stroke);

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (value <= 0) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/* ───────────────────────── Line chart ───────────────────────── */

class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.values,
    required this.labels,
    required this.maxY,
    required this.color,
    this.height = 150,
    this.yTicks = const [],
    this.showYLabels = false,
    this.delayMs = 300,
  });

  final List<double> values;
  final List<String> labels;
  final double maxY;
  final Color color;
  final double height;
  final List<double> yTicks;
  final bool showYLabels;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    return Semantics(
      label: 'Line chart: ${[for (var i = 0; i < values.length; i++) '${labels[i]} ${values[i].round()}'].join(', ')}',
      child: Reveal(
        delayMs: delayMs,
        curve: Curves.easeOutCubic,
        builder: (context, t) => SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(values, labels, maxY, color, yTicks, showYLabels, t, base),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.labels, this.maxY, this.color, this.yTicks, this.showYLabels, this.t, this.base);

  final List<double> values;
  final List<String> labels;
  final double maxY;
  final Color color;
  final List<double> yTicks;
  final bool showYLabels;
  final double t;
  final TextStyle base;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(showYLabels ? 26 : 4, 20, size.width - 4, size.height - 22);
    final grid = Paint()
      ..color = AppColors.track
      ..strokeWidth = 1;
    final small = base.copyWith(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w400, height: 1);

    for (final tick in yTicks) {
      final y = chart.bottom - tick / maxY * chart.height;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
      if (showYLabels) _drawLabel(canvas, tick.round().toString(), Offset(chart.left - 6, y), small, align: TextAlign.right);
    }

    final n = values.length;
    final inset = 10.0;
    final step = (chart.width - inset * 2) / (n - 1);
    final pts = [
      for (var i = 0; i < n; i++) Offset(chart.left + inset + step * i, chart.bottom - values[i] / maxY * chart.height),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    // Soft area fill, fades in last.
    final areaT = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
    if (areaT > 0) {
      final area = Path.from(line)
        ..lineTo(pts.last.dx, chart.bottom)
        ..lineTo(pts.first.dx, chart.bottom)
        ..close();
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.09 * areaT));
    }

    // Line draws in.
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    for (final m in line.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t), stroke);
    }

    // Dots pop in one by one + value labels.
    final dot = Paint()..color = color;
    final valueStyle = base.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.text, height: 1);
    for (var i = 0; i < n; i++) {
      final threshold = n == 1 ? 0.0 : i / (n - 1) * 0.9;
      final local = ((t - threshold) / 0.1).clamp(0.0, 1.0);
      if (local > 0) {
        canvas.drawCircle(pts[i], 4 * local, dot);
        _drawLabel(
          canvas,
          values[i].round().toString(),
          pts[i] - const Offset(0, 12),
          valueStyle.copyWith(color: AppColors.text.withValues(alpha: local)),
        );
      }
      _drawLabel(canvas, labels[i], Offset(pts[i].dx, size.height - 8), small.copyWith(fontSize: 10.5));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.t != t || old.values != values;
}

/* ───────────────────────── Bar chart ───────────────────────── */

class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.maxY,
    required this.color,
    this.height = 104,
    this.delayMs = 400,
  });

  final List<double> values;
  final List<String> labels;
  final double maxY;
  final Color color;
  final double height;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    return Semantics(
      label: 'Bar chart: ${[for (var i = 0; i < values.length; i++) '${labels[i]} ${values[i]}'].join(', ')}',
      child: Reveal(
        delayMs: delayMs,
        duration: const Duration(milliseconds: 800),
        builder: (context, t) => SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _BarPainter(values, labels, maxY, color, t, base)),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.values, this.labels, this.maxY, this.color, this.t, this.base);

  final List<double> values;
  final List<String> labels;
  final double maxY;
  final Color color;
  final double t;
  final TextStyle base;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(2, 6, size.width - 2, size.height - 20);
    final grid = Paint()
      ..color = AppColors.track
      ..strokeWidth = 1;
    for (var k = 0; k <= 2; k++) {
      final y = chart.bottom - chart.height * k / 2;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
    final n = values.length;
    final slot = chart.width / n;
    final barW = math.min(14.0, slot * 0.55);
    const stagger = 0.06;
    final small = base.copyWith(fontSize: 10.5, color: AppColors.muted, height: 1);
    final paint = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final local = ((t - i * stagger) / (1 - (n - 1) * stagger)).clamp(0.0, 1.0);
      final h = values[i] / maxY * chart.height * local;
      final cx = chart.left + slot * (i + 0.5);
      if (h > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - barW / 2, chart.bottom - h, barW, h),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          paint,
        );
      }
      _drawLabel(canvas, labels[i], Offset(cx, size.height - 7), small);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.t != t;
}

/* ───────────────────────── Radar (Balance) ───────────────────────── */

class RadarChart extends StatelessWidget {
  /// Order: top, right, bottom, left.
  const RadarChart({super.key, required this.names, required this.values, this.delayMs = 400});

  final List<String> names;
  final List<double> values;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    return Semantics(
      label: [for (var i = 0; i < names.length; i++) '${names[i]} ${values[i].round()}'].join(', '),
      child: AspectRatio(
        aspectRatio: 1,
        child: Reveal(
          delayMs: delayMs,
          duration: const Duration(milliseconds: 500),
          builder: (context, t) => CustomPaint(painter: _RadarPainter(names, values, t, base)),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.names, this.values, this.t, this.base);

  final List<String> names;
  final List<double> values;
  final double t;
  final TextStyle base;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 200;
    canvas.save();
    canvas.scale(s);
    const c = Offset(100, 100);
    const r = 55.0;
    const dirs = [Offset(0, -1), Offset(1, 0), Offset(0, 1), Offset(-1, 0)];

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.borderStrong
      ..strokeWidth = 1 / s;
    for (final f in [1.0, 0.66, 0.33]) {
      final path = Path()..addPolygon([for (final d in dirs) c + d * r * f], true);
      canvas.drawPath(path, gridPaint);
    }
    canvas.drawLine(c + dirs[0] * r, c + dirs[2] * r, gridPaint);
    canvas.drawLine(c + dirs[3] * r, c + dirs[1] * r, gridPaint);

    final scale = 0.6 + 0.4 * t;
    final pts = [for (var i = 0; i < 4; i++) c + dirs[i] * r * (values[i] / 100) * scale];
    final shape = Path()..addPolygon(pts, true);
    canvas.drawPath(shape, Paint()..color = AppColors.green.withValues(alpha: 0.18 * t));
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.green.withValues(alpha: t),
    );
    final dot = Paint()..color = AppColors.green.withValues(alpha: t);
    for (final p in pts) {
      canvas.drawCircle(p, 4, dot);
    }

    final nameStyle = base.copyWith(fontSize: 12, color: AppColors.muted, height: 1);
    final valStyle = base.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text, height: 1);
    const anchors = [Offset(100, 16), Offset(176, 92), Offset(100, 172), Offset(24, 92)];
    for (var i = 0; i < 4; i++) {
      _drawLabel(canvas, names[i], anchors[i], nameStyle);
      _drawLabel(canvas, values[i].round().toString(), anchors[i] + const Offset(0, 18), valStyle);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t;
}

/* ───────────────────────── Park illustration (AI Insights) ───────────────────────── */

class ParkScene extends StatelessWidget {
  const ParkScene({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(painter: _ParkPainter(), child: const SizedBox.expand()),
    );
  }
}

class _ParkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEFF7F1));
    canvas.drawCircle(Offset(w * 0.75, h * 0.24), w * 0.11, Paint()..color = const Color(0xFFFDE9B8));
    // Faint city buildings.
    final city = Paint()..color = const Color(0xFFD9E7F5);
    canvas.drawRect(Rect.fromLTWH(w * 0.12, h * 0.30, w * 0.12, h * 0.35), city);
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.20, w * 0.10, h * 0.45), city);
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.34, w * 0.14, h * 0.31), city);
    // Hills.
    canvas.drawOval(Rect.fromLTWH(-w * 0.3, h * 0.58, w * 1.0, h * 0.7), Paint()..color = const Color(0xFFBFE5C9));
    canvas.drawOval(Rect.fromLTWH(w * 0.3, h * 0.62, w * 1.0, h * 0.7), Paint()..color = const Color(0xFFA7DAB5));
    // Footpath.
    final path = Path()
      ..moveTo(w * 0.2, h)
      ..quadraticBezierTo(w * 0.55, h * 0.82, w * 0.62, h * 0.66)
      ..lineTo(w * 0.7, h * 0.66)
      ..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.5, h)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF4ECDD));
    // Trees.
    void tree(double x, double y, double r) {
      canvas.drawRect(Rect.fromLTWH(x - 1.5, y, 3, r * 1.4), Paint()..color = const Color(0xFF8B6B4A));
      canvas.drawCircle(Offset(x, y), r, Paint()..color = const Color(0xFF6CC283));
    }

    tree(w * 0.16, h * 0.58, w * 0.11);
    tree(w * 0.86, h * 0.55, w * 0.13);
  }

  @override
  bool shouldRepaint(_ParkPainter old) => false;
}
