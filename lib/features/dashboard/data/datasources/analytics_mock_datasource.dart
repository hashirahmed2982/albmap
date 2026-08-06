import 'dart:math';

import '../../domain/entities/business_analytics_entity.dart';
import 'analytics_remote_datasource.dart';

/// In-memory analytics store, seeded with plausible starting numbers so the
/// Dashboard looks like a real business with history, not a blank slate.
/// Live taps recorded via [recordEvent] (Business Details → Call/Directions/
/// view) increment on top of the seed for the current app session.
class AnalyticsMockDataSource implements AnalyticsDataSource {
  static final Map<String, BusinessAnalyticsEntity> _store = {
    'biz-1': const BusinessAnalyticsEntity(
      businessId: 'biz-1', profileClicks: 214, websiteClicks: 58, callClicks: 31, favoriteCount: 19,
      last7DaysProfileClicks: [22, 30, 18, 41, 35, 28, 40],
    ),
    'biz-6': const BusinessAnalyticsEntity(
      businessId: 'biz-6', profileClicks: 132, websiteClicks: 24, callClicks: 47, favoriteCount: 8,
      last7DaysProfileClicks: [12, 15, 20, 10, 18, 25, 32],
    ),
    'biz-7': const BusinessAnalyticsEntity(
      businessId: 'biz-7', profileClicks: 0, websiteClicks: 0, callClicks: 0, favoriteCount: 0,
      last7DaysProfileClicks: [0, 0, 0, 0, 0, 0, 0],
    ),
  };

  BusinessAnalyticsEntity _defaultFor(String businessId) {
    final rand = Random(businessId.hashCode);
    return BusinessAnalyticsEntity(
      businessId: businessId,
      profileClicks: 40 + rand.nextInt(150),
      websiteClicks: 5 + rand.nextInt(40),
      callClicks: 5 + rand.nextInt(30),
      favoriteCount: rand.nextInt(20),
      last7DaysProfileClicks: List.generate(7, (_) => rand.nextInt(30)),
    );
  }

  @override
  Future<BusinessAnalyticsEntity> getBusinessAnalytics(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _store[businessId] ?? _defaultFor(businessId);
  }

  @override
  Future<void> recordEvent(String businessId, AnalyticsEventType type) async {
    final current = _store[businessId] ?? _defaultFor(businessId);
    switch (type) {
      case AnalyticsEventType.profileView:
        _store[businessId] = current.copyWith(profileClicks: current.profileClicks + 1);
        break;
      case AnalyticsEventType.websiteClick:
        _store[businessId] = current.copyWith(websiteClicks: current.websiteClicks + 1);
        break;
      case AnalyticsEventType.callClick:
        _store[businessId] = current.copyWith(callClicks: current.callClicks + 1);
        break;
    }
  }
}
