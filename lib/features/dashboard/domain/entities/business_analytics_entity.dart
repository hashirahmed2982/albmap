import 'package:equatable/equatable.dart';

/// Aggregate engagement stats for a single business, shown on its owner's
/// Dashboard. "Profile clicks" = times the business's detail page was
/// opened; "Website clicks" = taps on Directions/website; "Call clicks" =
/// taps on the Call button. Daily series is a simple last-7-days trend for
/// a small sparkline-style chart.
class BusinessAnalyticsEntity extends Equatable {
  const BusinessAnalyticsEntity({
    required this.businessId,
    required this.profileClicks,
    required this.websiteClicks,
    required this.callClicks,
    required this.favoriteCount,
    this.last7DaysProfileClicks = const [],
  });

  final String businessId;
  final int profileClicks;
  final int websiteClicks;
  final int callClicks;
  final int favoriteCount;
  final List<int> last7DaysProfileClicks;

  BusinessAnalyticsEntity copyWith({
    int? profileClicks,
    int? websiteClicks,
    int? callClicks,
    int? favoriteCount,
  }) {
    return BusinessAnalyticsEntity(
      businessId: businessId,
      profileClicks: profileClicks ?? this.profileClicks,
      websiteClicks: websiteClicks ?? this.websiteClicks,
      callClicks: callClicks ?? this.callClicks,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      last7DaysProfileClicks: last7DaysProfileClicks,
    );
  }

  @override
  List<Object?> get props =>
      [businessId, profileClicks, websiteClicks, callClicks, favoriteCount, last7DaysProfileClicks];
}

enum AnalyticsEventType { profileView, websiteClick, callClick }
