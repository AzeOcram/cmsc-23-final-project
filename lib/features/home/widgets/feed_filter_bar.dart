// FILE LOCATION: lib/features/home/widgets/feed_filter_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/pantry_item_model.dart';
import '../../../core/models/user_model.dart';

class FeedFilterBar extends StatelessWidget {
  final List<String> selectedCategories;
  final List<String> selectedDietary;
  final String sortBy;
  final void Function(String) onCategoryToggle;
  final void Function(String) onDietaryToggle;
  final void Function(String) onSortChanged;
  final VoidCallback onClearAll;

  const FeedFilterBar({
    super.key,
    required this.selectedCategories,
    required this.selectedDietary,
    required this.sortBy,
    required this.onCategoryToggle,
    required this.onDietaryToggle,
    required this.onSortChanged,
    required this.onClearAll,
  });

  bool get hasFilters =>
      selectedCategories.isNotEmpty ||
      selectedDietary.isNotEmpty ||
      sortBy != 'newest';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort + Filter button row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              // Sort dropdown
              _SortButton(
                value: sortBy,
                onChanged: onSortChanged,
              ),
              const SizedBox(width: 8),
              // Filter button
              GestureDetector(
                onTap: () => _showFilterSheet(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasFilters
                        ? AppColors.oliveGreen
                        : AppColors.lightMoss.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasFilters
                          ? AppColors.oliveGreen
                          : AppColors.lemongrass.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune,
                        size: 15,
                        color:
                            hasFilters ? AppColors.cream : AppColors.oliveGreen,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hasFilters
                            ? 'Filtered (${selectedCategories.length + selectedDietary.length})'
                            : 'Filter',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasFilters
                              ? AppColors.cream
                              : AppColors.oliveGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClearAll,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Active filter chips (categories)
        if (selectedCategories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              itemCount: selectedCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = selectedCategories[i];
                return GestureDetector(
                  onTap: () => onCategoryToggle(cat),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sunflowerGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.sunflowerGold.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.barkBrown,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.close,
                            size: 12, color: AppColors.barkBrown),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 4),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        selectedCategories: selectedCategories,
        selectedDietary: selectedDietary,
        onCategoryToggle: onCategoryToggle,
        onDietaryToggle: onDietaryToggle,
        onClearAll: onClearAll,
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _SortButton({required this.value, required this.onChanged});

  String get _label {
    switch (value) {
      case 'expiring':
        return 'Expiring soon';
      default:
        return 'Newest first';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.cream,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort by', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _sortOption(context, 'newest', 'Newest first',
                    Icons.access_time_outlined),
                _sortOption(context, 'expiring', 'Expiring soon',
                    Icons.hourglass_bottom_outlined),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightMoss.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lemongrass.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 15, color: AppColors.oliveGreen),
            const SizedBox(width: 5),
            Text(
              _label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.oliveGreen,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_drop_down,
                size: 16, color: AppColors.oliveGreen),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(
      BuildContext context, String val, String label, IconData icon) {
    final active = value == val;
    return ListTile(
      leading: Icon(icon,
          color: active ? AppColors.oliveGreen : AppColors.barkBrown),
      title: Text(label,
          style: GoogleFonts.lato(
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.oliveGreen : AppColors.barkBrown,
          )),
      trailing:
          active ? const Icon(Icons.check, color: AppColors.oliveGreen) : null,
      onTap: () {
        onChanged(val);
        Navigator.pop(context);
      },
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final List<String> selectedCategories;
  final List<String> selectedDietary;
  final void Function(String) onCategoryToggle;
  final void Function(String) onDietaryToggle;
  final VoidCallback onClearAll;

  const _FilterSheet({
    required this.selectedCategories,
    required this.selectedDietary,
    required this.onCategoryToggle,
    required this.onDietaryToggle,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lemongrass.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Items',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    onClearAll();
                    Navigator.pop(context);
                  },
                  child: Text('Clear All',
                      style: GoogleFonts.lato(
                          color: AppColors.error, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Category',
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.w700, color: AppColors.forestDeep)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kItemCategories.map((cat) {
                final sel = selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat),
                  selected: sel,
                  onSelected: (_) => onCategoryToggle(cat),
                  backgroundColor: AppColors.lightMoss.withOpacity(0.5),
                  selectedColor: AppColors.oliveGreen,
                  checkmarkColor: AppColors.cream,
                  labelStyle: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? AppColors.cream : AppColors.barkBrown,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Dietary Tags',
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.w700, color: AppColors.forestDeep)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kDietaryTags.map((tag) {
                final sel = selectedDietary.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: sel,
                  onSelected: (_) => onDietaryToggle(tag),
                  backgroundColor: AppColors.lightMoss.withOpacity(0.5),
                  selectedColor: AppColors.sunflowerDeep,
                  checkmarkColor: AppColors.cream,
                  labelStyle: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? AppColors.cream : AppColors.barkBrown,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
