import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Fixes a real gap: this tile previously did nothing (onTap: () {}) —
/// there was no way for a returning user to change their password
/// in-app, ever.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentController.text == _newController.text) {
      AppToast.warning(context, 'changePassword.sameAsCurrent'.tr());
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await ref.read(authControllerProvider.notifier).changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      AppToast.error(context, error);
    } else {
      AppToast.success(context, 'changePassword.success'.tr());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientHeader(
                child: PageHeaderTitle(
                  title: 'changePassword.title'.tr(),
                  icon: Icons.lock_rounded,
                  accent: AppColors.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _currentController,
                        obscureText: _obscureCurrent,
                        maxLength: 72,
                        decoration: InputDecoration(
                          labelText: 'changePassword.current'.tr(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                        validator: (v) => Validators.required(v, 'common.required'.tr()),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _newController,
                        obscureText: _obscureNew,
                        maxLength: 72,
                        decoration: InputDecoration(
                          labelText: 'changePassword.newPassword'.tr(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        validator: (v) => Validators.password(
                          v,
                          requiredMessage: 'common.required'.tr(),
                          tooShortMessage: 'auth.passwordTooShort'.tr(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureNew,
                        maxLength: 72,
                        decoration: InputDecoration(labelText: 'changePassword.confirmNew'.tr()),
                        validator: (v) => Validators.confirmPassword(
                          v,
                          _newController.text,
                          requiredMessage: 'common.required'.tr(),
                          mismatchMessage: 'changePassword.mismatch'.tr(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'changePassword.action'.tr(),
                        isLoading: _isSubmitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
