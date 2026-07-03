import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/business_entity.dart';
import '../repositories/business_repository.dart';

class GetBusinessesUseCase implements UseCase<List<BusinessEntity>, GetBusinessesParams> {
  GetBusinessesUseCase(this._repository);
  final BusinessRepository _repository;

  @override
  Future<Either<Failure, List<BusinessEntity>>> call(GetBusinessesParams params) {
    return _repository.getBusinesses(
      category: params.category,
      radiusKm: params.radiusKm,
      userLat: params.userLat,
      userLng: params.userLng,
      sortBy: params.sortBy,
    );
  }
}

class GetBusinessesParams extends Equatable {
  const GetBusinessesParams({
    this.category,
    this.radiusKm,
    this.userLat,
    this.userLng,
    this.sortBy = 'distance',
  });

  final String? category;
  final double? radiusKm;
  final double? userLat;
  final double? userLng;
  final String sortBy;

  @override
  List<Object?> get props => [category, radiusKm, userLat, userLng, sortBy];
}

class GetBusinessDetailsUseCase implements UseCase<BusinessEntity, String> {
  GetBusinessDetailsUseCase(this._repository);
  final BusinessRepository _repository;

  @override
  Future<Either<Failure, BusinessEntity>> call(String id) {
    return _repository.getBusinessDetails(id);
  }
}

class SearchBusinessesUseCase implements UseCase<List<BusinessEntity>, String> {
  SearchBusinessesUseCase(this._repository);
  final BusinessRepository _repository;

  @override
  Future<Either<Failure, List<BusinessEntity>>> call(String query) {
    return _repository.searchBusinesses(query);
  }
}

class SubmitBusinessUseCase implements UseCase<void, BusinessEntity> {
  SubmitBusinessUseCase(this._repository);
  final BusinessRepository _repository;

  @override
  Future<Either<Failure, void>> call(BusinessEntity business) {
    return _repository.submitBusiness(business);
  }
}

class GetMyBusinessesUseCase implements UseCase<List<BusinessEntity>, String> {
  GetMyBusinessesUseCase(this._repository);
  final BusinessRepository _repository;

  @override
  Future<Either<Failure, List<BusinessEntity>>> call(String ownerId) {
    return _repository.getMyBusinesses(ownerId);
  }
}
