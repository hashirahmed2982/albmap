import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/site_content_model.dart';

abstract class ContentDataSource {
  Future<SiteContentModel> getSiteContent();
}

class ContentRemoteDataSourceImpl implements ContentDataSource {
  ContentRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<SiteContentModel> getSiteContent() async {
    try {
      // Public/unauthenticated on the backend — works the same for a
      // guest as a logged-in user, same as /categories.
      final Response<dynamic> response = await _dio.get<dynamic>('/content');
      return SiteContentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to load content');
    }
  }
}
