import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Every use case in the domain layer implements this so the
/// presentation layer interacts with them uniformly.
abstract class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

/// For use cases that take no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
