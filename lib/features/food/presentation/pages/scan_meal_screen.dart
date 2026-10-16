import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_models.dart';
import '../../../../data/api/session.dart';
import '../../../../theme.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/format.dart';
import '../../../../widgets/skeleton.dart';

/// A food (Package 1) or packaged product (Package 2), per serving, ready to log.
class _Item {
  const _Item({
    required this.name,
    required this.serving,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.labels,
    this.foodId,
    this.barcode,
  });

  factory _Item.food(Food f) => _Item(
    name: f.name,
    serving: f.serving,
    kcal: f.caloriesKcal,
    protein: f.proteinG,
    carbs: f.carbsG,
    fat: f.fatG,
    labels: f.labels,
    foodId: f.id,
  );

  factory _Item.product(Product p) => _Item(
    name: '${p.brand} ${p.productName}${p.variant == null ? '' : ' · ${p.variant}'}',
    serving: '${fmtNum(p.servingSize)} ${p.servingUnit}',
    kcal: p.caloriesKcal,
    protein: p.proteinG,
    carbs: p.carbsG,
    fat: p.fatG,
    labels: p.labels,
    barcode: p.barcode,
  );

  final String name;
  final String serving;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> labels;
  final String? foodId;
  final String? barcode;
}

const _mealTimes = [('breakfast', 'Breakfast'), ('lunch', 'Lunch'), ('dinner', 'Dinner'), ('snack', 'Snack')];

/// Breakfast before 10, lunch before 15, snack before 18, then dinner (until 22).
String _mealTimeNow() {
  final h = DateTime.now().hour;
  if (h < 10) return 'breakfast';
  if (h < 15) return 'lunch';
  if (h < 18) return 'snack';
  if (h < 22) return 'dinner';
  return 'snack';
}

class ScanMealScreen extends StatefulWidget {
  const ScanMealScreen({super.key, this.mealTime});

  /// breakfast, lunch, dinner or snack; preselected in the add sheet.
  final String? mealTime;

  @override
  State<ScanMealScreen> createState() => _ScanMealScreenState();
}

class _ScanMealScreenState extends State<ScanMealScreen> {
  int _mode = 2; // 0 Photo, 1 Barcode, 2 Search
  final _search = TextEditingController();
  final _barcode = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _lookingUp = false;
  String? _barcodeError;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _barcode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  Future<void> _lookUpBarcode() async {
    final code = _barcode.text.trim();
    if (!RegExp(r'^(\d{8}|\d{12,14})$').hasMatch(code)) {
      setState(() => _barcodeError = 'Enter the 8 or 13 digits under the barcode');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _lookingUp = true;
      _barcodeError = null;
    });
    try {
      final product = await SessionScope.of(context).api.product(code);
      if (mounted) await _showAddSheet(_Item.product(product));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _barcodeError = e.statusCode == 404 ? "We don't have this product yet." : e.message);
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _showAddSheet(_Item item) async {
    final added = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) => _AddSheet(item: item, mealTime: widget.mealTime ?? _mealTimeNow()),
    );
    if (added == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(toastBar(added));
  }

  Widget _darkPanel({required double frameHeight, required String title, required String body}) {
    return ClipRRect(
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
                width: 230,
                height: frameHeight,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSoft,
                  borderRadius: BorderRadius.circular(frameHeight > 150 ? 115 : 16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Text(title, textAlign: TextAlign.center, style: ts(14, FontWeight.w700, const Color(0xFFE5E7EB))),
                    Text(body, textAlign: TextAlign.center, style: ts(12.5, FontWeight.w400, const Color(0xFFB4BAC4))),
                  ],
                ),
              ),
            ),
            const Center(
              child: SizedBox(width: 280, height: 280, child: CustomPaint(painter: _CornersPainter())),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: ts(15, FontWeight.w400, AppColors.muted),
    prefixIcon: Icon(icon, color: AppColors.muted),
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
  );

  @override
  Widget build(BuildContext context) {
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
                onChanged: (i) => setState(() => _mode = i),
              ),
              if (_mode == 0) ...[
                Expanded(
                  child: _darkPanel(
                    frameHeight: 210,
                    title: 'Photo recognition is coming soon',
                    body: 'For now, search the food or type the barcode number.',
                  ),
                ),
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: OutlineChipButton(
                        label: 'Enter barcode',
                        icon: Icons.qr_code_scanner_rounded,
                        onTap: () => setState(() => _mode = 1),
                      ),
                    ),
                    Expanded(
                      child: OutlineChipButton(
                        label: 'Search food',
                        icon: Icons.search_rounded,
                        onTap: () => setState(() => _mode = 2),
                      ),
                    ),
                  ],
                ),
              ] else if (_mode == 1) ...[
                Expanded(
                  child: _darkPanel(
                    frameHeight: 120,
                    title: 'Type the barcode number',
                    body: 'Camera scanning is coming soon. Use the digits printed under the barcode.',
                  ),
                ),
                TextField(
                  controller: _barcode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
                  onSubmitted: (_) => _lookUpBarcode(),
                  style: ts(17, FontWeight.w600).copyWith(letterSpacing: 1.5),
                  decoration: _inputDecoration(
                    'e.g. 8991234567890',
                    Icons.qr_code_2_rounded,
                  ).copyWith(errorText: _barcodeError),
                ),
                _lookingUp
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
                    : PrimaryButton(label: 'Look up product', onTap: _lookUpBarcode),
              ] else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      TextField(
                        controller: _search,
                        autofocus: true,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: ts(15),
                        decoration: _inputDecoration('Search food, e.g. nasi goreng', Icons.search_rounded),
                      ),
                      Text(_query.isEmpty ? 'Popular' : 'Results', style: ts(14, FontWeight.w700, AppColors.muted)),
                      Expanded(
                        child: ApiBuilder<List<Food>>(
                          cacheKey: 'foods:${_query.toLowerCase()}',
                          load: (api) => api.searchFoods(query: _query, popular: _query.isEmpty, limit: 30),
                          loading: Shimmer(
                            child: Column(
                              spacing: 8,
                              children: [
                                for (var i = 0; i < 5; i++)
                                  const SkeletonBox(width: double.infinity, height: 62, radius: 14),
                              ],
                            ),
                          ),
                          builder: (context, foods) => foods.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Text(
                                    'No food found for "$_query". Try another name.',
                                    textAlign: TextAlign.center,
                                    style: ts(14, FontWeight.w400, AppColors.muted),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: foods.length,
                                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                                  itemBuilder: (context, i) => FadeUp(
                                    delayMs: i < 8 ? i * 40 : 0,
                                    child: AppCard(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      radius: 14,
                                      label: 'Add ${foods[i].name}',
                                      onTap: () => _showAddSheet(_Item.food(foods[i])),
                                      child: Row(
                                        spacing: 8,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(foods[i].name, style: ts(15, FontWeight.w600)),
                                                Text(
                                                  '${foods[i].serving} · ${fmtNum(foods[i].caloriesKcal)} kcal',
                                                  style: ts(12, FontWeight.w400, AppColors.muted),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (foods[i].labels.contains('Healthy')) const Pill('Healthy', size: 11),
                                          const Icon(Icons.add_circle_rounded, color: AppColors.green, size: 28),
                                        ],
                                      ),
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

/// Servings, meal time and the nutrients for that amount; returns the toast text after saving.
class _AddSheet extends StatefulWidget {
  const _AddSheet({required this.item, required this.mealTime});

  final _Item item;
  final String mealTime;

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  late int _meal = _mealTimes.indexWhere((t) => t.$1 == widget.mealTime).clamp(0, 3);
  double _servings = 1;
  bool _saving = false;

  Future<void> _add() async {
    setState(() => _saving = true);
    final item = widget.item;
    final meal = _mealTimes[_meal];
    final ok = await saveWithFeedback(
      context,
      (api) => api.addMeal(mealTime: meal.$1, foodId: item.foodId, barcode: item.barcode, servings: _servings),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop('Added to ${meal.$2} · ${fmtNum(item.kcal * _servings)} kcal');
    } else {
      setState(() => _saving = false);
    }
  }

  Widget _stepper(IconData icon, String label, VoidCallback? onTap) => PressScale(
    label: label,
    scale: 0.92,
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Icon(icon, color: onTap == null ? AppColors.muted : AppColors.text),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final n = _servings;
    return SafeArea(
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
                        item.barcode != null ? 'Barcode found' : '1 serving = ${item.serving}',
                        style: ts(13, FontWeight.w400, AppColors.muted),
                      ),
                      Text(item.name, style: ts(20, FontWeight.w700)),
                    ],
                  ),
                ),
                for (final l in item.labels.take(2))
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Pill(
                      l,
                      size: 11,
                      color: l.startsWith('High') && l != 'High protein' ? AppColors.orangeText : AppColors.greenDark,
                      bg: l.startsWith('High') && l != 'High protein' ? AppColors.orangeSoft : AppColors.greenSoft,
                    ),
                  ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(child: _MacroTile(fmtNum(item.kcal * n), 'kcal', AppColors.orangeSoft)),
                Expanded(child: _MacroTile('${fmtNum(item.protein * n)} g', 'Protein', AppColors.greenSoft)),
                Expanded(child: _MacroTile('${fmtNum(item.carbs * n)} g', 'Carbs', AppColors.blueSoft)),
                Expanded(child: _MacroTile('${fmtNum(item.fat * n)} g', 'Fat', AppColors.purpleSoft)),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Servings', style: ts(15, FontWeight.w600))),
                _stepper(
                  Icons.remove_rounded,
                  'Fewer servings',
                  n > 0.5 ? () => setState(() => _servings -= 0.5) : null,
                ),
                SizedBox(
                  width: 64,
                  child: Text(fmtNum(n, decimals: 1), textAlign: TextAlign.center, style: ts(20, FontWeight.w800)),
                ),
                _stepper(Icons.add_rounded, 'More servings', n < 10 ? () => setState(() => _servings += 0.5) : null),
              ],
            ),
            Segmented(
              options: [for (final t in _mealTimes) t.$2],
              index: _meal,
              onChanged: (i) => setState(() => _meal = i),
            ),
            _saving
                ? Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.greenDark, borderRadius: BorderRadius.circular(16)),
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    ),
                  )
                : PrimaryButton(label: 'Add to ${_mealTimes[_meal].$2}', height: 52, onTap: _add),
          ],
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
