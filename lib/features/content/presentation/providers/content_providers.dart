import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/site_content_entity.dart';
import '../../domain/usecases/get_site_content_usecase.dart';

/// Backs the About Us, Privacy Policy, and Terms & Conditions screens —
/// one shared fetch/cache instead of three, since GET /content returns
/// all of it in one call. Not `.autoDispose`: this rarely changes and
/// three different screens read it, so keeping it cached for the app's
/// lifetime (until explicitly invalidated on retry) avoids a refetch
/// flicker every time one of those screens is reopened.
///
/// Folds a failure to `null` rather than surfacing AsyncValue.error —
/// matches this codebase's existing convention (see categoriesProvider,
/// businessDetailsProvider); screens check for null themselves and show
/// ErrorStateWidget with a retry that invalidates this provider.
final siteContentProvider = FutureProvider<SiteContentEntity?>((ref) async {
  final useCase = sl<GetSiteContentUseCase>();
  final result = await useCase(const NoParams());
  return result.fold((_) => null, (content) => content);
});
