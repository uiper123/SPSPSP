import 'package:spt/core/auth/token_storage_base.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> readToken() async {
    return _token;
  }

  @override
  Future<void> deleteToken() async {
    _token = null;
  }
}

TokenStorage createTokenStorage() => _MemoryTokenStorage();
