// lib/features/auth/data/repositories/auth_repository.dart
import 'dart:convert';
import '../models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/storage/secure_storage.dart';

class LoginResult {
  final bool ok;
  final UserModel? user;
  final String? error;
  final String? redirectTo;

  const LoginResult({
    required this.ok,
    this.user,
    this.error,
    this.redirectTo,
  });
}

class AuthRepository {
  final ApiClient _api;
  final LocalDb _db;
  final SecureStorage _secureStorage;

  static const String _userKey = 'current_user';
  static const String _adminEmail = 'admin@local';
  static const String _adminPassword = 'admin123';

  AuthRepository({
    required ApiClient apiClient,
    required LocalDb localDb,
    required SecureStorage secureStorage,
  })  : _api = apiClient,
        _db = localDb,
        _secureStorage = secureStorage;

  Future<LoginResult> login(String email, String password) async {
    // Local admin (offline) check
    if (email.trim().toLowerCase() == _adminEmail &&
        password == _adminPassword) {
      final adminUser = UserModel(
        uid: 'local_admin',
        email: _adminEmail,
        name: 'Local Admin',
        role: 'superadmin',
        status: 'active',
      );
      await storeUser(adminUser);
      return LoginResult(ok: true, user: adminUser);
    }

    final res = await _api.login(email.trim().toLowerCase(), password);
    if (res['ok'] != true) {
      return LoginResult(
        ok: false,
        error: _mapError(res['err']?.toString() ?? 'unknown'),
      );
    }

    final userData = res['user'];
    if (userData == null) {
      return LoginResult(ok: false, error: 'invalid_response');
    }
    final user = UserModel.fromMap(Map<String, dynamic>.from(userData as Map));

    // Check device lock
    final deviceId = await _secureStorage.getDeviceId();
    if (user.deviceId != null &&
        user.deviceId!.isNotEmpty &&
        user.deviceId != deviceId) {
      return LoginResult(ok: false, error: 'device_blocked');
    }

    await storeUser(user);
    await _db.upsertUser(user.toMap());
    return LoginResult(ok: true, user: user);
  }

  Future<LoginResult> register(Map<String, dynamic> userData) async {
    final deviceId = await _secureStorage.getDeviceId();
    final payload = {...userData, 'deviceId': deviceId};
    final res = await _api.register(payload);
    if (res['ok'] != true) {
      return LoginResult(
        ok: false,
        error: _mapError(res['err']?.toString() ?? 'unknown'),
      );
    }
    final user = UserModel.fromMap(
        Map<String, dynamic>.from((res['user'] ?? res) as Map));
    await storeUser(user);
    await _db.upsertUser(user.toMap());
    return LoginResult(ok: true, user: user);
  }

  Future<LoginResult> loginGuest(String code) async {
    final res = await _api.loginGuest(code);
    if (res['ok'] != true) {
      return LoginResult(
        ok: false,
        error: _mapError(res['err']?.toString() ?? 'invalid_code'),
      );
    }
    final user = UserModel.fromMap(
        Map<String, dynamic>.from((res['user'] ?? res) as Map));
    await storeUser(user);
    return LoginResult(ok: true, user: user);
  }

  Future<void> logout() async {
    await _db.setSetting(_userKey, '');
    await _api.clearSessionToken();
  }

  Future<UserModel?> getStoredUser() async {
    try {
      final raw = await _db.getSetting(_userKey) ?? '';
      if (raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final user = UserModel.fromMap(map);
      // Try to refresh from local DB
      final cached = await _db.getUser(user.uid);
      if (cached != null) return UserModel.fromMap(cached);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> storeUser(UserModel user) async {
    await _db.setSetting(_userKey, jsonEncode(user.toMap()));
    await _db.upsertUser(user.toMap());
  }

  Future<UserModel?> fetchFreshUser(String uid) async {
    final data = await _api.fetchUserData(uid);
    if (data == null) return null;
    final user = UserModel.fromMap(data);
    await storeUser(user);
    return user;
  }

  Future<bool> checkForceLogout(UserModel user) async {
    final seenKey = 'force_logout_seen_${user.uid}';
    final seen = await _db.getKv(seenKey) ?? '';
    final serverToken = user.forceLogoutToken ?? '';
    if (serverToken.isNotEmpty && serverToken != seen) {
      await logout();
      return true;
    }
    return false;
  }

  Future<bool> changePassword(String uid, String old, String newPwd) async {
    return _api.changePassword(uid, old, newPwd);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _api.forgotPassword(email);
  }

  String _mapError(String err) {
    switch (err) {
      case 'not_configured': return 'not_configured';
      case 'network': return 'network_error';
      case 'invalid': return 'invalid_credentials';
      case 'banned': return 'account_banned';
      case 'device_blocked': return 'device_blocked';
      case 'email_exists': return 'email_exists';
      case 'not_found': return 'user_not_found';
      default: return err;
    }
  }
}
