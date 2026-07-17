import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Fixes a real gap: this tile previously did nothing (onTap: () {}) —
/// no in-app way to fix a typo'd name or add a phone number, ever. Also
/// wires up the avatar picker, which was previously a no-op button.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isSubmitting = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    final error = await ref.read(authControllerProvider.notifier).uploadAvatar(picked.path);
    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final error = await ref.read(authControllerProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('editProfile.saveSuccess'.tr())),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final avatarUrl = user?.profileImageUrl;
    // Mock mode's uploadAvatar echoes back a local file path (no real
    // server to host it), so a local path needs Image.file, while a real
    // upload returns an http(s) URL needing Image.network.
    final bool isLocalPath = avatarUrl != null && !avatarUrl.startsWith('http');

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
                    Text('editProfile.title'.tr(), style: AppTextStyles.h1),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: avatarUrl == null
                                  ? null
                                  : (isLocalPath ? FileImage(File(avatarUrl)) : NetworkImage(avatarUrl)) as ImageProvider,
                              child: avatarUrl == null
                                  ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: _isUploadingAvatar
                                  ? const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                      onPressed: _pickAndUploadAvatar,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(labelText: 'editProfile.fullName'.tr()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(labelText: 'editProfile.phone'.tr()),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'editProfile.emailLabel'.tr(args: [user?.email ?? '']),
                            style: AppTextStyles.bodySmall,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
