import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/dose_occurrence.dart';
import '../../models/medicine.dart';
import '../../repositories/medicine_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/greeting_helper.dart';
import '../../widgets/adherence_card.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/medicine_list_tile.dart';
import '../../widgets/next_reminder_card.dart';
import '../../widgets/quick_action_tile.dart';
import '../../widgets/section_eyebrow.dart';
import '../../widgets/summary_stat_card.dart';
import '../adherence/adherence_screen.dart';
import '../medicines/add_medicine_screen.dart';
import '../medicines/medicine_details_screen.dart';
import '../reminder/medicine_reminder_screen.dart';
import '../sos/sos_confirmation_screen.dart';

/// The primary Home dashboard for MediCare AI.
///
/// Houses the hero greeting, medication summary stats, featured next dose card with tape accent,
/// horizontal carousel for upcoming doses, daily adherence tape-roll ring, quick actions,
/// and interactive today's medicine list.
class HomeScreen extends StatefulWidget {
  final List<Medicine> medicines;
  final List<DoseOccurrence>? occurrences;
  final MedicineRepository? repository;
  final Function(Medicine) onToggleStatus;
  final Function(Medicine) onAddMedicine;
  final VoidCallback onNavigateToHistory;
  final VoidCallback onNavigateToMedicines;
  final VoidCallback onNavigateToProfile;
  final Function(Medicine)? onUpdateMedicine;
  final Function(String)? onDeleteMedicine;
  final Function(Medicine, bool)? onToggleEnabled;
  final Function(DoseOccurrence)? onTakeOccurrence;
  final Function(DoseOccurrence, int)? onSnoozeOccurrence;
  final Function(DoseOccurrence, String)? onSkipOccurrence;
  final AppUser? user;
  final DateTime Function()? clock;

  const HomeScreen({
    super.key,
    required this.medicines,
    this.occurrences,
    this.repository,
    required this.onToggleStatus,
    required this.onAddMedicine,
    required this.onNavigateToHistory,
    required this.onNavigateToMedicines,
    required this.onNavigateToProfile,
    this.onUpdateMedicine,
    this.onDeleteMedicine,
    this.onToggleEnabled,
    this.onTakeOccurrence,
    this.onSnoozeOccurrence,
    this.onSkipOccurrence,
    this.user,
    this.clock,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animController;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Staggered entrances for dashboard sections
    _fadeAnimations = List.generate(7, (index) {
      final start = (index * 0.08).clamp(0.0, 0.6);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(7, (index) {
      final start = (index * 0.08).clamp(0.0, 0.6);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Recompute time-of-day greeting dynamically when app resumes
      setState(() {});
    }
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic computations from real occurrence data if provided, fallback to medicines
    final int scheduledCount;
    final int takenCount;
    final int remainingCount;

    if (widget.occurrences != null && widget.occurrences!.isNotEmpty) {
      scheduledCount = widget.occurrences!.length;
      takenCount = widget.occurrences!.where((o) => o.isTaken).length;
      remainingCount = widget.occurrences!.where((o) => o.isPending || o.isSnoozed).length;
    } else {
      scheduledCount = widget.medicines.where((m) => m.isEnabled).length;
      takenCount = widget.medicines.where((m) => m.isEnabled && m.isTaken).length;
      remainingCount = widget.medicines.where((m) => m.isEnabled && m.isPending).length;
    }

    final pendingList = widget.medicines.where((m) => m.isEnabled && m.isPending).toList();

    // Determine next upcoming dose & occurrence
    Medicine? nextReminder;
    DoseOccurrence? nextOccurrence;

    if (widget.occurrences != null && widget.occurrences!.isNotEmpty) {
      final uncompleted = widget.occurrences!.where((o) => !o.isCompleted).toList();
      if (uncompleted.isNotEmpty) {
        nextOccurrence = uncompleted.first;
        for (final m in widget.medicines) {
          if (m.id == nextOccurrence.medicineId) {
            nextReminder = m;
            break;
          }
        }
      }
    }

    if (nextReminder == null) {
      final heroCandidates = widget.medicines
          .where((m) => m.isEnabled && m.isHeroReminder && m.isPending)
          .toList();
      if (heroCandidates.isNotEmpty) {
        nextReminder = heroCandidates.first;
      } else if (pendingList.isNotEmpty) {
        nextReminder = pendingList.first;
      }
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Hero Greeting Card)
              _buildAnimatedSection(
                0,
                GreetingHeader(
                  userName: GreetingHelper.resolveFirstName(
                    user: widget.user,
                    isDemo: widget.user?.isDemoUser == true,
                  ),
                  initials: GreetingHelper.getInitials(
                    GreetingHelper.resolveDisplayName(
                      user: widget.user,
                      isDemo: widget.user?.isDemoUser == true,
                    ),
                  ),
                  clock: widget.clock,
                  onAvatarTap: widget.onNavigateToProfile,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Demo Data Banner
              const DemoDataBanner(
                text: 'In-Memory Prototype • All changes reset when app restarts • Sample data',
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. Today's Medication Summary Stat Cards
              _buildAnimatedSection(
                1,
                SummaryStatCards(
                  scheduledCount: scheduledCount,
                  takenCount: takenCount,
                  remainingCount: remainingCount,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 3. Next Reminder Card (Hero Dose Card with Washi Tape Accent)
              _buildAnimatedSection(
                2,
                NextReminderCard(
                  medicine: nextReminder,
                  onTakeAction: nextReminder != null
                      ? () {
                          if (nextOccurrence != null && widget.onTakeOccurrence != null) {
                            widget.onTakeOccurrence!(nextOccurrence);
                          } else {
                            widget.onToggleStatus(nextReminder!);
                          }
                        }
                      : null,
                  onTap: nextReminder != null
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MedicineReminderScreen(
                                medicine: nextReminder!,
                                occurrence: nextOccurrence,
                                repository: widget.repository,
                                onTaken: () {
                                  if (nextOccurrence != null && widget.onTakeOccurrence != null) {
                                    widget.onTakeOccurrence!(nextOccurrence);
                                  } else {
                                    widget.onToggleStatus(nextReminder!);
                                  }
                                },
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ),

              // Horizontal Upcoming Carousel (Section 4.3 inspiration)
              if (pendingList.length > 1) ...[
                const SizedBox(height: AppSpacing.xl),
                _buildAnimatedSection(
                  3,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionEyebrow(
                        title: 'UPCOMING DOSES TODAY',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 114,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: pendingList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final med = pendingList[index];
                            return _UpcomingHorizontalCard(
                              medicine: med,
                              onTake: () => widget.onToggleStatus(med),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MedicineReminderScreen(
                                      medicine: med,
                                      onTaken: () => widget.onToggleStatus(med),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // 4. Daily Adherence Card (Tape-roll Progress Ring)
              _buildAnimatedSection(
                4,
                AdherenceCard(
                  takenCount: takenCount,
                  totalCount: scheduledCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AdherenceScreen(
                        repository: widget.repository,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 5. Quick Actions Section
              _buildAnimatedSection(
                5,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionEyebrow(
                      title: 'QUICK ACTIONS',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        QuickActionTile(
                          label: 'Add Med',
                          subtitle: 'New dose',
                          icon: Icons.add_rounded,
                          color: AppColors.sageDeep,
                          backgroundColor: AppColors.blush,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddMedicineScreen(
                                  onMedicineAdded: widget.onAddMedicine,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        QuickActionTile(
                          label: 'History',
                          subtitle: 'Sample logs',
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.sage,
                          backgroundColor: AppColors.statusTakenBg,
                          onTap: widget.onNavigateToHistory,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        QuickActionTile(
                          label: 'SOS Help',
                          subtitle: 'Emergency',
                          icon: Icons.emergency_rounded,
                          color: AppColors.emergency,
                          backgroundColor: AppColors.emergencyBg,
                          onTap: () => SosConfirmationDialog.show(
                            context,
                            repository: widget.repository,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // 6. Today's Medicine List
              _buildAnimatedSection(
                6,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionEyebrow(
                      title: "TODAY'S MEDICINES",
                      actionLabel: 'See all',
                      onAction: widget.onNavigateToMedicines,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap any dose to toggle taken / pending status',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (widget.medicines.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppSpacing.roundedXl,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'No medications scheduled for today.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.medicines.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final medicine = widget.medicines[index];
                          return MedicineListTile(
                            medicine: medicine,
                            onToggleStatus: () =>
                                widget.onToggleStatus(medicine),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => MedicineDetailsScreen(
                                    medicine: medicine,
                                    onToggleStatus: widget.onToggleStatus,
                                    onToggleEnabled: widget.onToggleEnabled,
                                    onUpdateMedicine: widget.onUpdateMedicine,
                                    onDeleteMedicine: widget.onDeleteMedicine,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),

              // Bottom padding so content does not collide with navigation bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
  }
}

/// Horizontal compact card for upcoming doses carousel (fixed height, snap-free)
class _UpcomingHorizontalCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTake;
  final VoidCallback? onTap;

  const _UpcomingHorizontalCard({
    required this.medicine,
    required this.onTake,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 195,
      decoration: BoxDecoration(
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedXl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedXl,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusPendingBg,
                          borderRadius: AppSpacing.roundedPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: AppColors.statusPending,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                medicine.scheduledTime,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.statusPending,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: AppColors.statusTakenBg,
                      borderRadius: AppSpacing.roundedPill,
                      child: InkWell(
                        onTap: onTake,
                        borderRadius: AppSpacing.roundedPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          child: const Text(
                            'Take',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sageDeep,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      medicine.dosage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
