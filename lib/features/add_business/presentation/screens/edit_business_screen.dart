import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/opening_hours_editor.dart';
import '../../../../core/widgets/page_header_title.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/selection_field.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../dashboard/presentation/providers/analytics_providers.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../map/domain/usecases/business_usecases.dart';
import '../../../map/presentation/providers/business_providers.dart';
import '../../../map/presentation/widgets/business_list_view.dart';
import 'location_picker_screen.dart';

/// Fixes a real gap: PATCH /businesses/:id existed on the backend with no
/// mobile screen ever calling it — owners could submit a new listing but
/// never fix a typo in an approved one. Editing name/category/address/
/// coordinates on an approved listing sends it back to pending for
/// re-review (enforced server-side — see business.service.js's
/// SENSITIVE_FIELDS check) — this screen surfaces that plainly so it's
/// not a surprise to the owner. Also lets the owner update opening hours
/// after the fact (non-sensitive — never triggers re-review).
class EditBusinessScreen extends ConsumerStatefulWidget {
  const EditBusinessScreen({required this.businessId, super.key});
  final String businessId;

  @override
  ConsumerState<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends ConsumerState<EditBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _whatsappSameAsPhone = true;

  String? _category;
  LatLng? _pickedLocation;
  Map<String, String> _openingHours = {};
  BusinessEntity? _original;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(businessDetailsProvider(widget.businessId).future);
    if (!mounted || result == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _original = result;
      _nameController.text = result.name;
      _descController.text = result.description;
      _streetAddressController.text = result.streetAddress;
      _cityController.text = result.city;
      _postalCodeController.text = result.postalCode;
      _countryController.text = result.country;
      _phoneController.text = result.phone ?? '';
      _whatsappSameAsPhone = result.whatsappNumber == result.phone || result.whatsappNumber == null;
      _whatsappController.text = _whatsappSameAsPhone ? '' : (result.whatsappNumber ?? '');
      _category = result.category;
      _pickedLocation = LatLng(result.latitude, result.longitude);
      _openingHours = Map<String, String>.from(result.openingHours);
      _isLoading = false;
    });
  }

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

  /// True if this edit touches a field that requires re-review once
  /// approved — mirrors the backend's SENSITIVE_FIELDS list exactly, so
  /// the UI can warn *before* submitting, not just after.
  bool get _touchesSensitiveField {
    if (_original == null) return false;
    return _nameController.text.trim() != _original!.name ||
        _category != _original!.category ||
        _streetAddressController.text.trim() != _original!.streetAddress ||
        _cityController.text.trim() != _original!.city ||
        _postalCodeController.text.trim() != _original!.postalCode ||
        _countryController.text.trim() != _original!.country ||
        _pickedLocation?.latitude != _original!.latitude ||
        _pickedLocation?.longitude != _original!.longitude;
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initialLocation: _pickedLocation)),
    );
    if (result != null) setState(() => _pickedLocation = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _original == null) return;
    if (_category == null || _pickedLocation == null) return;

    final willResetToPending = _original!.status == BusinessStatus.approved && _touchesSensitiveField;
    if (willResetToPending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('editBusiness.reviewWarningTitle'.tr()),
          content: Text('editBusiness.reviewWarningBody'.tr()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('editBusiness.continueAnyway'.tr()),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isSubmitting = true);

    final useCase = sl<UpdateBusinessUseCase>();
    final result = await useCase(UpdateBusinessParams(
      businessId: widget.businessId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category!,
      streetAddress: _streetAddressController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim().isEmpty ? 'Albania' : _countryController.text.trim(),
      latitude: _pickedLocation!.latitude,
      longitude: _pickedLocation!.longitude,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      whatsappNumber: _whatsappSameAsPhone
          ? (_phoneController.text.trim().isEmpty ? null : _phoneController.text.trim())
          : (_whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim()),
      openingHours: _openingHours,
    ));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (updated) {
        ref.invalidate(businessDetailsProvider(widget.businessId));
        // Same staleness class as the Add Business fix: without this, "My
        // Businesses" keeps showing the pre-edit status (e.g. still
        // "Approved" even though this edit just sent it back to pending).
        ref.invalidate(myBusinessesProvider(updated.ownerId));
        AppToast.success(
          context,
          updated.status == BusinessStatus.pending
              ? 'editBusiness.savedPending'.tr()
              : 'editBusiness.saved'.tr(),
        );
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
      return Scaffold(body: ErrorStateWidget(message: 'editBusiness.notFound'.tr()));
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
                  title: 'editBusiness.title'.tr(),
                  subtitle: _original!.name,
                  icon: categoryIcon(_original!.category),
                  accent: categoryColor(_original!.category),
                  // Subtitle is the business's own (variable-length) name.
                  iconBadgeSize: 32,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_original!.status == BusinessStatus.approved)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 18, color: AppColors.info),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'editBusiness.infoBanner'.tr(),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _streetAddressController,
                        decoration: InputDecoration(labelText: 'addBusiness.streetAddress'.tr()),
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
                      InkWell(
                        onTap: _openLocationPicker,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pin_drop_outlined, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _pickedLocation == null
                                      ? 'addBusiness.setLocation'.tr()
                                      : '${_pickedLocation!.latitude.toStringAsFixed(5)}, '
                                        '${_pickedLocation!.longitude.toStringAsFixed(5)}',
                                  style: AppTextStyles.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                        onChanged: (_) => setState(() {}),
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
                      const SizedBox(height: 12),
                      OpeningHoursEditor(
                        initialHours: _openingHours,
                        onChanged: (hours) => _openingHours = hours,
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
