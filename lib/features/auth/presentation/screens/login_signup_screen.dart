import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/forgot_password_sheet.dart';

/// 2. Login / Sign Up Screen
/// Toggles between login and sign-up modes, supports guest continuation,
/// forgot-password, and social login entry points.
class LoginSignUpScreen extends ConsumerStatefulWidget {
  const LoginSignUpScreen({super.key});

  @override
  ConsumerState<LoginSignUpScreen> createState() => _LoginSignUpScreenState();
}

class _LoginSignUpScreenState extends ConsumerState<LoginSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUpMode && !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.pleaseAcceptTerms'.tr())),
      );
      return;
    }

    final auth = ref.read(authControllerProvider.notifier);
    final bool success = _isSignUpMode
        ? await auth.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          )
        : await auth.login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    if (!success && mounted) {
      final error = ref.read(authControllerProvider).errorMessage;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error ?? 'common.somethingWrong'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.map_rounded, size: 38, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSignUpMode ? 'auth.createAccount'.tr() : 'auth.welcomeBack'.tr(),
                    style: AppTextStyles.h1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isSignUpMode ? 'auth.signupSubtitle'.tr() : 'auth.loginSubtitle'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isSignUpMode) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(labelText: 'auth.fullName'.tr()),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'auth.nameRequired'.tr() : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: 'auth.email'.tr()),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'auth.emailRequired'.tr();
                              if (!v.contains('@')) return 'auth.emailInvalid'.tr();
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'auth.password'.tr(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'auth.passwordRequired'.tr();
                              if (v.length < 6) return 'auth.passwordTooShort'.tr();
                              return null;
                            },
                          ),
                          if (!_isSignUpMode) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => const ForgotPasswordSheet(),
                                ),
                                child: Text('auth.forgotPassword'.tr()),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _acceptedTerms,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text('auth.acceptTerms'.tr(), style: AppTextStyles.bodySmall),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: _isSignUpMode ? 'auth.signUp'.tr() : 'auth.logIn'.tr(),
                            isLoading: authState.isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('auth.or'.tr(), style: AppTextStyles.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),

                  PrimaryButton(
                    label: 'auth.continueWithGoogle'.tr(),
                    outlined: true,
                    icon: Icons.g_mobiledata,
                    onPressed: () {}, // wire google_sign_in package
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'auth.continueWithFacebook'.tr(),
                    outlined: true,
                    icon: Icons.facebook,
                    onPressed: () {}, // wire facebook auth
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'auth.continueAsGuest'.tr(),
                    outlined: true,
                    icon: Icons.person_outline,
                    onPressed: () => ref.read(authControllerProvider.notifier).continueAsGuest(),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                      child: Text(
                        _isSignUpMode ? 'auth.alreadyHaveAccount'.tr() : 'auth.noAccount'.tr(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
