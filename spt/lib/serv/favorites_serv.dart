import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/auth/token_storage.dart';
import 'dart:convert';

import 'package:spt/models/plots_model.dart';

class FavoritesService {
  Future<List<PlotsModel>> getMyFavorites() async {
    final token = await tokenStorage.readToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/favorites/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final List<PlotsModel> result = [];
        for (var json in decoded) {
          try {
            result.add(PlotsModel.fromJson(json));
          } catch (e) {
            continue;
          }
        }
        return result;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> checkFavorite(int idPlace) async {
    final token = await tokenStorage.readToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/api/favorites/check?id_place=$idPlace',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorite'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(int idPlace) async {
    final token = await tokenStorage.readToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/favorites/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id_user': 0, 'id_place': idPlace}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorite'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
