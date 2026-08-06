import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/selection_field.dart';

/// 12. Contact Us Screen — support form + FAQ.
class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _inquiryType = 'general';
  bool _isSubmitting = false;

  // Keys map to contactUs.inquiryTypes.* translation entries — kept as
  // stable internal identifiers separate from the displayed (translated)
  // label, so switching language never changes what's actually submitted.
  static const List<String> _inquiryTypeKeys = ['general', 'businessSupport', 'bugReport', 'feedback'];

  String _inquiryTypeLabel(String key) => 'contactUs.inquiryTypes.$key'.tr();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    AppToast.success(context, 'contactUs.sent'.tr());
    _formKey.currentState!.reset();
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    setState(() => _inquiryType = 'general');
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
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(width: 4),
                    Text('contactUs.title'.tr(), style: AppTextStyles.h1),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(labelText: 'contactUs.name'.tr()),
                              validator: (v) => Validators.required(v, 'common.required'.tr()),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(labelText: 'contactUs.email'.tr()),
                              validator: (v) => Validators.email(
                                v,
                                requiredMessage: 'contactUs.validEmail'.tr(),
                                invalidMessage: 'contactUs.validEmail'.tr(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SelectionField<String>(
                              label: 'contactUs.inquiryType'.tr(),
                              selectedValue: _inquiryType,
                              options: [
                                for (final key in _inquiryTypeKeys)
                                  SelectionOption(value: key, label: _inquiryTypeLabel(key)),
                              ],
                              onChanged: (v) => setState(() => _inquiryType = v ?? 'general'),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _messageController,
                              maxLines: 5,
                              decoration: InputDecoration(labelText: 'contactUs.message'.tr()),
                              validator: (v) => Validators.required(v, 'common.required'.tr()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(label: 'contactUs.send'.tr(), isLoading: _isSubmitting, onPressed: _submit),
                      const SizedBox(height: 32),
                      Text('contactUs.faqTitle'.tr(), style: AppTextStyles.h3),
                      const SizedBox(height: 10),
                      _FaqTile(question: 'contactUs.faq1Q'.tr(), answer: 'contactUs.faq1A'.tr()),
                      _FaqTile(question: 'contactUs.faq2Q'.tr(), answer: 'contactUs.faq2A'.tr()),
                      _FaqTile(question: 'contactUs.faq3Q'.tr(), answer: 'contactUs.faq3A'.tr()),
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(question, style: AppTextStyles.bodyLarge),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        childrenPadding: const EdgeInsets.only(bottom: 14),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft, child: Text(answer, style: AppTextStyles.bodyMedium)),
          ),
        ],
      ),
    );
  }
}
