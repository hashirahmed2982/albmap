import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../events/presentation/screens/event_list_tile.dart';
import '../../../map/presentation/widgets/business_list_view.dart';
import '../providers/favorites_providers.dart';

/// 6. Favorites Screen — saved businesses & events (business users only).
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('favorites.title'.tr(), style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('favorites.subtitle'.tr(), style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    tabs: [Tab(text: 'favorites.businesses'.tr()), Tab(text: 'favorites.events'.tr())],
                  ),
                ],
              ),
            ),
            Expanded(
              child: favoritesAsync.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => ErrorStateWidget(
                  message: 'favorites.failedToLoad'.tr(),
                  onRetry: () => ref.invalidate(favoritesProvider),
                ),
                data: (favorites) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      favorites.businesses.isEmpty
                          ? EmptyStateWidget(
                              message: 'favorites.noBusinesses'.tr(), icon: Icons.storefront_outlined)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              itemCount: favorites.businesses.length,
                              itemBuilder: (context, i) => BusinessCard(
                                business: favorites.businesses[i],
                                trailing: IconButton(
                                  icon: const Icon(Icons.favorite, color: AppColors.error),
                                  onPressed: () async {
                                    final error = await ref
                                        .read(favoriteToggleControllerProvider.notifier)
                                        .toggleBusiness(favorites.businesses[i]);
                                    if (error != null && context.mounted) {
                                      AppToast.error(context, error);
                                    }
                                  },
                                ),
                              ),
                            ),
                      favorites.events.isEmpty
                          ? EmptyStateWidget(message: 'favorites.noEvents'.tr(), icon: Icons.event_busy_outlined)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              itemCount: favorites.events.length,
                              itemBuilder: (context, i) => EventListTile(event: favorites.events[i]),
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
