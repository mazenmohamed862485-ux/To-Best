// lib/features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../../../core/providers/app_providers.dart';

// ── Auth state ────────────────────────────────────────────────
enum AuthStatus {
  loading,
  unauthenticated,
  authenticated,
  pending,
  rejected,
  paymentPending,
  subscriptionExpired,
  deviceBlocked,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isSuperAdmin => user?.isSuperAdmin ?? false;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    ref: ref,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier({required AuthRepository repository, required Ref ref})
      : _repo = repository,
        _ref = ref,
        super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final user = await _repo.getStoredUser();
      if (user == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      final resolved = _resolveStatus(user);
      state = AuthState(status: resolved, user: user);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  AuthStatus _resolveStatus(UserModel user) {
    if (user.isAdmin || user.isSuperAdmin) return AuthStatus.authenticated;
    if (user.status == 'rejected') return AuthStatus.rejected;
    if (user.status == 'payment_pending') return AuthStatus.paymentPending;
    if (user.status == 'pending') return AuthStatus.pending;
    if (user.status != 'active') return AuthStatus.pending;
    if (!user.isSubscriptionValid && !user.isAdmin) {
      return AuthStatus.subscriptionExpired;
    }
    return AuthStatus.authenticated;
  }

  Future<LoginResult> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repo.login(email, password);
      if (!result.ok) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: result.error,
        );
        return result;
      }
      final user = result.user!;
      final resolved = _resolveStatus(user);
      state = AuthState(status: resolved, user: user);
      return result;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
      return LoginResult(ok: false, error: e.toString());
    }
  }

  Future<LoginResult> register(Map<String, dynamic> userData) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repo.register(userData);
      if (!result.ok) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: result.error,
        );
        return result;
      }
      final user = result.user!;
      state = AuthState(status: AuthStatus.pending, user: user);
      return result;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
      return LoginResult(ok: false, error: e.toString());
    }
  }

  Future<LoginResult> loginGuest(String code) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repo.loginGuest(code);
      if (!result.ok) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: result.error,
        );
        return result;
      }
      final user = result.user!;
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return result;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
      return LoginResult(ok: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(UserModel user) {
    final resolved = _resolveStatus(user);
    state = AuthState(status: resolved, user: user);
    _repo.storeUser(user);
  }

  Future<void> refreshUser() async {
    final uid = state.user?.uid;
    if (uid == null) return;
    final fresh = await _repo.fetchFreshUser(uid);
    if (fresh != null) updateUser(fresh);
  }

  Future<bool> checkForceLogout() async {
    final user = state.user;
    if (user == null) return false;
    return _repo.checkForceLogout(user);
  }
}

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    localDb: ref.watch(localDbProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
