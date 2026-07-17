import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase implements UseCase<List<CategoryEntity>, NoParams> {
  GetCategoriesUseCase(this._repository);
  final CategoryRepository _repository;

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams params) {
    return _repository.getCategories();
  }
}
