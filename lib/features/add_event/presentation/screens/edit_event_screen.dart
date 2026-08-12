import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/selection_field.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/domain/usecases/event_usecases.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../map/presentation/widgets/business_list_view.dart';

/// Edits an event the current user owns — name/description/category/date/
/// time/image only (the associated business is fixed once created, same
/// as it's not editable from Add Event either once picked).
///
/// Only reachable via an edit button My Events hides once an event has
/// finished (see my_events_screen.dart), but this re-checks that
/// server-side rule itself once loaded too — the event could finish
/// between opening My Events and tapping in, and the backend rejects the
/// PATCH either way (see event.service.js's updateEvent), so surfacing
/// that plainly up front is better than only discovering it after filling
/// out the whole form and submitting.
class EditEventScreen extends ConsumerStatefulWidget {
  const EditEventScreen({required this.eventId, super.key});
  final String eventId;

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String? _category;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _imageUrl;
  bool _isUploadingImage = false;

  EventEntity? _original;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final useCase = sl<GetEventDetailsUseCase>();
    final result = await useCase(widget.eventId);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _isLoading = false),
      (event) => setState(() {
        _original = event;
        _nameController.text = event.name;
        _descController.text = event.description;
        _category = event.category;
        _startDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
        _startTime = TimeOfDay.fromDateTime(event.startTime);
        _endTime = TimeOfDay.fromDateTime(event.endTime);
        _imageUrl = event.imageUrl;
        _isLoading = false;
      }),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isPastEvent => _original != null && !_original!.endTime.isAfter(DateTime.now());

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    final useCase = sl<UploadEventImageUseCase>();
    final result = await useCase(picked.path);
    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (url) => setState(() => _imageUrl = url),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _original == null) return;
    if (_category == null || _startDate == null || _startTime == null || _endTime == null) return;

    final startDateTime = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute,
    );
    final endDateTime = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day, _endTime!.hour, _endTime!.minute,
    );
    if (!endDateTime.isAfter(startDateTime)) {
      AppToast.warning(context, 'addEvent.endBeforeStart'.tr());
      return;
    }

    setState(() => _isSubmitting = true);

    final useCase = sl<UpdateEventUseCase>();
    final result = await useCase(UpdateEventParams(
      eventId: widget.eventId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category!,
      startTime: startDateTime,
      endTime: endDateTime,
      imageUrl: _imageUrl,
    ));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      // Covers both ordinary validation failures and the backend's
      // "already finished" rejection (a race between loading this screen
      // and submitting) — the server's message says which, so it's shown
      // as-is rather than a generic fallback.
      (failure) => AppToast.error(context, failure.message),
      (updated) {
        ref.invalidate(myEventsProvider(updated.businessId));
        ref.invalidate(eventsProvider);
        AppToast.success(context, 'editEvent.saved'.tr());
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }
    if (_original == null) {
      return Scaffold(body: ErrorStateWidget(message: 'editEvent.notFound'.tr()));
    }

    final dateFmt = DateFormat('MMM d, yyyy', context.locale.languageCode);

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
                  title: 'editEvent.title'.tr(),
                  subtitle: _original!.name,
                  icon: categoryIcon(_original!.category),
                  accent: categoryColor(_original!.category),
                  iconBadgeSize: 32,
                ),
              ),
              if (_isPastEvent)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.history_rounded, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('editEvent.cannotEditPast'.tr(), style: AppTextStyles.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          maxLength: 30,
                          decoration: InputDecoration(labelText: 'addEvent.eventName'.tr()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          maxLength: 300,
                          decoration: InputDecoration(labelText: 'addEvent.description'.tr()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                        ),
                        const SizedBox(height: 14),
                        SelectionField<String>(
                          label: 'addEvent.category'.tr(),
                          selectedValue: _category,
                          options: [
                            for (final c in ref.watch(categoryNamesProvider))
                              SelectionOption(value: c, label: localizedCategoryName(context, c)),
                          ],
                          onChanged: (v) => setState(() => _category = v),
                          validator: (v) => v == null ? 'addEvent.selectCategoryError'.tr() : null,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(_startDate == null ? 'addEvent.selectDate'.tr() : dateFmt.format(_startDate!)),
                                leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: _pickDate,
                              ),
                              const Divider(height: 1),
                              Row(
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      title: Text(
                                        _startTime?.format(context) ?? 'addEvent.startTime'.tr(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      leading: const Icon(Icons.access_time, color: AppColors.primary),
                                      onTap: () => _pickTime(isStart: true),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListTile(
                                      title: Text(
                                        _endTime?.format(context) ?? 'addEvent.endTime'.tr(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      leading: const Icon(Icons.access_time_filled, color: AppColors.primary),
                                      onTap: () => _pickTime(isStart: false),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _isUploadingImage ? null : _pickAndUploadImage,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Center(
                              child: _isUploadingImage
                                  ? const CircularProgressIndicator(color: AppColors.primary)
                                  : _imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: AppConstants.isRemoteMediaPath(_imageUrl)
                                              ? AppNetworkImage(url: AppConstants.resolveMediaUrl(_imageUrl)!, height: 100, width: double.infinity)
                                              : Image.file(File(_imageUrl!), height: 100, width: double.infinity, fit: BoxFit.cover),
                                        )
                                      : Text('addEvent.addImage'.tr()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        PrimaryButton(
                          label: 'common.saveChanges'.tr(),
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
