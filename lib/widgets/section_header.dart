import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Libre Caslon heading with an optional trailing rule, used to group
/// fields/sections on checkout and profile-style screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.withRule = true});

  final String title;
  final bool withRule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (withRule) ...[
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Divider(color: AppColors.line, height: AppSpacing.hairline)),
          ],
        ],
      ),
    );
  }
}
