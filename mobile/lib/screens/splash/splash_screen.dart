import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Splash Screen for MediCare AI.
///
/// Features a warm pastel blush/cream hero moment, Sweet Tape-inspired display headline,
/// washi-tape accent strip, and smooth ~1.8s automatic transition to the login screen.
class SplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const SplashScreen({super.key, this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();

    // Smooth ~1.8 second splash before transitioning
    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        if (widget.onFinished != null) {
          widget.onFinished!();
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _skipImmediately() {
    _navigationTimer?.cancel();
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decorative Washi Tape Strip
                      Transform.rotate(
                        angle: -0.03, // ~-1.7 degrees
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.tapeYellow,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'HEALTH COMPANION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Logo Mark
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.blush,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.sageDeep.withValues(alpha: 0.25),
                            width: 2,
                          ),
                          boxShadow: AppSpacing.heroShadow,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.medication_rounded,
                            size: 48,
                            color: AppColors.sageDeep,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      const Text(
                        'MediCare AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.sageDeep,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Big, Friendly Display Headline
                      const Text(
                        "WE'LL STICK BY\nYOUR DOSES.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.8,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Official Tagline
                      Text(
                        'Never Miss a Dose. Stay Healthy. Stay Connected.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // Subtle progress indicator & quick skip button
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.sageDeep),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextButton(
                        onPressed: _skipImmediately,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Continue →',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sageDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
