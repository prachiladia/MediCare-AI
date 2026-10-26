import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Interactive quick-action tile with scale-down feedback and large tap target.
class QuickActionTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  final String? subtitle;

  const QuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    this.subtitle,
  });

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEmergency = widget.color == AppColors.emergency;

    return Expanded(
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.roundedXl,
                border: Border.all(
                  color: _isPressed
                      ? widget.color.withValues(alpha: 0.5)
                      : (isEmergency
                          ? AppColors.emergency.withValues(alpha: 0.3)
                          : AppColors.border),
                  width: isEmergency ? 1.5 : 1.0,
                ),
                boxShadow: AppSpacing.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isEmergency ? AppColors.emergency : AppColors.forest,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
