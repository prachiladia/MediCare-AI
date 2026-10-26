import 'package:flutter/material.dart';
import '../../models/caregiver.dart';
import '../../repositories/medicine_repository.dart';
import '../../repositories/repository_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/section_eyebrow.dart';

/// Caregiver Information and Notification settings screen.
///
/// Phase 8 Specifications:
/// - Editable caregiver profile (Name, Relationship, Phone, Email) with format validation.
/// - Data stored through [MedicineRepository] with prominent in-memory disclaimer.
/// - Demonstrates the 3-consecutive-misses escalation rule.
/// - IN-APP alert labeled explicitly: "In-app demo alert. No SMS, call or email was sent."
/// - Chronological check: Taken or Skipped strictly resets the streak.
class CaregiverScreen extends StatefulWidget {
  final MedicineRepository? repository;

  const CaregiverScreen({super.key, this.repository});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final _formKey = GlobalKey<FormState>();
  late final MedicineRepository _repository;

  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _notifyOnThreeMisses = true;

  bool _isLoading = true;
  bool _isSaving = false;
  int _consecutiveMissedCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? RepositoryManager.instance;
    _loadCaregiverData();
  }

  Future<void> _loadCaregiverData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final info = await _repository.getCaregiverInfo();
      final streak = await _repository.getConsecutiveMissedCount();
      if (mounted) {
        setState(() {
          _nameController.text = info.name;
          _relationshipController.text = info.relationship;
          _phoneController.text = info.phone;
          _emailController.text = info.email;
          _notifyOnThreeMisses = info.alertOnThreeMisses;
          _consecutiveMissedCount = streak;
          _isLoading = false;
        });

        // Automatically show demo alert if streak threshold reached
        if (streak >= 3 && info.alertOnThreeMisses) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showConsecutiveMissedAlert(isAutomated: true);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load caregiver settings: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    final info = CaregiverInfo(
      name: _nameController.text.trim(),
      relationship: _relationshipController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      alertOnThreeMisses: _notifyOnThreeMisses,
    );

    try {
      await _repository.updateCaregiverInfo(info);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.sageDeep,
            content: Text(
              'Caregiver details saved in repository (in-memory demo).',
              style: TextStyle(color: Colors.white),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emergency,
            content: Text('Error saving caregiver info: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showConsecutiveMissedAlert({bool isAutomated = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.emergency, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Caregiver Escalation Alert',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emergency,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.emergencyBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.emergency.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'In-app demo alert. No SMS, call or email was sent.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emergency,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAutomated
                  ? 'CRITICAL REMINDER: You have $_consecutiveMissedCount consecutive missed doses recorded in your schedule.'
                  : 'PROTOTYPE SIMULATION: 3 consecutive missed doses were detected.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'In a production environment, an automated escalation alert would be dispatched to your designated caregiver:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text('• Caregiver: ${_nameController.text.trim()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('• Relationship: ${_relationshipController.text.trim()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('• Phone: ${_phoneController.text.trim()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('• Email: ${_emailController.text.trim()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
              'Taking or skipping the next dose will immediately reset this escalation streak.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Dismiss Simulation',
              style: TextStyle(color: AppColors.sageDeep, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Caregiver Support'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.sageDeep))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: AppColors.emergency,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.sageDeep,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Try Again'),
                                onPressed: _loadCaregiverData,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DemoDataBanner(
                            text: 'In-memory demo • External SMS/telephony is simulated only',
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Consecutive Missed Streak Status Card
                          if (_consecutiveMissedCount > 0) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: _consecutiveMissedCount >= 3
                                    ? AppColors.emergencyBg
                                    : AppColors.statusPendingBg,
                                borderRadius: AppSpacing.roundedLg,
                                border: Border.all(
                                  color: _consecutiveMissedCount >= 3
                                      ? AppColors.emergency
                                      : AppColors.statusPending,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _consecutiveMissedCount >= 3
                                        ? Icons.warning_rounded
                                        : Icons.info_outline_rounded,
                                    color: _consecutiveMissedCount >= 3
                                        ? AppColors.emergency
                                        : AppColors.statusPending,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Current consecutive missed streak: $_consecutiveMissedCount dose(s).'
                                      '${_consecutiveMissedCount >= 3 ? " Escalation threshold reached." : " (Resets on next Taken/Skipped)"}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _consecutiveMissedCount >= 3
                                            ? AppColors.emergency
                                            : AppColors.forest,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          const SectionEyebrow(title: 'PRIMARY CAREGIVER DETAILS'),
                          const SizedBox(height: AppSpacing.sm),

                          // Inputs Card
                          Container(
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
                                const Text(
                                  'Caregiver Name',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Dr. Sarah Jenkins, Mom, John',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  validator: CaregiverInfo.validateName,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                const Text(
                                  'Relationship',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _relationshipController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Physician, Daughter, Spouse',
                                    prefixIcon: Icon(
                                      Icons.family_restroom_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  validator: CaregiverInfo.validateRelationship,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                const Text(
                                  'Phone Number',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    hintText: '+1 (555) 000-0000',
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  validator: CaregiverInfo.validatePhone,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                const Text(
                                  'Email Address',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: 'caregiver@example.com',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  validator: CaregiverInfo.validateEmail,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          const SectionEyebrow(title: 'AUTOMATIC ESCALATION RULE'),
                          const SizedBox(height: AppSpacing.sm),

                          // 3-Consecutive Misses Escalation Card
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: AppSpacing.roundedXl,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Material(
                              color: AppColors.surface,
                              borderRadius: AppSpacing.roundedXl,
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: SwitchListTile(
                                  value: _notifyOnThreeMisses,
                                  activeThumbColor: AppColors.sageDeep,
                                  title: const Text(
                                    'Alert on 3 Consecutive Misses',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Triggers an urgent in-app alert when 3 scheduled doses are missed in a row.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  onChanged: (val) =>
                                      setState(() => _notifyOnThreeMisses = val),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          AppPrimaryButton(
                            label: _isSaving ? 'Saving...' : 'Save Caregiver Info',
                            icon: Icons.check_rounded,
                            onPressed: _isSaving ? null : _handleSave,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          AppSecondaryButton(
                            label: 'Simulate 3-Misses Alert (Demo)',
                            icon: Icons.notifications_active_outlined,
                            onPressed: () => _showConsecutiveMissedAlert(isAutomated: false),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
