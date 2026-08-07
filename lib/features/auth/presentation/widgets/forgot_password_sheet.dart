import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/repositories/auth_repository.dart';

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await sl<AuthRepository>().forgotPassword(email: _emailController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    result.fold(
      // Without this, a failed request (bad connection, unknown email,
      // server error) just quietly stopped the spinner — nothing told the
      // user it didn't work, so they'd sit there waiting for an email
      // that was never sent with no idea anything went wrong.
      (failure) => AppToast.error(context, failure.message),
      (_) => setState(() => _sent = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('auth.resetPasswordTitle'.tr(), style: AppTextStyles.h3),
            const SizedBox(height: 8),
            if (_sent)
              Text('auth.resetPasswordSent'.tr(), style: AppTextStyles.bodyMedium)
            else ...[
              Text('auth.resetPasswordSubtitle'.tr(), style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'auth.email'.tr()),
                validator: (v) => Validators.email(
                  v,
                  requiredMessage: 'auth.emailRequired'.tr(),
                  invalidMessage: 'auth.emailInvalid'.tr(),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'auth.sendResetLink'.tr(), isLoading: _isLoading, onPressed: _submit),
            ],
          ],
        ),
      ),
    );
  }
}
