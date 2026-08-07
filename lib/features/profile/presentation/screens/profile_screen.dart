import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/delete_account_sheet.dart';

/// 8. Profile Screen — business user account management.
///
/// Guests reach this same screen (it's never hidden from the nav — see
/// main_shell.dart) but see a "create an account" prompt instead of the
/// account menu, since this is a guest's only in-app path to registration.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final bool isGuest = user?.isGuest ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context, ref, isGuest: isGuest),
            const SizedBox(height: 12),
            if (isGuest)
              _buildGuestPrompt(context, ref)
            else
              ..._buildAccountMenu(context, ref),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, {required bool isGuest}) {
    final user = ref.watch(authControllerProvider).user;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 28 + MediaQuery.of(context).padding.top, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withValues(alpha: 0.10), AppColors.background],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.surface,
                  // Was passing user.profileImageUrl straight to
                  // NetworkImage — the backend returns a server-relative
                  // path ("/uploads/xxx.png"), not an absolute URL, so
                  // this silently failed to load (NetworkImage requires a
                  // fully-qualified URI) even when EditProfileScreen's
                  // identical avatar — which does resolve it — showed
                  // correctly right next to it.
                  backgroundImage: AppConstants.resolveMediaUrl(user?.profileImageUrl) != null
                      ? NetworkImage(AppConstants.resolveMediaUrl(user?.profileImageUrl)!)
                      : null,
                  child: Icon(
                    isGuest ? Icons.person_outline : Icons.person,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (!isGuest)
                Positioned(
                  bottom: 0, right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      // This used to be a dead button (onPressed: () {})
                      // — tapping it visibly did nothing. Edit Profile
                      // already has a working, tested avatar picker/
                      // upload flow, so route there instead of
                      // duplicating that logic in a second place.
                      onPressed: () => context.push(AppRoutes.editProfile),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(isGuest ? 'profile.browsingAsGuest'.tr() : (user?.name ?? 'auth.signUp'.tr()), style: AppTextStyles.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            isGuest ? 'profile.createAccountToUnlock'.tr() : (user?.email ?? ''),
            style: AppTextStyles.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isGuest ? 'profile.guest'.tr() : (user?.role.name ?? '').toUpperCase(),
              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPrompt(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.storefront_outlined, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('profile.ownBusiness'.tr(), style: AppTextStyles.h3)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'profile.guestExplainer'.tr(),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'profile.createAccountBtn'.tr(),
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'profile.loginExisting'.tr(),
                outlined: true,
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(children: [
          _ProfileTile(icon: Icons.settings_outlined, label: 'profile.settings'.tr(), onTap: () => context.push(AppRoutes.settings)),
          _ProfileTile(icon: Icons.info_outline, label: 'profile.aboutUs'.tr(), onTap: () => context.push(AppRoutes.aboutUs)),
          _ProfileTile(icon: Icons.mail_outline, label: 'profile.contactUs'.tr(), onTap: () => context.push(AppRoutes.contactUs)),
        ]),
      ],
    );
  }

  List<Widget> _buildAccountMenu(BuildContext context, WidgetRef ref) {
    return [
      _SectionCard(children: [
        _ProfileTile(
          icon: Icons.edit_outlined,
          label: 'profile.editProfile'.tr(),
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        _ProfileTile(
          icon: Icons.lock_outline,
          label: 'profile.changePassword'.tr(),
          onTap: () => context.push(AppRoutes.changePassword),
        ),
      ]),
      const SizedBox(height: 12),
      _SectionCard(children: [
        _ProfileTile(
          icon: Icons.dashboard_outlined,
          label: 'profile.myBusinesses'.tr(),
          accent: AppColors.primary,
          onTap: () => context.push(AppRoutes.myBusinesses),
        ),
        _ProfileTile(
          icon: Icons.storefront_outlined,
          label: 'profile.addBusiness'.tr(),
          accent: AppColors.secondary,
          onTap: () => context.push(AppRoutes.addBusiness),
        ),
        _ProfileTile(icon: Icons.settings_outlined, label: 'profile.settings'.tr(), onTap: () => context.push(AppRoutes.settings)),
        _ProfileTile(icon: Icons.info_outline, label: 'profile.aboutUs'.tr(), onTap: () => context.push(AppRoutes.aboutUs)),
        _ProfileTile(icon: Icons.mail_outline, label: 'profile.contactUs'.tr(), onTap: () => context.push(AppRoutes.contactUs)),
      ]),
      const SizedBox(height: 12),
      _SectionCard(children: [
        _ProfileTile(
          icon: Icons.logout,
          label: 'profile.logOut'.tr(),
          accent: AppColors.error,
          onTap: () => _confirmLogout(context, ref),
        ),
      ]),
      const SizedBox(height: 12),
      _SectionCard(children: [
        _ProfileTile(
          icon: Icons.delete_outline,
          label: 'profile.deleteAccount'.tr(),
          accent: AppColors.error,
          onTap: () => _showDeleteAccountSheet(context),
        ),
      ]),
    ];
  }

  void _showDeleteAccountSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DeleteAccountSheet(),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('profile.logOutConfirmTitle'.tr()),
        content: Text('profile.logOutConfirmBody'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.cancel'.tr())),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authControllerProvider.notifier).logout();
            },
            child: Text('profile.logOut'.tr(), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.label, required this.onTap, this.accent});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color color = accent ?? AppColors.primary;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: accent), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
