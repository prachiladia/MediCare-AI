import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/dose_occurrence.dart';
import '../models/medicine.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/repository_manager.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'history/history_screen.dart';
import 'home/home_screen.dart';
import 'medicines/medicines_screen.dart';
import 'profile/profile_screen.dart';

/// The root shell container holding the Material 3 NavigationBar and preserving
/// state across tabs using an IndexedStack.
///
/// Backed by [MedicineRepository] (defaults to in-memory implementation).
/// Constrains the application content to a maximum width of 480px centered on wide
/// screens (desktop web) while filling the full viewport on mobile devices.
class MainShell extends StatefulWidget {
  final MedicineRepository? repository;

  const MainShell({super.key, this.repository});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final MedicineRepository _repository;
  List<Medicine> _medicines = [];
  List<DoseOccurrence> _occurrences = [];
  AppUser? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = widget.repository ?? RepositoryManager.instance;
    _loadMedicines();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.medicineResolver = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMedicines();
    }
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isOffline = false;
    });

    try {
      // Reconcile missed doses on start and resume (Phase 7)
      await _repository.reconcileMissedDoses();

      final list = await _repository.getMedicines();
      final occs = await _repository.getOccurrences(todayOnly: true);
      final user = await _repository.getUserProfile();
      if (mounted) {
        setState(() {
          _medicines = list;
          _occurrences = occs;
          _user = user;
          _isLoading = false;
          _errorMessage = null;
          _isOffline = false;
        });

        // Cancel previous reminders to ensure clean slate across user account sessions
        await NotificationService().cancelAllReminders();

        // Register live medicine lookup for notification payload routing
        NotificationService.medicineResolver = (id) {
          for (final m in _medicines) {
            if (m.id == id) return m;
          }
          return null;
        };

        // Reschedule active alarms for current user's enabled medications
        for (final med in list) {
          if (med.isEnabled && med.isActive) {
            await NotificationService().scheduleMedicineReminders(med);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        final isOffline = errStr.contains('offline') ||
            errStr.contains('unavailable') ||
            errStr.contains('network') ||
            errStr.contains('failed-precondition');
        setState(() {
          _isLoading = false;
          _isOffline = isOffline;
          _errorMessage = isOffline
              ? 'Network offline. Using cached data if available.'
              : 'Failed to load medications: $e';
        });
      }
    }
  }

  Future<void> _toggleMedicineStatus(Medicine medicine) async {
    await _repository.toggleMedicineStatus(medicine.id);
    await _loadMedicines();

    final actionLabel =
        medicine.isTaken ? 'marked as pending' : 'marked as taken';
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${medicine.name} $actionLabel (in-memory demo)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleMedicineEnabled(Medicine medicine, bool isEnabled) async {
    await _repository.toggleMedicineEnabled(medicine.id, isEnabled);
    if (!isEnabled) {
      await NotificationService().cancelMedicineReminders(medicine);
    } else {
      await NotificationService()
          .scheduleMedicineReminders(medicine.copyWith(isEnabled: true));
    }
    await _loadMedicines();

    if (mounted) {
      final label = isEnabled ? 'resumed' : 'paused';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${medicine.name} reminders $label'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addMedicine(Medicine newMedicine) async {
    await _repository.addMedicine(newMedicine);
    final res =
        await NotificationService().scheduleMedicineReminders(newMedicine);
    if (!res.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder note: ${res.message}')),
      );
    }
    await _loadMedicines();
  }

  Future<void> _updateMedicine(Medicine updatedMedicine) async {
    Medicine? oldMed;
    for (final m in _medicines) {
      if (m.id == updatedMedicine.id) {
        oldMed = m;
        break;
      }
    }
    if (oldMed != null) {
      await NotificationService().cancelMedicineReminders(oldMed);
    }
    await _repository.updateMedicine(updatedMedicine);
    if (updatedMedicine.isEnabled && updatedMedicine.isActive) {
      final res = await NotificationService()
          .scheduleMedicineReminders(updatedMedicine);
      if (!res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder note: ${res.message}')),
        );
      }
    }
    await _loadMedicines();
  }

  Future<void> _deleteMedicine(String medicineId) async {
    Medicine? medToDelete;
    for (final m in _medicines) {
      if (m.id == medicineId) {
        medToDelete = m;
        break;
      }
    }
    if (medToDelete != null) {
      await NotificationService().cancelMedicineReminders(medToDelete);
    }
    await _repository.deleteMedicine(medicineId);
    await _loadMedicines();
  }

  Future<void> _handleDoseTaken(DoseOccurrence occurrence) async {
    try {
      await _repository.recordDoseTaken(occurrence.id);
      await _loadMedicines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emergency,
            content: Text('Could not mark taken: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleDoseSnooze(DoseOccurrence occurrence, int minutes) async {
    try {
      await _repository.recordDoseSnooze(occurrence.id, minutes);
      await _loadMedicines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emergency,
            content: Text('Could not snooze dose: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleDoseSkip(DoseOccurrence occurrence, String reason) async {
    try {
      await _repository.recordDoseSkipped(occurrence.id, reason);
      await _loadMedicines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emergency,
            content: Text('Could not skip dose: $e'),
          ),
        );
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceWarm,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.border, width: 1),
              right: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Scaffold(
            backgroundColor: AppColors.cream,
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.sageDeep,
                    ),
                  )
                : _errorMessage != null && _medicines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isOffline
                                    ? Icons.wifi_off_rounded
                                    : Icons.cloud_off_rounded,
                                size: 56,
                                color: _isOffline
                                    ? AppColors.statusPending
                                    : AppColors.emergency,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                _isOffline ? 'Offline Mode' : 'Connection Error',
                                style: AppTextStyles.heroMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.sageDeep,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Try Again'),
                                onPressed: _loadMedicines,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          if (_isOffline || _errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: _isOffline
                                  ? AppColors.statusPendingBg
                                  : AppColors.emergencyBg,
                              child: Row(
                                children: [
                                  Icon(
                                    _isOffline
                                        ? Icons.wifi_off_rounded
                                        : Icons.error_outline_rounded,
                                    size: 16,
                                    color: _isOffline
                                        ? AppColors.statusPending
                                        : AppColors.emergency,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage ??
                                          'Offline: changes will sync when reconnected',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _isOffline
                                            ? AppColors.forest
                                            : AppColors.emergency,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _loadMedicines,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        'Retry',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.sageDeep,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: IndexedStack(
                              index: _currentIndex,
                              children: [
                                HomeScreen(
                                  medicines: _medicines,
                                  occurrences: _occurrences,
                                  repository: _repository,
                                  user: _user,
                                  onToggleStatus: _toggleMedicineStatus,
                                  onAddMedicine: _addMedicine,
                                  onUpdateMedicine: _updateMedicine,
                                  onDeleteMedicine: _deleteMedicine,
                                  onToggleEnabled: _toggleMedicineEnabled,
                                  onTakeOccurrence: _handleDoseTaken,
                                  onSnoozeOccurrence: _handleDoseSnooze,
                                  onSkipOccurrence: _handleDoseSkip,
                                  onNavigateToHistory: () => _onTabSelected(2),
                                  onNavigateToMedicines: () => _onTabSelected(1),
                                  onNavigateToProfile: () => _onTabSelected(3),
                                ),
                                MedicinesScreen(
                                  medicines: _medicines,
                                  onToggleStatus: _toggleMedicineStatus,
                                  onAddMedicine: _addMedicine,
                                  onUpdateMedicine: _updateMedicine,
                                  onDeleteMedicine: _deleteMedicine,
                                  onToggleEnabled: _toggleMedicineEnabled,
                                ),
                                HistoryScreen(
                                  occurrences: _occurrences,
                                  repository: _repository,
                                ),
                                ProfileScreen(
                                  repository: _repository,
                                  onProfileUpdated: (updated) {
                                    if (mounted) {
                                      setState(() {
                                        _user = updated;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.medication_outlined),
                    selectedIcon: Icon(Icons.medication_rounded),
                    label: 'Medicines',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'History',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
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
