import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/demo_data_banner.dart';

/// Registration screen for MediCare AI.
///
/// Implements full client-side validation (name, email, password, confirm match),
/// blush/cream styling, washi-tape accent, and returns to Login upon completion.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthManager.instance.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.sageDeep,
          content: Text('Account registered in demonstration mode! Welcome!'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushReplacementNamed('/home');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emergency,
          content: Text(e.message),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emergency,
          content: Text('Registration failed. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tape Accent Strip
                    Transform.rotate(
                      angle: -0.02,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tapeBlush,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'JOIN MEDICARE AI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const Text(
                      'START YOUR\nHEALTH COMPANION',
                      style: AppTextStyles.heroLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Never miss another scheduled dose. Free college prototype.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const DemoDataBanner(
                      text: 'Demo Mode • Cloud account registration connects in Phase 9',
                    ),
                    const SizedBox(height: AppSpacing.xl),

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
                            'Full Name',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.forest),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Jane Doe',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          const Text(
                            'Email Address',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.forest),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'name@example.com',
                              prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                            ),
                            validator: (val) {
                              final trimmed = val?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return 'Email address is required';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(trimmed)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          const Text(
                            'Password',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.forest),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Create password (min 6 chars)',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          const Text(
                            'Confirm Password',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.forest),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            decoration: const InputDecoration(
                              hintText: 'Re-enter your password',
                              prefixIcon: Icon(Icons.lock_reset_rounded, color: AppColors.textSecondary),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (val != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          AppPrimaryButton(
                            label: 'Register Account',
                            isLoading: _isLoading,
                            onPressed: _handleRegister,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Back to login
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Already registered?',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sageDeep,
                            ),
                          ),
                        ),
                      ],
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
