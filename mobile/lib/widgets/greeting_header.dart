import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/greeting_helper.dart';

/// Top hero greeting card with blush pastel background, high-contrast forest text,
/// Sweet Tape-inspired display typography, dynamic time-of-day greeting, and an avatar badge.
class GreetingHeader extends StatelessWidget {
  final String? greeting;
  final String? userName;
  final String? initials;
  final String companionSubtitle;
  final VoidCallback? onAvatarTap;
  final DateTime Function()? clock;

  const GreetingHeader({
    super.key,
    this.greeting,
    this.userName,
    this.initials,
    this.companionSubtitle = "We'll stick by your doses today.",
    this.onAvatarTap,
    this.clock,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGreeting =
        greeting ?? GreetingHelper.getGreeting(clock: clock);
    final trimmedName = userName?.trim() ?? '';
    final hasName = trimmedName.isNotEmpty;
    final effectiveInitials = initials != null && initials!.trim().isNotEmpty
        ? initials!.trim()
        : GreetingHelper.getInitials(trimmedName);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: AppSpacing.rounded2xl,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: AppSpacing.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Soft ambient corner decorative shape (expansive, intentional background wash)
          Positioned(
            top: -50,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sageLight.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -45,
            left: 20,
            child: IgnorePointer(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),

          // Main Header Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.heroPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Eyebrow sticker badge & Profile Avatar with layered halo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Small companion sticker
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: AppSpacing.roundedPill,
                        border: Border.all(
                          color: AppColors.sage.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 13,
                            color: AppColors.sageDeep,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'MEDICARE COMPANION',
                            style: TextStyle(
                              color: AppColors.forest,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Avatar with an intentional layered halo frame
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sageLight.withValues(alpha: 0.45),
                        border: Border.all(
                          color: AppColors.sage.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Semantics(
                        label: 'User profile avatar',
                        button: true,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(
                            side: BorderSide(
                              color: AppColors.sageDeep,
                              width: 1.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onAvatarTap,
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: Center(
                                child: effectiveInitials.isNotEmpty
                                    ? Text(
                                        effectiveInitials,
                                        style: const TextStyle(
                                          color: AppColors.forest,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          letterSpacing: 0.3,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.forest,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Greeting Display Headline with Single-Line Ellipsis Guard
                Text(
                  hasName
                      ? '${effectiveGreeting.toUpperCase()}, $trimmedName!'
                      : '${effectiveGreeting.toUpperCase()}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heroLarge.copyWith(
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Companion Subtitle (Human, warm microcopy)
                Text(
                  companionSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Easygoing. No drama.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
