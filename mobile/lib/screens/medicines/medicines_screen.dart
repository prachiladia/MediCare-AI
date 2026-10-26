import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/medicine_list_tile.dart';
import 'add_medicine_screen.dart';
import 'medicine_details_screen.dart';

/// Screen displaying the full list of medications with category filters,
/// detailed inspection, and in-memory management controls.
class MedicinesScreen extends StatefulWidget {
  final List<Medicine> medicines;
  final Function(Medicine) onToggleStatus;
  final Function(Medicine) onAddMedicine;
  final Function(Medicine)? onUpdateMedicine;
  final Function(String)? onDeleteMedicine;
  final Function(Medicine, bool)? onToggleEnabled;

  const MedicinesScreen({
    super.key,
    required this.medicines,
    required this.onToggleStatus,
    required this.onAddMedicine,
    this.onUpdateMedicine,
    this.onDeleteMedicine,
    this.onToggleEnabled,
  });

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  String _selectedFilter = 'All';

  List<Medicine> get _filteredMedicines {
    switch (_selectedFilter) {
      case 'Active':
        return widget.medicines.where((m) => m.isEnabled).toList();
      case 'Paused':
        return widget.medicines.where((m) => !m.isEnabled).toList();
      case 'Taken':
        return widget.medicines.where((m) => m.isTaken).toList();
      case 'Pending':
        return widget.medicines.where((m) => m.isPending).toList();
      case 'All':
      default:
        return widget.medicines;
    }
  }

  void _openDetails(Medicine med) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicineDetailsScreen(
          medicine: med,
          onToggleStatus: widget.onToggleStatus,
          onToggleEnabled: widget.onToggleEnabled,
          onUpdateMedicine: widget.onUpdateMedicine,
          onDeleteMedicine: widget.onDeleteMedicine,
        ),
      ),
    );
  }

  void _openAddMedicine() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          onMedicineAdded: (newMed) async {
            widget.onAddMedicine(newMed);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('My Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Medicine',
            onPressed: _openAddMedicine,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoDataBanner(
                text: 'In-Memory Prototype • All changes reset when app restarts • Tap a medicine for details',
              ),
              const SizedBox(height: AppSpacing.lg),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Active', 'Paused', 'Pending', 'Taken'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: AppColors.blush,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.forest
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedPill,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.sageDeep
                                : AppColors.border,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Medicines List
              if (_filteredMedicines.isEmpty)
                EmptyStateCard(
                  title: 'No medicines found',
                  message: 'No medicines match the selected "$_selectedFilter" filter.',
                  icon: Icons.medication_outlined,
                  actionLabel: 'Add a medicine',
                  onAction: _openAddMedicine,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredMedicines.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final med = _filteredMedicines[index];
                    return MedicineListTile(
                      medicine: med,
                      onToggleStatus: () => widget.onToggleStatus(med),
                      onTap: () => _openDetails(med),
                    );
                  },
                ),

              const SizedBox(height: AppSpacing.xxl),

              // Smart Pill Identifier Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.sageDeep,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smart Pill Identifier Coming Soon',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AI-assisted photo scanning and pharmacy sync will be enabled in future releases.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
