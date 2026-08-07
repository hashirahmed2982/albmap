import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

/// Confirmation flow for permanently deleting the signed-in account —
/// App Store Guideline 5.1.1(v) requires any app that supports in-app
/// account creation to also support in-app account deletion.
///
/// The password field is optional rather than conditionally shown:
/// [UserEntity] has no field telling the client whether this account has
/// a password set at all (a Google/Facebook-only account doesn't). Rather
/// than plumb an `authProvider` flag end-to-end just to hide/show one
/// field, this always shows it — a password-auth account that leaves it
/// blank gets the backend's "Password is required..." error back as a
/// normal toast, and a social-only account can just leave it blank and
/// proceed, since the backend only asks for a password when the account
/// actually has one to confirm.
class DeleteAccountSheet extends ConsumerStatefulWidget {
  const DeleteAccountSheet({super.key});

  @override
  ConsumerState<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<DeleteAccountSheet> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    final String password = _passwordController.text;
    final String? error = await ref.read(authControllerProvider.notifier).deleteAccount(
          password: password.isEmpty ? null : password,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _isLoading = false);
      AppToast.error(context, error);
      return;
    }
    // Account + local session are gone — the router's redirect (it watches
    // authControllerProvider) takes over from here and sends the user to
    // the welcome/login flow on its own, so just close the sheet.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('profile.deleteAccountTitle'.tr(), style: AppTextStyles.h3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('profile.deleteAccountWarning'.tr(), style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            enabled: !_isLoading,
            maxLength: 72,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              labelText: 'profile.deleteAccountPasswordLabel'.tr(),
              helperText: 'profile.deleteAccountPasswordHelper'.tr(),
              helperMaxLines: 2,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.error.withValues(alpha: 0.6),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Text('profile.deleteAccountConfirm'.tr()),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'common.cancel'.tr(),
            outlined: true,
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
