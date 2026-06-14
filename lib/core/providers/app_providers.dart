// lib/core/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_db.dart';
import '../storage/secure_storage.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../network/sync_service.dart';

// ── Infrastructure providers ──────────────────────────────────
final localDbProvider = Provider<LocalDb>((ref) {
  final db = LocalDb();
  ref.onDispose(db.close);
  return db;
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    secureStorage: ref.watch(secureStorageProvider),
    localDb: ref.watch(localDbProvider),
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.init();
  ref.onDispose(service.dispose);
  return service;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    api: ref.watch(apiClientProvider),
    db: ref.watch(localDbProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
  service.startAutoSync();
  ref.onDispose(service.dispose);
  return service;
});

// ── App settings providers ────────────────────────────────────
final isOnlineProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

// App language: 'ar' or 'en'
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier(ref.watch(localDbProvider));
});

class LanguageNotifier extends StateNotifier<String> {
  final LocalDb _db;
  LanguageNotifier(this._db) : super('ar') {
    _load();
  }
  Future<void> _load() async {
    final lang = await _db.getSetting('mc_lang') ?? 'ar';
    state = lang;
  }
  Future<void> setLanguage(String lang) async {
    state = lang;
    await _db.setSetting('mc_lang', lang);
  }
}

// App theme: 'dark' / 'light'
final themeProvider = StateNotifierProvider<ThemeNotifier, String>((ref) {
  return ThemeNotifier(ref.watch(localDbProvider));
});

class ThemeNotifier extends StateNotifier<String> {
  final LocalDb _db;
  ThemeNotifier(this._db) : super('dark') {
    _load();
  }
  Future<void> _load() async {
    final t = await _db.getSetting('mc_theme') ?? 'dark';
    state = t;
  }
  Future<void> setTheme(String t) async {
    state = t;
    await _db.setSetting('mc_theme', t);
  }
}

// Accent color (hex string)
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, String>((ref) {
  return AccentColorNotifier(ref.watch(localDbProvider));
});

class AccentColorNotifier extends StateNotifier<String> {
  final LocalDb _db;
  AccentColorNotifier(this._db) : super('4CAF50') {
    _load();
  }
  Future<void> _load() async {
    final c = await _db.getSetting('mc_accent') ?? '4CAF50';
    state = c;
  }
  Future<void> setColor(String hex) async {
    state = hex;
    await _db.setSetting('mc_accent', hex);
  }
}
