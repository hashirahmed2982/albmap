import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/site_content_entity.dart';
import '../repositories/content_repository.dart';

class GetSiteContentUseCase implements UseCase<SiteContentEntity, NoParams> {
  GetSiteContentUseCase(this._repository);
  final ContentRepository _repository;

  @override
  Future<Either<Failure, SiteContentEntity>> call(NoParams params) {
    return _repository.getSiteContent();
  }
}
