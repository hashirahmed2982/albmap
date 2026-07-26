import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/selection_field.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/domain/category_translations.dart';
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
  String _category = 'General';
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<BusinessEntity> _ownedBusinesses = [];
  bool _loadingBusinesses = true;
  String? _imageUrl;
  bool _isUploadingImage = false;

  static const List<String> _categories = ['General', 'Music', 'Food', 'Sports', 'Workshop', 'Community'];

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
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (url) => setState(() => _imageUrl = url),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null || _startDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('addEvent.completeAllFields'.tr())));
      return;
    }

    final startDateTime = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute,
    );
    final endDateTime = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day, _endTime!.hour, _endTime!.minute,
    );

    final event = EventEntity(
      id: const Uuid().v4(),
      businessId: _selectedBusiness!.id,
      businessName: _selectedBusiness!.name,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      startTime: startDateTime,
      endTime: endDateTime,
      imageUrl: _imageUrl,
    );

    final bool success = await ref.read(createEventControllerProvider.notifier).submit(event);
    if (success && mounted) {
      ref.invalidate(eventsProvider);
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('addEvent.failedToCreate'.tr())));
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
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('addEvent.title'.tr(), style: AppTextStyles.h1),
                        Text('addEvent.subtitle'.tr(), style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                ],
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
                                  decoration: InputDecoration(labelText: 'addEvent.eventName'.tr()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _descController,
                                  maxLines: 4,
                                  decoration: InputDecoration(labelText: 'addEvent.description'.tr()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                                ),
                                const SizedBox(height: 14),
                                SelectionField<String>(
                                  label: 'addEvent.category'.tr(),
                                  selectedValue: _category,
                                  options: [
                                    for (final c in _categories)
                                      SelectionOption(value: c, label: localizedCategoryName(context, c)),
                                  ],
                                  onChanged: (v) => setState(() => _category = v ?? 'General'),
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
                                                      ? Image.network(AppConstants.resolveMediaUrl(_imageUrl)!, height: 100, width: double.infinity, fit: BoxFit.cover)
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
