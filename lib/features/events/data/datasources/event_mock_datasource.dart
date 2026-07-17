import '../models/event_model.dart';
import 'event_remote_datasource.dart';

/// In-memory fake events, tied to the fake business IDs in
/// business_mock_datasource.dart (biz-1, biz-2, ...) so Business Details
/// screens show related events correctly.
class EventMockDataSource implements EventRemoteDataSource {
  static final DateTime _now = DateTime.now();

  static final List<EventModel> _events = [
    EventModel(
      id: 'evt-1', businessId: 'biz-1', businessName: 'Espresso Corner',
      name: 'Latte Art Workshop', description: 'Learn the basics of latte art from our head barista.',
      category: 'Workshop',
      startTime: _now.add(const Duration(days: 3, hours: 2)),
      endTime: _now.add(const Duration(days: 3, hours: 4)),
      address: 'Rruga Myslym Shyri, Tirana',
    ),
    EventModel(
      id: 'evt-2', businessId: 'biz-2', businessName: 'Bella Napoli',
      name: 'Pizza & Wine Night', description: 'Pairing menu featuring 4 pizzas and local wines.',
      category: 'Food',
      startTime: _now.add(const Duration(days: 5, hours: 5)),
      endTime: _now.add(const Duration(days: 5, hours: 8)),
      address: 'Blloku, Tirana',
    ),
    EventModel(
      id: 'evt-3', businessId: 'biz-3', businessName: 'Urban Fitness Studio',
      name: 'Free Community Yoga', description: 'Open outdoor yoga session, all levels welcome.',
      category: 'Sports',
      startTime: _now.add(const Duration(days: 1, hours: 3)),
      endTime: _now.add(const Duration(days: 1, hours: 4)),
      address: 'Rruga e Kavajës, Tirana',
    ),
    EventModel(
      id: 'evt-4', businessId: 'biz-5', businessName: 'CineStar Multiplex',
      name: 'Indie Film Night', description: 'Screening of a local independent film followed by Q&A.',
      category: 'Community',
      startTime: _now.add(const Duration(days: 7, hours: 6)),
      endTime: _now.add(const Duration(days: 7, hours: 9)),
      address: 'TEG, Tirana',
    ),
  ];

  Future<void> _fakeDelay() => Future<void>.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<EventModel>> getEvents({
    String? category,
    String? businessId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await _fakeDelay();
    Iterable<EventModel> results = _events;
    if (category != null) results = results.where((e) => e.category == category);
    if (businessId != null) results = results.where((e) => e.businessId == businessId);
    if (fromDate != null) results = results.where((e) => e.startTime.isAfter(fromDate));
    if (toDate != null) results = results.where((e) => e.startTime.isBefore(toDate));
    return results.toList();
  }

  @override
  Future<EventModel> getEventDetails(String id) async {
    await _fakeDelay();
    return _events.firstWhere((e) => e.id == id, orElse: () => _events.first);
  }

  @override
  Future<void> createEvent(EventModel event) async {
    await _fakeDelay();
    _events.add(event);
  }

  @override
  Future<String> uploadEventImage(String filePath) async {
    await _fakeDelay();
    return filePath;
  }
}
