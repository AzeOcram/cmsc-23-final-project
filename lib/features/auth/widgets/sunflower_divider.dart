// FILE LOCATION: lib/features/auth/widgets/sunflower_divider.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SunflowerDivider extends StatelessWidget {
  const SunflowerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.lemongrass.withOpacity(0.4),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.local_florist,
            size: 18,
            color: AppColors.sunflowerGold,
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.lemongrass.withOpacity(0.4),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
