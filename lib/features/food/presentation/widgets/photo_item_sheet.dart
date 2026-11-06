import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/api/api_models.dart';
import '../../../../theme.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/format.dart';
import 'food_picker_sheet.dart';

/// What the user did in the photo item sheet.
sealed class PhotoItemEdit {
  const PhotoItemEdit();
}

class PhotoItemChanged extends PhotoItemEdit {
  const PhotoItemChanged(this.item);

  final PhotoItem item;
}

class PhotoItemDeleted extends PhotoItemEdit {
  const PhotoItemDeleted();
}

/// Edit one food from a Scan Meal photo: change it to a database food, change its weight, or delete it.
/// Returns null when dismissed.
Future<PhotoItemEdit?> showPhotoItemSheet(BuildContext context, PhotoItem item) => showModalBottomSheet<PhotoItemEdit>(
  context: context,
  showDragHandle: true,
  backgroundColor: Colors.white,
  isScrollControlled: true,
  builder: (_) => _PhotoItemSheet(item: item),
);

/// "Database" or "AI estimate": where a photo item's nutrients come from.
class PhotoSourceChip extends StatelessWidget {
  const PhotoSourceChip(this.item, {super.key});

  final PhotoItem item;

  @override
  Widget build(BuildContext context) {
    final db = item.fromDatabase;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: db ? AppColors.blueSoft : AppColors.purpleSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        db ? 'Database' : 'AI estimate',
        style: ts(10, FontWeight.w700, db ? AppColors.blueDark : AppColors.purpleDark),
      ),
    );
  }
}

class _PhotoItemSheet extends StatefulWidget {
  const _PhotoItemSheet({required this.item});

  final PhotoItem item;

  @override
  State<_PhotoItemSheet> createState() => _PhotoItemSheetState();
}

class _PhotoItemSheetState extends State<_PhotoItemSheet> {
  late PhotoItem _item = widget.item;

  Future<void> _changeFood() async {
    final food = await showFoodPicker(context);
    if (food == null || !mounted) return;
    setState(() => _item = PhotoItem.fromFood(food, grams: _item.grams, box: _item.box));
  }

  Widget _round(IconData icon, String label, VoidCallback onTap) => PressScale(
    label: label,
    scale: 0.92,
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Icon(icon, color: AppColors.text),
    ),
  );

  Widget _macro(String value, String label, Color bg) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: ts(15, FontWeight.w700)),
          Text(label, style: ts(11, FontWeight.w400, AppColors.muted)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final it = _item;
    final sliderMax = math.max(1000.0, it.grams);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.name, style: ts(20, FontWeight.w800)),
                      Text(
                        it.fromDatabase
                            ? 'Nutrients from the food database'
                            : 'Recognized by AI · ${(it.confidence * 100).round()}% sure',
                        style: ts(12, FontWeight.w400, AppColors.muted),
                      ),
                    ],
                  ),
                ),
                PhotoSourceChip(it),
              ],
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              radius: 12,
              label: 'Change food',
              onTap: _changeFood,
              child: Row(
                children: [
                  Expanded(child: Text('Change food', style: ts(14, FontWeight.w600))),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.greenDark),
                ],
              ),
            ),
            Row(
              children: [
                _round(Icons.remove_rounded, 'Less', () => setState(() => _item = it.withGrams(it.grams - 10))),
                Expanded(
                  child: Text('${fmtNum(it.grams)} g', textAlign: TextAlign.center, style: ts(24, FontWeight.w800)),
                ),
                _round(Icons.add_rounded, 'More', () => setState(() => _item = it.withGrams(it.grams + 10))),
              ],
            ),
            Slider(
              value: it.grams.clamp(PhotoItem.minGrams, sliderMax).toDouble(),
              min: PhotoItem.minGrams,
              max: sliderMax,
              activeColor: AppColors.green,
              label: '${fmtNum(it.grams)} g',
              onChanged: (v) => setState(() => _item = it.withGrams(v.roundToDouble())),
            ),
            Row(
              spacing: 6,
              children: [
                _macro(fmtNum(it.caloriesKcal), 'kcal', AppColors.orangeSoft),
                _macro('${fmtNum(it.proteinG)} g', 'Protein', AppColors.greenSoft),
                _macro('${fmtNum(it.carbsG)} g', 'Carbs', AppColors.blueSoft),
                _macro('${fmtNum(it.fatG)} g', 'Fat', AppColors.purpleSoft),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: PressScale(
                    label: 'Delete',
                    onTap: () => Navigator.of(context).pop(const PhotoItemDeleted()),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      child: Text('Delete', style: ts(16, FontWeight.w700, AppColors.red)),
                    ),
                  ),
                ),
                Expanded(
                  child: PrimaryButton(
                    label: 'Done',
                    height: 52,
                    onTap: () => Navigator.of(context).pop(PhotoItemChanged(_item)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
