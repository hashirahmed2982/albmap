import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/category_model.dart';

abstract class CategoryDataSource {
  Future<List<CategoryModel>> getCategories();
}

class CategoryRemoteDataSourceImpl implements CategoryDataSource {
  CategoryRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/categories');
      return (response.data['data'] as List<dynamic>)
          .map((dynamic e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Failed to load categories');
    }
  }
}
