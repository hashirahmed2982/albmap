import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/selection_field.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/domain/usecases/event_usecases.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../map/domain/usecases/business_usecases.dart';

/// 10. Add Event Screen — business users create events tied to their business.
class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  BusinessEntity? _selectedBusiness;
  // Was a hardcoded, event-only list ('General', 'Music', ...) disconnected
  // from the same backend categories table Add Business already used —
  // now driven by categoryNamesProvider like everywhere else, so there's
  // exactly one source of truth for what categories exist. No longer
  // defaults to a guessed value, since nothing guarantees the backend's
  // list still contains a category literally named 'General'.
  String? _category;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<BusinessEntity> _ownedBusinesses = [];
  bool _loadingBusinesses = true;
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadOwnedBusinesses();
  }

  Future<void> _loadOwnedBusinesses() async {
    final userId = ref.read(authControllerProvider).user?.id;
    final useCase = sl<GetBusinessesUseCase>();
    final result = await useCase(const GetBusinessesParams());
    result.fold(
      (_) => setState(() => _loadingBusinesses = false),
      (businesses) => setState(() {
        _ownedBusinesses = businesses.where((b) => b.ownerId == userId).toList();
        _loadingBusinesses = false;
      }),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null || _startDate == null || _startTime == null || _endTime == null) {
      AppToast.warning(context, 'addEvent.completeAllFields'.tr());
      return;
    }

    final startDateTime = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute,
    );
    final endDateTime = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day, _endTime!.hour, _endTime!.minute,
    );

    // Without this check, picking an end time earlier in the day than the
    // start time (an easy mis-tap on the time picker) silently created an
    // event with a negative duration — nothing caught it here, and nothing
    // downstream re-validates it either.
    if (!endDateTime.isAfter(startDateTime)) {
      AppToast.warning(context, 'addEvent.endBeforeStart'.tr());
      return;
    }

    final event = EventEntity(
      id: const Uuid().v4(),
      businessId: _selectedBusiness!.id,
      businessName: _selectedBusiness!.name,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category!,
      startTime: startDateTime,
      endTime: endDateTime,
      imageUrl: _imageUrl,
    );

    final bool success = await ref.read(createEventControllerProvider.notifier).submit(event);
    if (success && mounted) {
      ref.invalidate(eventsProvider);
      Navigator.of(context).pop();
    } else if (mounted) {
      AppToast.error(context, 'addEvent.failedToCreate'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createEventControllerProvider);
    final dateFmt = DateFormat('MMM d, yyyy', context.locale.languageCode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              child: PageHeaderTitle(
                title: 'addEvent.title'.tr(),
                subtitle: 'addEvent.subtitle'.tr(),
                icon: Icons.event_rounded,
                accent: AppColors.secondary,
              ),
            ),
            Expanded(
              child: _loadingBusinesses
                  ? const LoadingIndicator()
                  : _ownedBusinesses.isEmpty
                      ? EmptyStateWidget(
                          message: 'addEvent.noBusinessTitle'.tr(),
                          icon: Icons.storefront_outlined,
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SelectionField<BusinessEntity>(
                                  label: 'addEvent.associatedBusiness'.tr(),
                                  selectedValue: _selectedBusiness,
                                  options: [
                                    for (final b in _ownedBusinesses)
                                      SelectionOption(value: b, label: b.name, icon: Icons.storefront_outlined),
                                  ],
                                  onChanged: (v) => setState(() => _selectedBusiness = v),
                                ),
                                const SizedBox(height: 14),
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
                                  label: 'addEvent.submit'.tr(),
                                  isLoading: createState.isLoading,
                                  onPressed: _submit,
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
