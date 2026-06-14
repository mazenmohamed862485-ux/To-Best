// lib/core/storage/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const String _keySecretKey = 'to_best_secret_key';
  static const String _keyDeviceId  = 'to_best_device_id';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<String> getSecretKey() async {
    return (await _storage.read(key: _keySecretKey)) ?? '';
  }

  Future<void> saveSecretKey(String key) async {
    if (key.isEmpty) {
      await _storage.delete(key: _keySecretKey);
    } else {
      await _storage.write(key: _keySecretKey, value: key);
    }
  }

  Future<String> getDeviceId() async {
    var id = await _storage.read(key: _keyDeviceId);
    if (id == null || id.isEmpty) {
      id = _generateDeviceId();
      await _storage.write(key: _keyDeviceId, value: id);
    }
    return id;
  }

  String _generateDeviceId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = (now * 31 + now.hashCode).toRadixString(16);
    return 'dev_$rand';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
