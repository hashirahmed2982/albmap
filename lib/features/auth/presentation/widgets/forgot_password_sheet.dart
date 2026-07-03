import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/repositories/auth_repository.dart';

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final result = await sl<AuthRepository>().forgotPassword(email: _emailController.text.trim());
    setState(() {
      _isLoading = false;
      _sent = result.isRight();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reset your password', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          if (_sent)
            const Text('Check your email for a password reset link.', style: AppTextStyles.bodyMedium)
          else ...[
            Text('Enter the email associated with your account.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Send reset link', isLoading: _isLoading, onPressed: _submit),
          ],
        ],
      ),
    );
  }
}
