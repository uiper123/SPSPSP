import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/auth/token_storage.dart';

class AddPlaceService {
  Future<String?> _getToken() async {
    return tokenStorage.readToken();
  }

  Future<String> createPlace({
    required String name,
    required String description,
    required String address,
    required String coordinates,
    required int idCategory,
    required List<XFile> images,
  }) async {
    final token = await _getToken();
    if (token == null) return 'Ошибка: Нет токена авторизации';

    try {
      final List<String> base64Images = [];
      for (final file in images) {
        final bytes = await file.readAsBytes();
        base64Images.add(base64Encode(bytes));
      }

      final body = jsonEncode({
        'name': name,
        'description': description,
        'address': address,
        'coordinates': coordinates.isNotEmpty ? coordinates : null,
        'id_category': idCategory,
        'images': base64Images,
      });

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/api/place'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return 'ok';
      } else {
        return 'Сервер (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      return 'Сбой подключения: $e';
    }
  }
}
