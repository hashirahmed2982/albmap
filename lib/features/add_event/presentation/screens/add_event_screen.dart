import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/domain/entities/event_entity.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null || _startDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please complete all fields')));
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
    );

    final bool success = await ref.read(createEventControllerProvider.notifier).submit(event);
    if (success && mounted) {
      ref.invalidate(eventsProvider);
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to create event')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createEventControllerProvider);
    final dateFmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                        Text('Add Event', style: AppTextStyles.h1),
                        const Text('Create an event for your business', style: AppTextStyles.bodyMedium),
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
                      ? const EmptyStateWidget(
                          message: 'You need an approved business before creating events',
                          icon: Icons.storefront_outlined,
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<BusinessEntity>(
                                  value: _selectedBusiness,
                                  decoration: const InputDecoration(labelText: 'Associated business'),
                                  items: [
                                    for (final b in _ownedBusinesses)
                                      DropdownMenuItem(value: b, child: Text(b.name)),
                                  ],
                                  onChanged: (v) => setState(() => _selectedBusiness = v),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Event name'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _descController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(labelText: 'Description'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _category,
                                  decoration: const InputDecoration(labelText: 'Category'),
                                  items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
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
                                        title: Text(_startDate == null ? 'Select date' : dateFmt.format(_startDate!)),
                                        leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                                        trailing: const Icon(Icons.chevron_right_rounded),
                                        onTap: _pickDate,
                                      ),
                                      const Divider(height: 1),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ListTile(
                                              title: Text(_startTime?.format(context) ?? 'Start time'),
                                              leading: const Icon(Icons.access_time, color: AppColors.primary),
                                              onTap: () => _pickTime(isStart: true),
                                            ),
                                          ),
                                          Expanded(
                                            child: ListTile(
                                              title: Text(_endTime?.format(context) ?? 'End time'),
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
                                  onTap: () {}, // wire image_picker for event poster
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.divider),
                                    ),
                                    child: const Center(child: Text('Add event image/poster')),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                PrimaryButton(
                                  label: 'Submit event',
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
