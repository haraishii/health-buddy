import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/api/api_models.dart';
import '../../../../theme.dart';
import '../../../../widgets/api_builder.dart';
import '../../../../widgets/format.dart';

/// Searches the food database like the Search tab and returns the tapped food, or null when dismissed.
/// Used by the Scan Meal photo result for "Add manually" and "Change food".
Future<Food?> showFoodPicker(BuildContext context) => showModalBottomSheet<Food>(
  context: context,
  showDragHandle: true,
  backgroundColor: Colors.white,
  isScrollControlled: true,
  builder: (_) => const _FoodPicker(),
);

class _FoodPicker extends StatefulWidget {
  const _FoodPicker();

  @override
  State<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends State<_FoodPicker> {
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.75,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text('Add a food', style: ts(18, FontWeight.w700)),
              TextField(
                autofocus: true,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                style: ts(15),
                decoration: InputDecoration(
                  hintText: 'Search food, e.g. tempe goreng',
                  hintStyle: ts(15, FontWeight.w400, AppColors.muted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              Expanded(
                child: ApiBuilder<List<Food>>(
                  cacheKey: 'foods:${_query.toLowerCase()}',
                  load: (api) => api.searchFoods(query: _query, popular: _query.isEmpty, limit: 30),
                  loading: const Center(child: CircularProgressIndicator()),
                  builder: (context, foods) => foods.isEmpty
                      ? Text(
                          'No food found for "$_query". Try another name.',
                          textAlign: TextAlign.center,
                          style: ts(14, FontWeight.w400, AppColors.muted),
                        )
                      : ListView.separated(
                          itemCount: foods.length,
                          separatorBuilder: (context, i) => const Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (context, i) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(foods[i].name, style: ts(15, FontWeight.w600)),
                            subtitle: Text(
                              '${foods[i].serving} · ${fmtNum(foods[i].caloriesKcal)} kcal',
                              style: ts(12, FontWeight.w400, AppColors.muted),
                            ),
                            trailing: const Icon(Icons.add_circle_rounded, color: AppColors.green),
                            onTap: () => Navigator.of(context).pop(foods[i]),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
