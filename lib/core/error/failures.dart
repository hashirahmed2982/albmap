import 'package:equatable/equatable.dart';

/// Base failure type returned by repositories to the domain/presentation
/// layers. We never leak raw exceptions or Dio errors past the data layer —
/// everything gets mapped to one of these so UI code can pattern-match
/// cleanly without knowing about HTTP/DB details.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load cached data.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}

/// Carries the backend's structured duplicate-business warning (see
/// business.service.js's findPotentialDuplicate) so the UI can show the
/// specific conflicting business's name/distance rather than just a
/// generic error string, and offer a "submit anyway" path.
class DuplicateBusinessFailure extends Failure {
  const DuplicateBusinessFailure({
    required String message,
    required this.duplicateName,
    required this.duplicateAddress,
    required this.distanceMeters,
  }) : super(message);

  final String duplicateName;
  final String duplicateAddress;
  final int distanceMeters;

  @override
  List<Object?> get props => [message, duplicateName, duplicateAddress, distanceMeters];
}
