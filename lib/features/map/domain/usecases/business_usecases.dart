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

class SubmitBusinessParams extends Equatable {
  const SubmitBusinessParams({required this.business, this.confirmDuplicate = false});
  final BusinessEntity business;
  final bool confirmDuplicate;

  @override
  List<Object?> get props => [business, confirmDuplicate];
}

class SubmitBusinessUseCase implements UseCase<BusinessEntity, SubmitBusinessParams> {
  SubmitBusinessUseCase(this._repository);
  final BusinessRepository _repository;

  @override
  Future<Either<Failure, BusinessEntity>> call(SubmitBusinessParams params) {
    return _repository.submitBusiness(params.business, confirmDuplicate: params.confirmDuplicate);
  }
}

class UpdateBusinessParams extends Equatable {
  const UpdateBusinessParams({
    required this.businessId,
    this.name,
    this.description,
    this.category,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.openingHours,
  });

  final String businessId;
  final String? name;
  final String? description;
  final String? category;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final Map<String, String>? openingHours;

  @override
  List<Object?> get props =>
      [businessId, name, description, category, address, latitude, longitude, phone, openingHours];
}

class UpdateBusinessUseCase implements UseCase<BusinessEntity, UpdateBusinessParams> {
  UpdateBusinessUseCase(this._repository);
  final BusinessRepository _repository;

  @override
  Future<Either<Failure, BusinessEntity>> call(UpdateBusinessParams params) {
    return _repository.updateBusiness(
      params.businessId,
      name: params.name,
      description: params.description,
      category: params.category,
      address: params.address,
      latitude: params.latitude,
      longitude: params.longitude,
      phone: params.phone,
      openingHours: params.openingHours,
    );
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

class UploadLogoUseCase implements UseCase<String, String> {
  UploadLogoUseCase(this._repository);
  final BusinessRepository _repository;

  @override
  Future<Either<Failure, String>> call(String filePath) {
    return _repository.uploadLogo(filePath);
  }
}
