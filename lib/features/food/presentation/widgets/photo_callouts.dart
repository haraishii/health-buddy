import 'package:flutter/material.dart';

import '../../../../data/api/api_models.dart';
import '../../../../theme.dart';
import '../../../../widgets/format.dart';

/// Where one callout goes on the photo. [labelY] is 0..1 of the photo height; [anchor] is 0..1 of its width
/// and height. [index] is the item's position in the list, so its number is index + 1.
class CalloutSpec {
  const CalloutSpec({
    required this.index,
    required this.left,
    required this.labelY,
    required this.anchor,
    required this.showLabel,
  });

  final int index;
  final bool left;
  final double labelY;
  final Offset anchor;

  /// False on a crowded side: only the numbered dot is drawn and the name stays in the list.
  final bool showLabel;
}

/// Foods in the left half get labels on the left edge, the rest on the right, spread top to bottom in the
/// order of the foods. Items without a box get no callout.
List<CalloutSpec> layoutCallouts(List<PhotoBox?> boxes, {int maxLabelsPerSide = 4}) {
  final anchors = <(int, Offset)>[
    for (var i = 0; i < boxes.length; i++)
      if (boxes[i] case final b?) (i, Offset((b.xMin + b.xMax) / 2000, (b.yMin + b.yMax) / 2000)),
  ];
  final specs = <CalloutSpec>[];
  for (final left in [true, false]) {
    final side = anchors.where((a) => (a.$2.dx < 0.5) == left).toList()..sort((a, b) => a.$2.dy.compareTo(b.$2.dy));
    final crowded = side.length > maxLabelsPerSide;
    for (var k = 0; k < side.length; k++) {
      specs.add(
        CalloutSpec(
          index: side[k].$1,
          left: left,
          labelY: (k + 1) / (side.length + 1),
          anchor: side[k].$2,
          showLabel: !crowded,
        ),
      );
    }
  }
  return specs;
}

/// A green circle with the item's number, used on the photo and in the list.
class PhotoNumberDot extends StatelessWidget {
  const PhotoNumberDot(this.number, {super.key, this.size = 18});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text('$number', style: ts(size * 0.5, FontWeight.w800, Colors.white)),
    );
  }
}

/// Arrows from labels at the photo's edges to each food. Put it over the photo in a Stack of the photo's size.
class PhotoCallouts extends StatelessWidget {
  const PhotoCallouts({super.key, required this.items});

  final List<PhotoItem> items;

  @override
  Widget build(BuildContext context) {
    final specs = layoutCallouts([for (final i in items) i.box]);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _CalloutPainter(specs))),
            for (final s in specs)
              if (s.showLabel)
                Positioned(
                  left: s.left ? 6 : null,
                  right: s.left ? null : 6,
                  top: s.labelY * h - 11,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w * 0.45),
                    child: _Pill(number: s.index + 1, item: items[s.index]),
                  ),
                )
              else
                Positioned(
                  left: s.anchor.dx * w - 10,
                  top: s.anchor.dy * h - 10,
                  child: PhotoNumberDot(s.index + 1, size: 20),
                ),
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.number, required this.item});

  final int number;
  final PhotoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.only(left: 2, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          PhotoNumberDot(number),
          Flexible(
            child: Text(
              '${item.name} · ${fmtNum(item.grams)} g',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(11, FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalloutPainter extends CustomPainter {
  _CalloutPainter(this.specs);

  final List<CalloutSpec> specs;

  @override
  void paint(Canvas canvas, Size size) {
    final halo = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = AppColors.green
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (final s in specs.where((s) => s.showLabel)) {
      final from = Offset((s.left ? 0.15 : 0.85) * size.width, s.labelY * size.height);
      final to = Offset(s.anchor.dx * size.width, s.anchor.dy * size.height);
      canvas
        ..drawLine(from, to, halo)
        ..drawLine(from, to, line)
        ..drawCircle(to, 8.5, Paint()..color = Colors.white)
        ..drawCircle(to, 6, Paint()..color = AppColors.green);
    }
  }

  @override
  bool shouldRepaint(_CalloutPainter old) => old.specs != specs;
}
