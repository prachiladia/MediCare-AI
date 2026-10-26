import 'package:flutter/material.dart';
import '../../repositories/medicine_repository.dart';
import '../../repositories/repository_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/adherence_ring.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/section_eyebrow.dart';
import '../../widgets/status_badge.dart';

/// Detailed Adherence and Progress tracking screen.
///
/// Phase 8 Specifications:
/// - Adherence formula: Denominator = eligible occurrences whose scheduled time has passed (Taken + Skipped + Missed).
/// - Numerator: Confirmed Taken doses.
/// - Percentage = (Taken / Eligible) * 100.
/// - Shows Taken, Skipped, Missed, Pending separately.
/// - Safe divide-by-zero handling.
/// - States explicitly: Skipped doses count in the denominator but not as taken. Prototype metric only.
/// - Matches counts with Dashboard and History through [MedicineRepository].
class AdherenceScreen extends StatefulWidget {
  final MedicineRepository? repository;
  final int? takenCount;
  final int? pendingCount;
  final int? skippedCount;
  final int? missedCount;

  const AdherenceScreen({
    super.key,
    this.repository,
    this.takenCount,
    this.pendingCount,
    this.skippedCount,
    this.missedCount,
  });

  @override
  State<AdherenceScreen> createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends State<AdherenceScreen> {
  late int _taken;
  late int _pending;
  late int _skipped;
  late int _missed;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _taken = widget.takenCount ?? 4;
    _pending = widget.pendingCount ?? 1;
    _skipped = widget.skippedCount ?? 0;
    _missed = widget.missedCount ?? 0;

    _loadStats();
  }

  Future<void> _loadStats() async {
    final repo = widget.repository ??
        (widget.takenCount == null ? RepositoryManager.instance : null);

    if (repo != null) {
      setState(() => _isLoading = true);
      try {
        await repo.reconcileMissedDoses();
        final stats = await repo.getDoseSummaryStats();
        if (mounted) {
          setState(() {
            _taken = stats['taken'] ?? 0;
            _pending = stats['remaining'] ?? 0;
            _skipped = stats['skipped'] ?? 0;
            _missed = stats['missed'] ?? 0;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  int get eligibleCount => _taken + _skipped + _missed;
  int get totalScheduled => eligibleCount + _pending;

  double get adherenceRatio {
    if (eligibleCount == 0) {
      return totalScheduled > 0 ? 1.0 : 0.0;
    }
    return (_taken / eligibleCount).clamp(0.0, 1.0);
  }

  int get adherencePercentage => (adherenceRatio * 100).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Adherence & Progress'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DemoDataBanner(
                    text: 'Prototype metrics • Dynamic adherence active in Phase 8',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Hero Tape-Roll Adherence Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.rounded2xl,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppSpacing.cardShadow,
                    ),
                    child: Column(
                      children: [
                        const SectionEyebrow(title: 'DAILY ADHERENCE SCORE'),
                        const SizedBox(height: AppSpacing.lg),
                        _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.xl),
                                child: CircularProgressIndicator(color: AppColors.sageDeep),
                              )
                            : AdherenceTapeRoll(
                                percentage: adherenceRatio,
                                takenDoses: _taken,
                                totalDoses: totalScheduled,
                                size: 130,
                                strokeWidth: 14,
                              ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          eligibleCount > 0
                              ? '$adherencePercentage% Adherence Today'
                              : 'Healthy Routine in Motion',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adherence is calculated as Taken doses divided by completed decisions (Taken, Skipped, and Missed).',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const SectionEyebrow(title: "TODAY'S DOSE BREAKDOWN"),
                  const SizedBox(height: AppSpacing.sm),

                  // 4 Status Breakdown Cards
                  Row(
                    children: [
                      Expanded(
                        child: _BreakdownCard(
                          type: StatusBadgeType.taken,
                          label: 'Taken',
                          count: _taken,
                          subtitle: 'Confirmed on time',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _BreakdownCard(
                          type: StatusBadgeType.pending,
                          label: 'Pending',
                          count: _pending,
                          subtitle: 'Awaiting dose time',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _BreakdownCard(
                          type: StatusBadgeType.skipped,
                          label: 'Skipped',
                          count: _skipped,
                          subtitle: 'Reason recorded',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _BreakdownCard(
                          type: StatusBadgeType.missed,
                          label: 'Missed',
                          count: _missed,
                          subtitle: 'Expired without reply',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Policy & Educational Note Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: AppSpacing.roundedLg,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_outlined, color: AppColors.sageDeep, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Adherence Policy Note',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• Formula: Taken / (Taken + Skipped + Missed).\n'
                          '• Denominator = eligible occurrences whose scheduled window has closed.\n'
                          '• Skipped doses count in the denominator but not as taken.\n'
                          '• Pending doses are excluded until their window passes.\n'
                          '• Personal tracking prototype: not a medically validated clinical score.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final StatusBadgeType type;
  final String label;
  final int count;
  final String subtitle;

  const _BreakdownCard({
    required this.type,
    required this.label,
    required this.count,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(type: type, compact: true),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
