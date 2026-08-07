import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/opening_hours_editor.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/selection_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../dashboard/presentation/providers/analytics_providers.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../map/domain/usecases/business_usecases.dart';
import '../../../map/presentation/widgets/business_list_view.dart';
import 'location_picker_screen.dart';

/// 9. Add Business Screen — business registration form (pending approval).
///
/// The address field is free-text (an address string can't be geocoded
/// reliably enough to place a marker without user confirmation — house
/// numbers, informal addresses, and typos are all common in real listings).
/// So the actual map coordinates come from a separate, explicit
/// "pick location on map" step (LocationPickerScreen) — the address text
/// and the coordinates are two independent pieces of information the owner
/// provides, not one derived from the other. Submission is blocked until a
/// location has actually been picked, rather than silently defaulting to
/// some placeholder point.
///
/// Also captures per-day opening hours (see OpeningHoursEditor) — this was
/// previously a backend/model field nothing in the UI ever populated, so
/// every business showed no hours at all on its details page.
class AddBusinessScreen extends ConsumerStatefulWidget {
  const AddBusinessScreen({super.key});

  @override
  ConsumerState<AddBusinessScreen> createState() => _AddBusinessScreenState();
}

class _AddBusinessScreenState extends ConsumerState<AddBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'Albania');
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _whatsappSameAsPhone = true;

  String? _category;
  LatLng? _pickedLocation;
  String? _logoUrl;
  Map<String, String> _openingHours = {};
  bool _isSubmitting = false;
  bool _isUploadingLogo = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingLogo = true);
    final useCase = sl<UploadLogoUseCase>();
    final result = await useCase(picked.path);
    if (!mounted) return;
    setState(() => _isUploadingLogo = false);

    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (url) => setState(() => _logoUrl = url),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: _pickedLocation),
      ),
    );
    if (result != null) {
      setState(() => _pickedLocation = result);
    }
  }

  Future<void> _submit({bool confirmDuplicate = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      AppToast.warning(context, 'addBusiness.selectCategoryError'.tr());
      return;
    }
    if (_pickedLocation == null) {
      AppToast.warning(context, 'addBusiness.selectLocationError'.tr());
      return;
    }

    setState(() => _isSubmitting = true);

    final user = ref.read(authControllerProvider).user!;
    final business = BusinessEntity(
      id: const Uuid().v4(),
      ownerId: user.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category!,
      streetAddress: _streetAddressController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim().isEmpty ? 'Albania' : _countryController.text.trim(),
      latitude: _pickedLocation!.latitude,
      longitude: _pickedLocation!.longitude,
      status: BusinessStatus.pending,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      whatsappNumber: _whatsappSameAsPhone
          ? (_phoneController.text.trim().isEmpty ? null : _phoneController.text.trim())
          : (_whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim()),
      logoUrl: _logoUrl,
      openingHours: _openingHours,
    );

    final useCase = sl<SubmitBusinessUseCase>();
    final result = await useCase(
      SubmitBusinessParams(business: business, confirmDuplicate: confirmDuplicate),
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    await result.fold(
      (failure) async {
        // A duplicate warning is a specific, actionable case — offer
        // "submit anyway" with the conflicting business's details, rather
        // than just showing the generic message as a dead-end error.
        if (failure is DuplicateBusinessFailure) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text('addBusiness.duplicateTitle'.tr()),
              content: Text(
                'addBusiness.duplicateBody'.tr(args: [
                  failure.duplicateName,
                  failure.duplicateAddress,
                  '${failure.distanceMeters}',
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('addBusiness.submitAnyway'.tr()),
                ),
              ],
            ),
          );
          if (proceed == true && mounted) {
            await _submit(confirmDuplicate: true);
          }
          return;
        }
        AppToast.error(context, failure.message);
      },
      (_) {
        // Without this, "My Businesses" would keep showing whatever it
        // last fetched — a FutureProvider.autoDispose only refetches when
        // actually disposed and rewatched, and simply navigating here via
        // push (then popping back) doesn't dispose the screen underneath,
        // it just covers it. This was the reported "have to refresh
        // manually to see the new business" bug.
        ref.invalidate(myBusinessesProvider(user.id));
        setState(() => _submitted = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              GradientHeader(
                child: PageHeaderTitle(
                  title: 'addBusiness.title'.tr(),
                  icon: Icons.storefront_rounded,
                  accent: AppColors.secondary,
                  backIcon: Icons.close_rounded,
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(color: AppColors.pending.withValues(alpha: 0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.hourglass_top_rounded, size: 48, color: AppColors.pending),
                        ),
                        const SizedBox(height: 20),
                        Text('addBusiness.submittedTitle'.tr(), style: AppTextStyles.h2, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(
                          'addBusiness.submittedBody'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(label: 'common.done'.tr(), onPressed: () => Navigator.of(context).pop()),
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

    final categoryNames = ref.watch(categoryNamesProvider);

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
                  title: 'addBusiness.title'.tr(),
                  subtitle: 'addBusiness.subtitle'.tr(),
                  icon: Icons.storefront_rounded,
                  accent: AppColors.secondary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: _isUploadingLogo ? null : _pickAndUploadLogo,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Center(
                            child: _isUploadingLogo
                                ? const CircularProgressIndicator(color: AppColors.primary)
                                : _logoUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AppConstants.isRemoteMediaPath(_logoUrl)
                                            ? AppNetworkImage(url: AppConstants.resolveMediaUrl(_logoUrl)!, height: 120, width: double.infinity)
                                            : Image.file(File(_logoUrl!), height: 120, width: double.infinity, fit: BoxFit.cover),
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                                          const SizedBox(height: 6),
                                          Text('addBusiness.addLogo'.tr(), style: AppTextStyles.bodySmall),
                                        ],
                                      ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'addBusiness.businessName'.tr()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(labelText: 'addBusiness.description'.tr()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                      ),
                      const SizedBox(height: 14),
                      SelectionField<String>(
                        label: 'addBusiness.category'.tr(),
                        selectedValue: _category,
                        options: [
                          for (final c in categoryNames)
                            SelectionOption(value: c, label: localizedCategoryName(context, c), icon: categoryIcon(c)),
                        ],
                        onChanged: (v) => setState(() => _category = v),
                        validator: (v) => v == null ? 'addBusiness.selectCategoryError'.tr() : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _streetAddressController,
                        decoration: InputDecoration(
                          labelText: 'addBusiness.streetAddress'.tr(),
                          helperText: 'addBusiness.streetAddressHelper'.tr(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(labelText: 'addBusiness.city'.tr()),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _postalCodeController,
                              decoration: InputDecoration(labelText: 'addBusiness.postalCode'.tr()),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _countryController,
                        decoration: InputDecoration(labelText: 'addBusiness.country'.tr()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                      ),
                      const SizedBox(height: 14),

                      // Separate, explicit map-pin step — this is what
                      // actually determines the marker position, not the
                      // address text above.
                      InkWell(
                        onTap: _openLocationPicker,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _pickedLocation == null
                                ? AppColors.surface
                                : AppColors.success.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _pickedLocation == null ? AppColors.divider : AppColors.success.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _pickedLocation == null ? Icons.pin_drop_outlined : Icons.check_circle,
                                color: _pickedLocation == null ? AppColors.primary : AppColors.success,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickedLocation == null
                                          ? 'addBusiness.setLocation'.tr()
                                          : 'addBusiness.locationSet'.tr(),
                                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_pickedLocation != null)
                                      Text(
                                        '${_pickedLocation!.latitude.toStringAsFixed(5)}, '
                                        '${_pickedLocation!.longitude.toStringAsFixed(5)}',
                                        style: AppTextStyles.bodySmall,
                                      )
                                    else
                                      Text(
                                        'addBusiness.locationRequired'.tr(),
                                        style: AppTextStyles.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: 'addBusiness.phoneNumber'.tr()),
                        validator: (v) => Validators.optionalPhone(v, invalidMessage: 'common.invalidPhone'.tr()),
                        onChanged: (_) => setState(() {}), // refresh WhatsApp preview text below
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _whatsappSameAsPhone,
                        onChanged: (v) => setState(() => _whatsappSameAsPhone = v ?? true),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('addBusiness.whatsappSameAsPhone'.tr(), style: AppTextStyles.bodyMedium),
                      ),
                      if (!_whatsappSameAsPhone) ...[
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: 'addBusiness.whatsappNumber'.tr()),
                          validator: (v) => Validators.optionalPhone(v, invalidMessage: 'common.invalidPhone'.tr()),
                        ),
                      ],
                      const SizedBox(height: 20),

                      Text('addBusiness.openingHours'.tr(), style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text(
                        'addBusiness.openingHoursHelper'.tr(),
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      OpeningHoursEditor(
                        initialHours: _openingHours,
                        onChanged: (hours) => _openingHours = hours,
                      ),

                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'addBusiness.submit'.tr(),
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
