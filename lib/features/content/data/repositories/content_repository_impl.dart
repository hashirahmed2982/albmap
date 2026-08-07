import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/site_content_entity.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_remote_datasource.dart';

class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl({required ContentDataSource dataSource}) : _dataSource = dataSource;
  final ContentDataSource _dataSource;

  @override
  Future<Either<Failure, SiteContentEntity>> getSiteContent() async {
    try {
      return Right(await _dataSource.getSiteContent());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
