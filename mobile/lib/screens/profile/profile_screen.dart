import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/caregiver.dart';
import '../../repositories/medicine_repository.dart';
import '../../repositories/repository_manager.dart';
import '../../services/auth_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/greeting_helper.dart';
import '../../widgets/demo_data_banner.dart';

/// Screen displaying the user's profile, emergency contact card, and health preferences.
class ProfileScreen extends StatefulWidget {
  final MedicineRepository? repository;
  final Function(AppUser?)? onProfileUpdated;

  const ProfileScreen({super.key, this.repository, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _remindersEnabled = true;
  bool _soundEnabled = true;
  CaregiverInfo? _caregiver;
  AppUser? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = widget.repository ?? RepositoryManager.instance;
      final caregiver = await repo.getCaregiverInfo();
      final user = await repo.getUserProfile() ?? AuthManager.instance.currentUser;
      if (mounted) {
        setState(() {
          _caregiver = caregiver;
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load profile: $e';
        });
      }
    }
  }

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _user?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your name',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageDeep,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        final repo = widget.repository ?? RepositoryManager.instance;
        await repo.updateUserProfile(name: newName);
        final updatedUser = await repo.getUserProfile();
        if (mounted) {
          setState(() {
            _user = updatedUser;
          });
          widget.onProfileUpdated?.call(updatedUser);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile name updated'),
              backgroundColor: AppColors.sageDeep,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update name: $e'),
              backgroundColor: AppColors.emergency,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = AuthManager.instance.isDemoMode || _user?.isDemoUser == true;
    final resolvedName = GreetingHelper.resolveDisplayName(
      user: _user,
      isDemo: isDemo,
    );
    final displayName = resolvedName ?? (isDemo ? 'Demo User' : 'No name set');
    final email = _user?.email.trim().isNotEmpty == true
        ? _user!.email.trim()
        : (isDemo ? 'demo@medicare.ai' : '');
    final initials = GreetingHelper.getInitials(resolvedName);

    final caregiverName = _caregiver?.name.trim().isNotEmpty == true
        ? _caregiver!.name.trim()
        : 'Dr. Sarah Jenkins';
    final caregiverSubtitle = _caregiver != null && _caregiver!.relationship.isNotEmpty
        ? '${_caregiver!.relationship} • ${_caregiver!.phone}'
        : 'Primary Care Physician • +1 (555) 019-2834';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'App Settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.sageDeep),
              )
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
                            onPressed: _loadProfile,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DemoDataBanner(
                          text: isDemo
                              ? 'Profile preview • In-memory demo mode'
                              : 'Connected to Cloud • Synced with Firebase',
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Profile Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppSpacing.rounded2xl,
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppSpacing.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.blush,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: initials.isNotEmpty
                                      ? Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.forest,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_rounded,
                                          size: 32,
                                          color: AppColors.forest,
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: _showEditNameDialog,
                                      borderRadius: AppSpacing.roundedSm,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                displayName,
                                                style: AppTextStyles.titleLarge,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Tooltip(
                                              message: 'Edit Name',
                                              child: Icon(
                                                Icons.edit_outlined,
                                                size: 20,
                                                color: AppColors.sageDeep,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (email.isNotEmpty)
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDemo
                                            ? AppColors.blush
                                            : AppColors.statusTakenBg,
                                        borderRadius: AppSpacing.roundedPill,
                                      ),
                                      child: Text(
                                        isDemo
                                            ? 'Patient ID: MC-90412 (Demo)'
                                            : 'Status: Cloud Synced (Active)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isDemo
                                              ? AppColors.forest
                                              : AppColors.sageDeep,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Emergency Contact Section
                        const Text(
                          'EMERGENCY CONTACTS',
                          style: AppTextStyles.eyebrow,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Material(
                          color: AppColors.surface,
                          borderRadius: AppSpacing.roundedLg,
                          child: InkWell(
                            onTap: () =>
                                Navigator.of(context).pushNamed('/caregiver'),
                            borderRadius: AppSpacing.roundedLg,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                borderRadius: AppSpacing.roundedLg,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: AppColors.emergencyBg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.contact_phone_rounded,
                                          color: AppColors.emergency,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              caregiverName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: AppColors.forest,
                                              ),
                                            ),
                                            Text(
                                              caregiverSubtitle,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Tap to configure caregiver settings',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.sageDeep,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

              const SizedBox(height: AppSpacing.xxl),

              // Preferences Section
              const Text(
                'PREFERENCES & COMPANION SETTINGS',
                style: AppTextStyles.eyebrow,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppSpacing.cardShadow,
                ),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.roundedLg,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _remindersEnabled,
                        activeThumbColor: AppColors.sageDeep,
                        title: const Text(
                          'Reminder Notifications (Demo)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forest,
                          ),
                        ),
                        subtitle: const Text(
                          'Actual scheduling activates in Phase 5',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        onChanged: (val) {
                          setState(() => _remindersEnabled = val);
                        },
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      SwitchListTile(
                        value: _soundEnabled,
                        activeThumbColor: AppColors.sageDeep,
                        title: const Text(
                          'Alert Sounds (Demo)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forest,
                          ),
                        ),
                        subtitle: const Text(
                          'Gentle chime on reminder times',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        onChanged: (val) {
                          setState(() => _soundEnabled = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Sign Out Action
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emergency,
                    side: const BorderSide(color: AppColors.emergency),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedLg,
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out?'),
                        content: const Text(
                          'Signing out cancels scheduled reminder alerts and returns you to the login screen.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emergency,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await SessionManager.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // About Project & Disclaimer
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
                    const Text(
                      'MediCare AI – Health Companion Prototype',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Intelligent Medicine Reminder & Health Companion.\n"Never Miss a Dose. Stay Healthy. Stay Connected."\nVersion 1.0.0 (Phase 1 Shell)\n\nDemonstration mode: Firebase, push notifications, and telephony are inactive.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
