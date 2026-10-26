import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_spacing.dart';

/// A subtle banner indicating that all data shown in the interface is for
/// prototype and UI demonstration purposes only.
class DemoDataBanner extends StatelessWidget {
  final String text;

  const DemoDataBanner({
    super.key,
    this.text = 'Demo data • Reminders & cloud sync are not active yet',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
