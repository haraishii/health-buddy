import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/animated.dart';
import '../widgets/common.dart';

enum _ScanPhase { idle, analyzing, done }

class ScanMealScreen extends StatefulWidget {
  const ScanMealScreen({super.key});

  @override
  State<ScanMealScreen> createState() => _ScanMealScreenState();
}

class _ScanMealScreenState extends State<ScanMealScreen> {
  int _mode = 0; // 0 Photo, 1 Barcode, 2 Search
  _ScanPhase _phase = _ScanPhase.idle;
  Timer? _timer;

  static const _popular = [
    ('Nasi goreng', '1 plate · 520 kcal'),
    ('Chicken rice bowl', '1 bowl · 640 kcal'),
    ('Gado-gado', '1 plate · 410 kcal'),
    ('Banana', '1 medium · 105 kcal'),
    ('Greek yogurt', '150 g · 140 kcal'),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _capture() {
    if (_phase != _ScanPhase.idle) return;
    setState(() => _phase = _ScanPhase.analyzing);
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _phase = _ScanPhase.done);
      _showResult();
    });
  }

  void _addAndClose(String message) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(toastBar(message));
  }

  Future<void> _showResult() async {
    final add = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mode == 1 ? 'Barcode found' : 'Detected',
                          style: ts(13, FontWeight.w400, AppColors.muted),
                        ),
                        Text('Chicken rice bowl', style: ts(20, FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Pill('92% match'),
                ],
              ),
              const Row(
                spacing: 8,
                children: [
                  Expanded(child: _MacroTile('640', 'kcal', AppColors.orangeSoft)),
                  Expanded(child: _MacroTile('28 g', 'Protein', AppColors.greenSoft)),
                  Expanded(child: _MacroTile('82 g', 'Carbs', AppColors.blueSoft)),
                  Expanded(child: _MacroTile('18 g', 'Fat', AppColors.purpleSoft)),
                ],
              ),
              Column(
                children: [
                  for (final item in const [
                    ('White rice · 1 cup', '240 kcal'),
                    ('Grilled chicken · 100 g', '280 kcal'),
                    ('Mixed vegetables', '120 kcal'),
                  ])
                    Container(
                      height: 42,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.divider)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.$1, style: ts(14)),
                          Text(item.$2, style: ts(14, FontWeight.w400, AppColors.muted)),
                        ],
                      ),
                    ),
                ],
              ),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: PressScale(
                      label: 'Edit',
                      onTap: () => Navigator.of(sheetContext).pop(false),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderStrong),
                        ),
                        child: Text('Edit', style: ts(15, FontWeight.w600)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: 'Add to Lunch',
                      height: 52,
                      onTap: () => Navigator.of(sheetContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (add == true) {
      _addAndClose('Added to Lunch · 640 kcal');
    } else {
      setState(() => _phase = _ScanPhase.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    const hints = ['Point the camera at your plate', 'Line up the barcode on the package'];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              const BackHeader('Scan Meal'),
              Segmented(
                options: const ['Photo', 'Barcode', 'Search'],
                index: _mode,
                onChanged: (i) => setState(() {
                  _mode = i;
                  _phase = _ScanPhase.idle;
                  _timer?.cancel();
                }),
              ),
              if (_mode < 2) ...[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: AppColors.dark,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Motion.standard,
                              width: 210,
                              height: _mode == 0 ? 210 : 110,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.darkSoft,
                                borderRadius: BorderRadius.circular(_mode == 0 ? 105 : 16),
                              ),
                              child: Text(
                                hints[_mode],
                                textAlign: TextAlign.center,
                                style: ts(13, FontWeight.w400, const Color(0xFFB4BAC4)),
                              ),
                            ),
                          ),
                          const Center(
                            child: SizedBox(width: 280, height: 280, child: CustomPaint(painter: _CornersPainter())),
                          ),
                          if (_phase != _ScanPhase.done) const ScanLine(),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 16,
                            child: Text(
                              _phase == _ScanPhase.analyzing ? 'Analyzing your meal…' : 'Hold steady',
                              textAlign: TextAlign.center,
                              style: ts(13, FontWeight.w500, const Color(0xFFE5E7EB)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: PressScale(
                    label: 'Capture',
                    scale: 0.93,
                    onTap: _capture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCDEFD7), width: 5),
                      ),
                      child: _phase == _ScanPhase.analyzing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : Icon(
                              _mode == 0 ? Icons.photo_camera_outlined : Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                    ),
                  ),
                ),
                Text(
                  'Tap to capture. Results can always be edited.',
                  textAlign: TextAlign.center,
                  style: ts(13, FontWeight.w400, AppColors.muted),
                ),
              ] else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      TextField(
                        autofocus: true,
                        style: ts(15),
                        decoration: InputDecoration(
                          hintText: 'Search food, e.g. nasi goreng',
                          hintStyle: ts(15, FontWeight.w400, AppColors.muted),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.borderStrong),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                          ),
                        ),
                      ),
                      Text('Popular', style: ts(14, FontWeight.w700, AppColors.muted)),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _popular.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 8),
                          itemBuilder: (context, i) => FadeUp(
                            delayMs: i * 50,
                            child: AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              radius: 14,
                              onTap: () => _addAndClose('${_popular[i].$1} added'),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_popular[i].$1, style: ts(15, FontWeight.w600)),
                                        Text(_popular[i].$2, style: ts(12, FontWeight.w400, AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.add_circle_rounded, color: AppColors.green, size: 28),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile(this.value, this.label, this.bg);

  final String value;
  final String label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: ts(16, FontWeight.w700)),
          Text(label, style: ts(11, FontWeight.w400, AppColors.muted)),
        ],
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const l = 40.0;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, l)
      ..lineTo(0, 0)
      ..lineTo(l, 0)
      ..moveTo(w - l, 0)
      ..lineTo(w, 0)
      ..lineTo(w, l)
      ..moveTo(w, h - l)
      ..lineTo(w, h)
      ..lineTo(w - l, h)
      ..moveTo(l, h)
      ..lineTo(0, h)
      ..lineTo(0, h - l);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CornersPainter old) => false;
}
