import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/business_analytics_entity.dart';
import '../../domain/usecases/analytics_usecases.dart';
import '../../../map/domain/entities/business_entity.dart';
import '../../../map/domain/usecases/business_usecases.dart';

/// All businesses owned by the current user, across every approval status —
/// backs the "My Businesses" screen.
final myBusinessesProvider =
    FutureProvider.autoDispose.family<List<BusinessEntity>, String>((ref, ownerId) async {
  final useCase = sl<GetMyBusinessesUseCase>();
  final result = await useCase(ownerId);
  return result.fold((_) => <BusinessEntity>[], (list) => list);
});

final businessAnalyticsProvider =
    FutureProvider.autoDispose.family<BusinessAnalyticsEntity?, String>((ref, businessId) async {
  final useCase = sl<GetBusinessAnalyticsUseCase>();
  final result = await useCase(businessId);
  return result.fold((_) => null, (data) => data);
});

/// Fire-and-forget analytics recording — call from Business Details on
/// view/Call/Directions taps. Never awaited by the UI; failures are
/// swallowed at the repository level since analytics shouldn't block or
/// alarm the visitor.
void recordAnalyticsEvent(String businessId, AnalyticsEventType type) {
  final useCase = sl<RecordAnalyticsEventUseCase>();
  useCase(RecordAnalyticsEventParams(businessId: businessId, type: type));
}
