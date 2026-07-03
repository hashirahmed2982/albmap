import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/other_auth_usecases.dart';

/// Holds current auth state for the whole app. Screens/router read this
/// via `ref.watch(authControllerProvider)` to gate navigation and UI.
class AuthState {
  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserEntity? user, bool? isLoading, String? errorMessage, bool clearError = false}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController()
      : _loginUseCase = sl<LoginUseCase>(),
        _signUpUseCase = sl<SignUpUseCase>(),
        _continueAsGuestUseCase = sl<ContinueAsGuestUseCase>(),
        _getCurrentUserUseCase = sl<GetCurrentUserUseCase>(),
        _logoutUseCase = sl<LogoutUseCase>(),
        super(const AuthState(isLoading: true)) {
    _restoreSession();
  }

  final LoginUseCase _loginUseCase;
  final SignUpUseCase _signUpUseCase;
  final ContinueAsGuestUseCase _continueAsGuestUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;

  Future<void> _restoreSession() async {
    final result = await _getCurrentUserUseCase(const NoParams());
    result.fold(
      (failure) => state = const AuthState(isLoading: false),
      (user) => state = AuthState(user: user, isLoading: false),
    );
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _loginUseCase(LoginParams(email: email, password: password));
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (user) {
        state = AuthState(user: user, isLoading: false);
        return true;
      },
    );
  }

  Future<bool> signUp({required String email, required String password, required String name}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _signUpUseCase(SignUpParams(email: email, password: password, name: name));
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (user) {
        state = AuthState(user: user, isLoading: false);
        return true;
      },
    );
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _continueAsGuestUseCase(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (user) => state = AuthState(user: user, isLoading: false),
    );
  }

  Future<void> logout() async {
    await _logoutUseCase(const NoParams());
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
