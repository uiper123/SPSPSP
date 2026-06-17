import 'dart:html' as html;

import 'package:spt/core/auth/token_storage_base.dart';

class _WebTokenStorage implements TokenStorage {
  static const String _tokenKey = 'spotfynder_token';

  @override
  Future<void> writeToken(String token) async {
    html.window.localStorage[_tokenKey] = token;
  }

  @override
  Future<String?> readToken() async {
    return html.window.localStorage[_tokenKey];
  }

  @override
  Future<void> deleteToken() async {
    html.window.localStorage.remove(_tokenKey);
  }
}

TokenStorage createTokenStorage() => _WebTokenStorage();
