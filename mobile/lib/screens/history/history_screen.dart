import 'package:flutter/material.dart';
import '../../models/dose_occurrence.dart';
import '../../repositories/medicine_repository.dart';
import '../../repositories/repository_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/status_badge.dart';

/// Filter categories for the adherence history log.
enum HistoryFilter {
  all('All', null),
  taken('Taken', DoseStatus.taken),
  skipped('Skipped', DoseStatus.skipped),
  missed('Missed', DoseStatus.missed);

  final String label;
  final DoseStatus? status;
  const HistoryFilter(this.label, this.status);
}

/// Screen displaying the user's medication history and adherence tracking.
///
/// Phase 7 Requirements:
/// - Reads real occurrences from [MedicineRepository] or passed [occurrences].
/// - Strictly NO fictitious hardcoded history records.
/// - Filters: All, Taken, Skipped, Missed.
/// - Chronological ordering: newest first.
/// - Clear display of original scheduled time, action timestamp, and skip reason.
/// - Helpful empty states with supportive, non-shaming wording.
class HistoryScreen extends StatefulWidget {
  final List<DoseOccurrence>? occurrences;
  final MedicineRepository? repository;

  const HistoryScreen({
    super.key,
    this.occurrences,
    this.repository,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.all;
  List<DoseOccurrence> _historyList = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.occurrences != widget.occurrences ||
        oldWidget.repository != widget.repository) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = widget.repository ??
          (widget.occurrences == null ? RepositoryManager.instance : null);

      if (repo != null) {
        // Reconcile missed doses on history view
        await repo.reconcileMissedDoses();
        final records = await repo.getHistoryOccurrences(
          filterStatus: _selectedFilter.status,
        );
        if (mounted) {
          setState(() {
            _historyList = records;
            _isLoading = false;
          });
        }
      } else {
        // Fallback from widget.occurrences
        Iterable<DoseOccurrence> list = widget.occurrences ?? [];
        if (_selectedFilter.status != null) {
          list = list.where((o) => o.status == _selectedFilter.status);
        }
        final sorted = List<DoseOccurrence>.from(list);
        sorted.sort((a, b) {
          final aTime = a.actionTimestamp ?? a.originalScheduledTime;
          final bTime = b.actionTimestamp ?? b.originalScheduledTime;
          return bTime.compareTo(aTime);
        });
        if (mounted) {
          setState(() {
            _historyList = sorted;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load history: $e';
        });
      }
    }
  }

  void _onFilterSelected(HistoryFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    _loadHistory();
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;

    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final stdHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeStr = '${stdHour.toString().padLeft(2, '0')}:$minute $period';

    if (isToday) return 'Today at $timeStr';
    if (isYesterday) return 'Yesterday at $timeStr';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final allOccurrences = widget.occurrences ?? _historyList;
    final takenCount = allOccurrences.where((o) => o.isTaken).length;
    final skippedCount = allOccurrences.where((o) => o.isSkipped).length;
    final missedCount = allOccurrences.where((o) => o.isMissed).length;
    final eligibleCount = takenCount + skippedCount + missedCount;
    final adherenceRate = eligibleCount > 0
        ? ((takenCount / eligibleCount) * 100).round()
        : 100;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Adherence History'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.sageDeep,
          backgroundColor: AppColors.surface,
          onRefresh: _loadHistory,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DemoDataBanner(
                  text: 'In-memory demo • Updates reconcile when app opens or resumes',
                ),
                const SizedBox(height: AppSpacing.lg),

                // Real Summary Overview Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.rounded2xl,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppSpacing.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'ADHERENCE SNAPSHOT',
                              style: AppTextStyles.eyebrow,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusTakenBg,
                              borderRadius: AppSpacing.roundedPill,
                              border: Border.all(color: AppColors.sageLight),
                            ),
                            child: Text(
                              eligibleCount > 0
                                  ? '$adherenceRate% Adherence'
                                  : 'No doses due yet',
                              style: const TextStyle(
                                color: AppColors.sageDeep,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        eligibleCount > 0
                            ? '$takenCount of $eligibleCount Doses Taken'
                            : 'All Caught Up',
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        eligibleCount > 0
                            ? 'Taken: $takenCount • Skipped: $skippedCount • Missed: $missedCount'
                            : 'No dose events have passed their scheduled time yet.',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                  children: HistoryFilter.values.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Material(
                        key: ValueKey('filter_${filter.name}'),
                        color: isSelected
                            ? AppColors.sageDeep
                            : AppColors.surface,
                        borderRadius: AppSpacing.roundedPill,
                        child: InkWell(
                          borderRadius: AppSpacing.roundedPill,
                          onTap: () => _onFilterSelected(filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: AppSpacing.roundedPill,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.sageDeep
                                    : AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              filter.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.forest,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

                const SizedBox(height: AppSpacing.lg),

                // Dose Records List or Empty State
                if (_isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.sageDeep,
                      ),
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: AppColors.emergency,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sageDeep,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Try Again'),
                            onPressed: _loadHistory,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (_historyList.isEmpty) ...[
                  _buildEmptyState(_selectedFilter),
                ] else ...[
                  ..._historyList.map((occ) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _HistoryOccurrenceCard(
                        occurrence: occ,
                        formattedOriginalTime:
                            _formatDateTime(occ.originalScheduledTime),
                        formattedActionTime: occ.actionTimestamp != null
                            ? _formatDateTime(occ.actionTimestamp!)
                            : null,
                      ),
                    );
                  }),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Informational Note Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Missed status is evaluated when the app is opened or resumed. Doses are marked missed if unhandled 60m past scheduled time, or 30m after last snooze.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
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
    );
  }

  Widget _buildEmptyState(HistoryFilter filter) {
    final (IconData icon, String title, String message) = switch (filter) {
      HistoryFilter.taken => (
          Icons.medication_outlined,
          'No Taken Doses Yet',
          'Logged doses marked as taken will be displayed here in chronological order.'
        ),
      HistoryFilter.skipped => (
          Icons.thumb_up_alt_outlined,
          'No Skipped Doses',
          'When you record a skipped dose with a reason, it will appear here.'
        ),
      HistoryFilter.missed => (
          Icons.sentiment_satisfied_alt_rounded,
          'No Missed Doses!',
          'Great job staying on track with your routine. You have zero missed doses recorded.'
        ),
      HistoryFilter.all => (
          Icons.history_toggle_off_rounded,
          'No Dose Records Found',
          'Your medication dose activity (taken, skipped, or missed) will be logged here.'
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.rounded2xl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: filter == HistoryFilter.missed
                  ? AppColors.sageDeep
                  : AppColors.sage,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoryOccurrenceCard extends StatelessWidget {
  final DoseOccurrence occurrence;
  final String formattedOriginalTime;
  final String? formattedActionTime;

  const _HistoryOccurrenceCard({
    required this.occurrence,
    required this.formattedOriginalTime,
    this.formattedActionTime,
  });

  @override
  Widget build(BuildContext context) {
    final statusType = occurrence.isTaken
        ? StatusBadgeType.taken
        : (occurrence.isSkipped
            ? StatusBadgeType.skipped
            : (occurrence.isMissed
                ? StatusBadgeType.missed
                : (occurrence.isSnoozed
                    ? StatusBadgeType.snoozed
                    : StatusBadgeType.pending)));

    final statusLabel = occurrence.isTaken
        ? 'Taken'
        : (occurrence.isSkipped
            ? 'Skipped'
            : (occurrence.isMissed
                ? 'Missed Window'
                : (occurrence.isSnoozed
                    ? 'Snoozed (${occurrence.snoozeCount}/3)'
                    : 'Pending')));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                type: statusType,
                customLabel: statusLabel,
                compact: true,
              ),
              if (occurrence.isSampleData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Sample',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            occurrence.medicineName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Dosage: ${occurrence.dosage}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Scheduled: $formattedOriginalTime',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (formattedActionTime != null) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  occurrence.isTaken
                      ? Icons.check_circle_outline_rounded
                      : (occurrence.isSkipped
                          ? Icons.redo_rounded
                          : (occurrence.isMissed
                              ? Icons.info_outline_rounded
                              : Icons.snooze_rounded)),
                  size: 14,
                  color: occurrence.isTaken
                      ? AppColors.statusTaken
                      : (occurrence.isMissed
                          ? AppColors.statusMissed
                          : AppColors.textMuted),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    occurrence.isTaken
                        ? 'Taken at: $formattedActionTime'
                        : (occurrence.isSkipped
                            ? 'Skipped at: $formattedActionTime'
                            : (occurrence.isMissed
                                ? 'Window passed: $formattedActionTime'
                                : 'Snoozed at: $formattedActionTime')),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: occurrence.isMissed
                          ? AppColors.statusMissed
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (occurrence.isSkipped &&
              occurrence.skipReason != null &&
              occurrence.skipReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.statusSkippedBg,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(color: AppColors.blush),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 13,
                    color: AppColors.statusSkipped,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: ${occurrence.skipReason}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.forest,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
