import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/site_content_entity.dart';

abstract class ContentRepository {
  Future<Either<Failure, SiteContentEntity>> getSiteContent();
}
