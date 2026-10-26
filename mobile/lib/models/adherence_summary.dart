import 'dose_occurrence.dart';

/// Computed adherence metrics for a collection of dose occurrences.
class AdherenceMetrics {
  final int taken;
  final int skipped;
  final int missed;
  final int pending;
  final int eligible;
  final int totalScheduled;
  final double percentage;

  const AdherenceMetrics({
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.pending,
    required this.eligible,
    required this.totalScheduled,
    required this.percentage,
  });

  int get roundedPercentage => percentage.round();
}

/// Utility for calculating medication adherence.
///
/// Phase 8 Formula Specification:
/// - Denominator = eligible occurrences whose scheduled time has passed and have reached a terminal status (Taken + Skipped + Missed).
/// - Numerator = occurrences confirmed [DoseStatus.taken].
/// - Percentage = (Taken / Eligible) * 100.
/// - Pending/Snoozed occurrences are excluded from the denominator until their response window concludes.
/// - Divide-by-zero handling: when eligible == 0, percentage is 100.0% if totalScheduled > 0, or 0.0% if zero doses exist.
/// - Prototype limitation notice: Skipped doses count in the denominator (eligible) but not as taken. This is a prototype metric, not a medically validated clinical score.
class AdherenceCalculator {
  AdherenceCalculator._();

  static AdherenceMetrics calculate(Iterable<DoseOccurrence> occurrences) {
    int taken = 0;
    int skipped = 0;
    int missed = 0;
    int pending = 0;

    for (final occ in occurrences) {
      if (occ.isTaken) {
        taken++;
      } else if (occ.isSkipped) {
        skipped++;
      } else if (occ.isMissed) {
        missed++;
      } else {
        pending++;
      }
    }

    final eligible = taken + skipped + missed;
    final totalScheduled = eligible + pending;

    // Divide-by-zero protection:
    final double percentage;
    if (eligible == 0) {
      percentage = totalScheduled > 0 ? 100.0 : 0.0;
    } else {
      percentage = ((taken / eligible) * 100.0).clamp(0.0, 100.0);
    }

    return AdherenceMetrics(
      taken: taken,
      skipped: skipped,
      missed: missed,
      pending: pending,
      eligible: eligible,
      totalScheduled: totalScheduled,
      percentage: percentage,
    );
  }
}
