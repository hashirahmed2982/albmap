import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Persistent bottom navigation shell wrapping the 5 primary tabs.
///
/// Guests only lose the **Favorites** tab (saving is a registered-user
/// feature). Profile stays visible even for guests — it's their only path
/// back to signing up or logging in, and to Settings/About/Contact. Hiding
/// it entirely would strand a guest with no way to create an account short
/// of restarting the app. [ProfileScreen] itself detects guest state and
/// shows a "create an account" prompt instead of the account menu.
class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final bool isGuest = authState.user?.isGuest ?? true;
    final int unread = ref.watch(unreadNotificationsCountProvider);

    final List<_TabDef> tabs = [
      const _TabDef(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Discover'),
      const _TabDef(icon: Icons.event_outlined, activeIcon: Icons.event_rounded, label: 'Events'),
      if (!isGuest)
        const _TabDef(icon: Icons.favorite_outline, activeIcon: Icons.favorite_rounded, label: 'Favorites'),
      _TabDef(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications_rounded,
        label: 'Alerts',
        badgeCount: unread,
      ),
      _TabDef(
        icon: isGuest ? Icons.person_add_alt_outlined : Icons.person_outline,
        activeIcon: isGuest ? Icons.person_add_alt_1_rounded : Icons.person_rounded,
        label: isGuest ? 'Account' : 'Profile',
      ),
    ];

    // Map the (possibly reduced) visible tab list back to the full 5-branch
    // index. Only Favorites (branch 2) is ever skipped for guests — Profile
    // (branch 4) always stays reachable.
    final List<int> branchIndexes = isGuest ? [0, 1, 3, 4] : [0, 1, 2, 3, 4];
    final int currentTabIndex =
        branchIndexes.indexOf(navigationShell.currentIndex).clamp(0, tabs.length - 1);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            // Explicit per-state colors — without these, unselected icons/
            // labels fall back to a theme-derived color that can end up
            // invisible against this bar depending on ambient theme state.
            iconTheme: WidgetStateProperty.resolveWith((states) {
              return IconThemeData(
                color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              return AppTextStyles.caption.copyWith(
                color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
                fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              );
            }),
          ),
          child: NavigationBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            height: 64,
            selectedIndex: currentTabIndex,
            onDestinationSelected: (int index) {
              navigationShell.goBranch(
                branchIndexes[index],
                initialLocation: branchIndexes[index] == navigationShell.currentIndex,
              );
            },
            destinations: [
              for (final tab in tabs)
                NavigationDestination(
                  icon: tab.badgeCount > 0
                      ? Badge(
                          backgroundColor: AppColors.error,
                          label: Text('${tab.badgeCount}'),
                          child: Icon(tab.icon),
                        )
                      : Icon(tab.icon),
                  selectedIcon: Icon(tab.activeIcon),
                  label: tab.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef({required this.icon, required this.activeIcon, required this.label, this.badgeCount = 0});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
}
