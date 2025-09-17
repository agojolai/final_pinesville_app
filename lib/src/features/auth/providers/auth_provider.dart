import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/repositories/auth_repository.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.instance;
});

// Current User Provider
final currentUserProvider = StreamProvider<firebase_auth.User?>((ref) {
  return firebase_auth.FirebaseAuth.instance.authStateChanges();
});

// Auth State Provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepository);
});

// Auth State Classes
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final firebase_auth.User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    firebase_auth.User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Auth State Notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(const AuthState()) {
    // Listen to auth state changes
    _authRepository.authUser;
  }

  // Login method
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final userCredential = await _authRepository.logInWithEmailAndPassword(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: userCredential.user,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      // Rethrow the exception so the UI can handle it
      rethrow;
    }
  }

  // Register method
  Future<firebase_auth.UserCredential?> signUp(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final userCredential = await _authRepository.registerWithEmailAndPassword(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: userCredential.user,
        errorMessage: null,
      );
      return userCredential;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      // Rethrow the exception so the UI can handle it
      rethrow;
    }
  }

  // Logout method
  Future<void> signOut() async {
    try {
      await _authRepository.logout();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Forget password method
  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.forgetPassword(email);
      // You might want to show a success message here
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(
      status: AuthStatus.initial,
      errorMessage: null,
    );
  }
}
