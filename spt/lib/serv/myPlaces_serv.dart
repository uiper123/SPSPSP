import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/auth/token_storage.dart';
import 'package:spt/models/plots_model.dart';

class MyPlacesService {
  Future<String?> _getToken() async {
    return tokenStorage.readToken();
  }

  Future<List<PlotsModel>> getMyPlaces() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/places/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<PlotsModel> result = [];
        for (var json in data) {
          try {
            result.add(PlotsModel.fromJson(json));
          } catch (e) {
            continue;
          }
        }
        return result;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<int> getFavoritesCount() async {
    final token = await _getToken();
    if (token == null) return 0;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/favorites/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
