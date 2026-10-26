import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular "tape roll" style adherence progress indicator.
///
/// Features a thick pastel track (sageLight) with rounded stroke progress (sageDeep)
/// and adherence count/percentage nestled inside the center.
class AdherenceTapeRoll extends StatelessWidget {
  final double percentage; // 0.0 to 1.0
  final int takenDoses;
  final int totalDoses;
  final double size;
  final double strokeWidth;

  const AdherenceTapeRoll({
    super.key,
    required this.percentage,
    required this.takenDoses,
    required this.totalDoses,
    this.size = 110.0,
    this.strokeWidth = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percentage.clamp(0.0, 1.0);
    final displayPercent = (clampedPercent * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track and progress arc
          CustomPaint(
            size: Size(size, size),
            painter: _TapeRollPainter(
              progress: clampedPercent,
              trackColor: AppColors.sageLight.withValues(alpha: 0.5),
              progressColor: AppColors.sageDeep,
              strokeWidth: strokeWidth,
            ),
          ),

          // Central text metrics
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$displayPercent%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$takenDoses of $totalDoses taken',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TapeRollPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _TapeRollPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc Paint
    if (progress > 0.0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Start at top (-pi / 2)
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TapeRollPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
