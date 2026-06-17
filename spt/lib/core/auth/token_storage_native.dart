import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spt/core/auth/token_storage_base.dart';

class _NativeTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> writeToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  @override
  Future<String?> readToken() async {
    return _storage.read(key: 'token');
  }

  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }
}

TokenStorage createTokenStorage() => _NativeTokenStorage();
