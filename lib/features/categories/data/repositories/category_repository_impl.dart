import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required CategoryDataSource dataSource}) : _dataSource = dataSource;
  final CategoryDataSource _dataSource;

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      return Right(await _dataSource.getCategories());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
