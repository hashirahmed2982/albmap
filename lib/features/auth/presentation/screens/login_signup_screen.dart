import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/forgot_password_sheet.dart';

/// 2. Login / Sign Up Screen — "Bold Editorial" redesign (see
/// AlbMap_Design_Spec_Bold_Editorial.md + Login.png mockup): dark
/// background, serif "AlbMap" wordmark, an underline tab toggle between
/// Hyr/Regjistrohu (replacing the old bottom "Already have an account?"
/// link as the primary way to switch modes), sharp-cornered bordered
/// inputs/buttons, and a persistent Terms/Privacy footer disclaimer.
///
/// Sign-up itself is two steps — submitting the form only emails a code
/// (see AuthController.requestSignup); [_isVerifyingOtp] switches this
/// same screen into a third mode to collect that code, which is what
/// actually creates the account (AuthController.verifySignupOtp). The
/// GoRouter redirect (app_router.dart) reactively navigates away once
/// that succeeds and authState.isAuthenticated becomes true — this
/// screen never navigates itself, for signup or login.
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
  final _otpController = TextEditingController();

  bool _isSignUpMode = false;
  bool _isVerifyingOtp = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _isResending = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUpMode && !_isVerifyingOtp && !_acceptedTerms) {
      AppToast.warning(context, 'auth.pleaseAcceptTerms'.tr());
      return;
    }

    final auth = ref.read(authControllerProvider.notifier);
    final bool success;
    if (_isVerifyingOtp) {
      success = await auth.verifySignupOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );
    } else if (_isSignUpMode) {
      success = await auth.requestSignup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      if (success && mounted) {
        setState(() {
          _isVerifyingOtp = true;
          _otpController.clear();
        });
      }
    } else {
      success = await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!success && mounted) {
      final error = ref.read(authControllerProvider).errorMessage;
      AppToast.error(context, error ?? 'common.somethingWrong'.tr());
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    final auth = ref.read(authControllerProvider.notifier);
    final bool success = await auth.requestSignup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isResending = false);
    if (success) {
      AppToast.success(context, 'auth.codeResent'.tr());
    } else {
      final error = ref.read(authControllerProvider).errorMessage;
      AppToast.error(context, error ?? 'common.somethingWrong'.tr());
    }
  }

  Future<void> _handleSocialLogin(Future<bool> Function() signInMethod) async {
    final bool success = await signInMethod();
    if (!mounted) return;
    if (!success) {
      final error = ref.read(authControllerProvider).errorMessage;
      // "Sign-in cancelled" (user backed out of the picker) surfaces the
      // same way as a real failure here — deliberately not special-cased
      // into silence, since a brief, accurate toast is simple and honest,
      // and cancelling isn't something that needs hiding.
      AppToast.error(context, error ?? 'common.somethingWrong'.tr());
    }
  }

  void _switchMode(bool signUp) {
    if (_isVerifyingOtp) return; // don't let a stray tap escape the OTP step
    setState(() => _isSignUpMode = signUp);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Text('AlbMap', style: AppTextStyles.h1.copyWith(fontSize: 36), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'auth.tagline'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              if (!_isVerifyingOtp) _ModeTabToggle(isSignUpMode: _isSignUpMode, onChanged: _switchMode),
              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isVerifyingOtp) ...[
                      Text(
                        'auth.verifyEmailSubtitle'.tr(namedArgs: {'email': _emailController.text.trim()}),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2.copyWith(letterSpacing: 8),
                        decoration: InputDecoration(labelText: 'auth.verificationCode'.tr(), counterText: ''),
                        validator: (v) => Validators.otp(
                          v,
                          requiredMessage: 'auth.otpRequired'.tr(),
                          invalidMessage: 'auth.otpInvalid'.tr(),
                        ),
                      ),
                    ] else ...[
                      if (_isSignUpMode) ...[
                        _FieldLabel('auth.fullName'.tr()),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          maxLength: 150,
                          decoration: const InputDecoration(counterText: ''),
                          validator: (v) => Validators.required(v, 'auth.nameRequired'.tr()),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _FieldLabel('auth.email'.tr()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 255,
                        decoration: InputDecoration(
                          hintText: 'auth.emailHint'.tr(),
                          prefixIcon: const Icon(Icons.mail_outline, size: 20),
                          counterText: '',
                        ),
                        validator: (v) => Validators.email(
                          v,
                          requiredMessage: 'auth.emailRequired'.tr(),
                          invalidMessage: 'auth.emailInvalid'.tr(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('auth.password'.tr()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        maxLength: 72,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          counterText: '',
                        ),
                        validator: (v) => Validators.password(
                          v,
                          requiredMessage: 'auth.passwordRequired'.tr(),
                          tooShortMessage: 'auth.passwordTooShort'.tr(),
                        ),
                      ),
                      if (!_isSignUpMode) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => const ForgotPasswordSheet(),
                            ),
                            child: Text(
                              'auth.forgotPassword'.tr(),
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
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
                    ],
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _isVerifyingOtp
                          ? 'auth.verifyButton'.tr()
                          : _isSignUpMode
                              ? 'auth.signUp'.tr()
                              : 'auth.logIn'.tr(),
                      isLoading: authState.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),

              if (_isVerifyingOtp) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isVerifyingOtp = false),
                      child: Text('auth.useAnotherEmail'.tr()),
                    ),
                    TextButton(
                      onPressed: _isResending ? null : _resendCode,
                      child: Text(_isResending ? 'common.loading'.tr() : 'auth.resendCode'.tr()),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('auth.or'.tr(), style: AppTextStyles.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                _SocialLoginButton(
                  label: 'auth.continueWithGoogle'.tr(),
                  badge: const Text('G', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  onPressed: () => _handleSocialLogin(
                    () => ref.read(authControllerProvider.notifier).loginWithGoogle(),
                  ),
                ),
                const SizedBox(height: 10),
                _SocialLoginButton(
                  label: 'auth.continueWithFacebook'.tr(),
                  badge: const Icon(Icons.facebook, size: 16),
                  onPressed: () => _handleSocialLogin(
                    () => ref.read(authControllerProvider.notifier).loginWithFacebook(),
                  ),
                ),
                const SizedBox(height: 10),
                // Sign in with Apple isn't wired up yet (separate task —
                // it needs its own Apple Developer Services ID + backend
                // token verification, not just this button). Shown here
                // to match the mockup visually; tapping surfaces an
                // honest "coming soon" rather than attempting a sign-in
                // that would silently fail.
                _SocialLoginButton(
                  label: 'auth.continueWithApple'.tr(),
                  badge: const Icon(Icons.apple, size: 18),
                  onPressed: () => AppToast.info(context, 'auth.appleSignInComingSoon'.tr()),
                ),

                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => ref.read(authControllerProvider.notifier).continueAsGuest(),
                    child: Text(
                      'auth.continueAsGuest'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _TermsFooter(
                  onTapTerms: () => context.push(AppRoutes.termsConditions),
                  onTapPrivacy: () => context.push(AppRoutes.privacyPolicy),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small uppercase field label ("EMAIL", "FJALËKALIMI") above each input —
/// the mockup labels fields this way instead of via InputDecoration's
/// floating label, which is why these are separate Text widgets rather
/// than a `labelText`.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }
}

/// Underline tab toggle between Login/Sign Up — replaces the old bottom
/// "Already have an account?" text link as the primary way to switch
/// modes, per the mockup. A true two-column tab bar: each tab takes
/// exactly half the width with a centered label, and the underline below
/// it spans that same half — red and full-weight for the active tab, a
/// thin muted line for the inactive one — matching the mockup exactly
/// (not a text-hugging underline with a separate trailing divider).
class _ModeTabToggle extends StatelessWidget {
  const _ModeTabToggle({required this.isSignUpMode, required this.onChanged});
  final bool isSignUpMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TabLabel(text: 'auth.logIn'.tr(), selected: !isSignUpMode, onTap: () => onChanged(false))),
        Expanded(child: _TabLabel(text: 'auth.signUp'.tr(), selected: isSignUpMode, onTap: () => onChanged(true))),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              text,
              textAlign: TextAlign.center,
              // Active tab reads white/bold (not red) in the mockup — the
              // red is reserved for the underline beneath it.
              style: AppTextStyles.h3.copyWith(color: selected ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
          Container(
            height: selected ? 2.5 : 1.5,
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ],
      ),
    );
  }
}

/// Outlined social-login button with a small circular icon badge on the
/// left, matching the mockup — deliberately a screen-local widget rather
/// than a change to the shared PrimaryButton, which several other
/// screens also use with `outlined: true` for buttons that don't have
/// this badge treatment.
class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({required this.label, required this.badge, required this.onPressed});
  final String label;
  final Widget badge;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderStrong, width: 1.5),
              ),
              child: DefaultTextStyle(
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                child: IconTheme(
                  data: const IconThemeData(color: AppColors.textPrimary),
                  child: badge,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "By continuing you agree to our Terms & Conditions and our Privacy
/// Policy." with the two policy names as tappable red links — persistent
/// under the guest/social options on both Login and Sign Up, distinct
/// from the sign-up-only "I accept..." checkbox above (that one gates
/// actually submitting the sign-up form; this is a general disclaimer
/// shown regardless of mode, per the mockup).
class _TermsFooter extends StatelessWidget {
  const _TermsFooter({required this.onTapTerms, required this.onTapPrivacy});
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.caption.copyWith(color: AppColors.textSecondary);
    final linkStyle = baseStyle.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: 'auth.footerAgreementPrefix'.tr()),
          TextSpan(text: 'aboutUs.terms'.tr(), style: linkStyle, recognizer: TapGestureRecognizer()..onTap = onTapTerms),
          TextSpan(text: 'auth.footerAgreementMiddle'.tr()),
          TextSpan(text: 'aboutUs.privacyPolicy'.tr(), style: linkStyle, recognizer: TapGestureRecognizer()..onTap = onTapPrivacy),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
