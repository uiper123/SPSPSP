import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/auth/token_storage.dart';

class AuthService {
  String? lastError;

  Future<void> saveToken(String token) async {
    await tokenStorage.writeToken(token);
  }

  Future<String?> getToken() async {
    return tokenStorage.readToken();
  }

  Future<void> deleteToken() async {
    await tokenStorage.deleteToken();
  }

  String? _readError(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> login(String email, String password) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final accessToken = data['access_token'];
        if (accessToken is! String || accessToken.isEmpty) {
          lastError = 'Сервер не вернул токен авторизации';
          return false;
        }
        await saveToken(accessToken);
        return true;
      } else {
        lastError = _readError(response) ?? 'Не удалось выполнить вход';
        return false;
      }
    } catch (e) {
      lastError = 'Ошибка входа: $e';
      return false;
    }
  }

  Future<String> register(
    String first_name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': first_name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return 'ok';
      } else {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map && decoded.containsKey('detail')) {
            final detail = decoded['detail'];
            if (detail is List) {
              return 'Проверьте правильность введенных данных';
            }
            return detail.toString();
          }
        } catch (_) {}
        return 'Ошибка регистрации';
      }
    } catch (e) {
      return 'Ошибка сети';
    }
  }
}
