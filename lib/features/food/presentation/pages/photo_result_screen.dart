import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../data/api/api_models.dart';
import '../../../../theme.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/format.dart';
import '../../meal_time.dart';
import '../widgets/food_picker_sheet.dart';
import '../widgets/photo_callouts.dart';
import '../widgets/photo_item_sheet.dart';

/// How the result screen was left without saving.
enum PhotoResultExit { retake }

/// Review of a Scan Meal photo: callouts on the photo, the foods with their weight and nutrients, totals,
/// date and meal time. Pops with [PhotoResultExit.retake], or with the toast text after saving.
class PhotoResultScreen extends StatefulWidget {
  const PhotoResultScreen({super.key, required this.image, required this.analysis, required this.takenAt});

  final Uint8List image;
  final PhotoAnalysis analysis;

  /// When the photo was taken; picks the initial date and meal time.
  final DateTime takenAt;

  @override
  State<PhotoResultScreen> createState() => _PhotoResultScreenState();
}

class _PhotoResultScreenState extends State<PhotoResultScreen> {
  late final List<PhotoItem> _items = [...widget.analysis.items];
  late DateTime _date = DateUtils.dateOnly(widget.takenAt);
  late int _meal = mealTimes.indexWhere((t) => t.$1 == mealTimeAt(widget.takenAt));
  bool _saving = false;

  double _sum(double Function(PhotoItem) f) => _items.fold(0, (s, i) => s + f(i));

  void _step(int i, double delta) => setState(() => _items[i] = _items[i].withGrams(_items[i].grams + delta));

  Future<void> _edit(int i) async {
    final result = await showPhotoItemSheet(context, _items[i]);
    if (result == null || !mounted) return;
    setState(() {
      switch (result) {
        case PhotoItemChanged(:final item):
          _items[i] = item;
        case PhotoItemDeleted():
          _items.removeAt(i);
      }
    });
  }

  Future<void> _addManually() async {
    final food = await showFoodPicker(context);
    if (food == null || !mounted) return;
    setState(() => _items.add(PhotoItem.fromFood(food, grams: food.servingGrams)));
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final monthAgo = today.subtract(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _date.isBefore(monthAgo) ? _date : monthAgo,
      lastDate: today,
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final meal = mealTimes[_meal];
    final kcal = _sum((i) => i.caloriesKcal);
    final ok = await saveWithFeedback(
      context,
      (api) => api.addMealsBatch(mealTime: meal.$1, items: List.of(_items), date: _date),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop('Added to ${meal.$2} · ${fmtNum(kcal)} kcal');
    } else {
      setState(() => _saving = false);
    }
  }

  String get _dateLabel {
    final today = DateUtils.dateOnly(DateTime.now());
    if (_date == today) return 'Today';
    if (_date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return fmtShortDate(_date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Expanded(child: BackHeader('Meal photo')),
                  Text(
                    '${_items.length} ${_items.length == 1 ? 'food' : 'foods'}',
                    style: ts(13, FontWeight.w600, AppColors.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.memory(widget.image, width: double.infinity, fit: BoxFit.fitWidth),
                          Positioned.fill(child: PhotoCallouts(items: _items)),
                        ],
                      ),
                    ),
                    if (_items.isEmpty)
                      _EmptyCard(nothingFound: widget.analysis.items.isEmpty)
                    else ...[
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        radius: 14,
                        child: Column(
                          children: [
                            for (var i = 0; i < _items.length; i++)
                              _ItemRow(
                                index: i,
                                item: _items[i],
                                last: i == _items.length - 1,
                                onEdit: () => _edit(i),
                                onLess: () => _step(i, -10),
                                onMore: () => _step(i, 10),
                              ),
                          ],
                        ),
                      ),
                      _Totals(
                        grams: _sum((i) => i.grams),
                        kcal: _sum((i) => i.caloriesKcal),
                        protein: _sum((i) => i.proteinG),
                        carbs: _sum((i) => i.carbsG),
                        fat: _sum((i) => i.fatG),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: AppColors.orangeSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE7B0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Something missing?', style: ts(13, FontWeight.w600, AppColors.orangeText)),
                          ),
                          OutlineChipButton(label: 'Add manually', icon: Icons.add_rounded, onTap: _addManually),
                        ],
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        OutlineChipButton(
                          label: _dateLabel,
                          icon: Icons.calendar_today_rounded,
                          trailing: Icons.expand_more_rounded,
                          onTap: _pickDate,
                        ),
                        Expanded(
                          child: Segmented(
                            options: [for (final t in mealTimes) t.$2],
                            index: _meal,
                            onChanged: (i) => setState(() => _meal = i),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: PressScale(
                      label: 'Retake',
                      onTap: _saving ? null : () => Navigator.of(context).pop(PhotoResultExit.retake),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderStrong),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 6,
                          children: [
                            const Icon(Icons.refresh_rounded, size: 20),
                            Text('Retake', style: ts(16, FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _saving
                        ? Container(
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.greenDark,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            ),
                          )
                        : PrimaryButton(label: 'Save to log', onTap: _items.isEmpty ? null : _save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.index,
    required this.item,
    required this.last,
    required this.onEdit,
    required this.onLess,
    required this.onMore,
  });

  final int index;
  final PhotoItem item;
  final bool last;
  final VoidCallback onEdit;
  final VoidCallback onLess;
  final VoidCallback onMore;

  Widget _round(Key key, IconData icon, String label, VoidCallback onTap, {Color? bg, Color? fg}) => PressScale(
    key: key,
    label: label,
    scale: 0.9,
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        shape: BoxShape.circle,
        border: bg == null ? Border.all(color: AppColors.borderStrong) : null,
      ),
      child: Icon(icon, size: 16, color: fg ?? AppColors.text),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          spacing: 6,
          children: [
            PhotoNumberDot(index + 1, size: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 4,
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts(14, FontWeight.w700),
                        ),
                      ),
                      PhotoSourceChip(item),
                    ],
                  ),
                  Text(
                    '${fmtNum(item.caloriesKcal)} kcal · P ${fmtNum(item.proteinG)} · '
                    'C ${fmtNum(item.carbsG)} · F ${fmtNum(item.fatG)}',
                    style: ts(11, FontWeight.w400, AppColors.muted),
                  ),
                ],
              ),
            ),
            _round(ValueKey('photo-item-minus-$index'), Icons.remove_rounded, 'Less ${item.name}', onLess),
            SizedBox(
              width: 46,
              child: Text('${fmtNum(item.grams)} g', textAlign: TextAlign.center, style: ts(12, FontWeight.w700)),
            ),
            _round(ValueKey('photo-item-plus-$index'), Icons.add_rounded, 'More ${item.name}', onMore),
            _round(
              ValueKey('photo-item-edit-$index'),
              Icons.edit_rounded,
              'Edit ${item.name}',
              onEdit,
              bg: AppColors.greenSoft,
              fg: AppColors.greenDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double grams;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  Widget _macro(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(value, style: ts(13, FontWeight.w700)),
          Text(label, style: ts(10, FontWeight.w400, AppColors.muted)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text('Total · ${fmtNum(grams)} g', style: ts(12, FontWeight.w400, AppColors.muted)),
          Text('${fmtNum(kcal)} kcal', style: ts(22, FontWeight.w800)),
          Row(
            spacing: 6,
            children: [
              _macro('${fmtNum(protein)} g', 'Protein'),
              _macro('${fmtNum(carbs)} g', 'Carbs'),
              _macro('${fmtNum(fat)} g', 'Fat'),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.nothingFound});

  /// True when the AI found nothing; false when the user removed every food.
  final bool nothingFound;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 14,
      child: Column(
        spacing: 4,
        children: [
          const Icon(Icons.no_food_outlined, color: AppColors.muted, size: 32),
          Text(nothingFound ? 'No food found in this photo' : 'No foods left', style: ts(15, FontWeight.w700)),
          Text(
            nothingFound
                ? 'Take the photo again with the whole plate in view, or add the food manually.'
                : 'Add a food manually or retake the photo.',
            textAlign: TextAlign.center,
            style: ts(13, FontWeight.w400, AppColors.muted),
          ),
        ],
      ),
    );
  }
}
