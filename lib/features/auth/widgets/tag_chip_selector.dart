// FILE LOCATION: lib/features/auth/widgets/tag_chip_selector.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class TagChipSelector extends StatelessWidget {
  final List<String> tags;
  final List<String> selected;
  final void Function(String tag, bool selected) onChanged;

  const TagChipSelector({
    super.key,
    required this.tags,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final isSelected = selected.contains(tag);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: FilterChip(
            label: Text(tag),
            selected: isSelected,
            onSelected: (val) => onChanged(tag, val),
            backgroundColor: AppColors.lightMoss.withOpacity(0.5),
            selectedColor: AppColors.oliveGreen,
            checkmarkColor: AppColors.cream,
            labelStyle: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.cream : AppColors.barkBrown,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.oliveGreen
                  : AppColors.lemongrass.withOpacity(0.4),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: isSelected ? 2 : 0,
            pressElevation: 4,
          ),
        );
      }).toList(),
    );
  }
}
