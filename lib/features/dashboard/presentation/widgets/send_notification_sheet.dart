import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../providers/send_notification_provider.dart';

/// Compose sheet for broadcasting an offer/announcement from a business
/// owner. See send_notification_provider.dart for the important caveat
/// about mock/offline delivery only reaching the sender's own device.
class SendNotificationSheet extends ConsumerStatefulWidget {
  const SendNotificationSheet({required this.business, super.key});
  final BusinessEntity business;

  @override
  ConsumerState<SendNotificationSheet> createState() => _SendNotificationSheetState();
}

class _SendNotificationSheetState extends ConsumerState<SendNotificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final errorMessage = await ref.read(sendBusinessNotificationControllerProvider.notifier).send(
          businessId: widget.business.id,
          businessName: widget.business.name,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
        );
    if (errorMessage == null) {
      setState(() => _sent = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sendState = ref.watch(sendBusinessNotificationControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _sent ? _buildSentState(context) : _buildForm(context, sendState),
    );
  }

  Widget _buildForm(BuildContext context, AsyncValue<void> sendState) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.campaign_outlined, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('sendNotification.title'.tr(), style: AppTextStyles.h3),
                    Text('sendNotification.forBusiness'.tr(args: [widget.business.name]), style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleController,
            maxLength: 60,
            decoration: InputDecoration(labelText: 'sendNotification.titleLabel'.tr(), hintText: 'sendNotification.titleHint'.tr()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
          ),
          TextFormField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(labelText: 'sendNotification.message'.tr()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'sendNotification.disclaimer'.tr(),
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'sendNotification.send'.tr(),
            isLoading: sendState.isLoading,
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildSentState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
        ),
        const SizedBox(height: 16),
        Text('sendNotification.sentTitle'.tr(), style: AppTextStyles.h3),
        const SizedBox(height: 6),
        Text('sendNotification.sentBody'.tr(), style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        PrimaryButton(label: 'common.done'.tr(), onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
