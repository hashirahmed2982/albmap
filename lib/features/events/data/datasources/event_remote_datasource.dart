import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/event_model.dart';

abstract class EventRemoteDataSource {
  Future<List<EventModel>> getEvents({
    String? category,
    String? businessId,
    DateTime? fromDate,
    DateTime? toDate,
  });
  Future<EventModel> getEventDetails(String id);
  Future<void> createEvent(EventModel event);
  Future<String> uploadEventImage(String filePath);

  /// "I'm interested" / RSVP toggle — see the backend's event.routes.js
  /// (POST/DELETE /events/:id/interest) and event_interests table.
  Future<void> addInterest(String eventId);
  Future<void> removeInterest(String eventId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  EventRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<EventModel>> getEvents({
    String? category,
    String? businessId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/events',
        queryParameters: <String, dynamic>{
          if (category != null) 'category': category,
          if (businessId != null) 'businessId': businessId,
          if (fromDate != null) 'from': fromDate.toIso8601String(),
          if (toDate != null) 'to': toDate.toIso8601String(),
        },
      );
      return (response.data['data'] as List<dynamic>)
          .map((dynamic e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to load events');
    }
  }

  @override
  Future<EventModel> getEventDetails(String id) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/events/$id');
      return EventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to load event');
    }
  }

  @override
  Future<void> createEvent(EventModel event) async {
    try {
      await _dio.post<dynamic>('/events', data: event.toCreateJson());
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to create event');
    }
  }

  @override
  Future<String> uploadEventImage(String filePath) async {
    try {
      final formData = FormData.fromMap(<String, dynamic>{
        'image': await MultipartFile.fromFile(filePath),
      });
      final Response<dynamic> response = await _dio.post<dynamic>('/events/image', data: formData);
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to upload event image');
    }
  }

  @override
  Future<void> addInterest(String eventId) async {
    try {
      await _dio.post<dynamic>('/events/$eventId/interest');
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to mark interest');
    }
  }

  @override
  Future<void> removeInterest(String eventId) async {
    try {
      await _dio.delete<dynamic>('/events/$eventId/interest');
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to remove interest');
    }
  }
}
