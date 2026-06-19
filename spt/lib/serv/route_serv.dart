import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/auth/token_storage.dart';
import 'dart:convert';

import 'package:spt/models/route_model.dart';

class RouteService {
  String? lastError;

  Future<String?> _getToken() => tokenStorage.readToken();

  String? _readError(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<RouteModel>> getRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/routes'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((j) => RouteModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<RouteModel?> getRoute(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/route/$id'),
      );
      if (response.statusCode == 200) {
        return RouteModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<RoutePathModel?> getRoutePath(int routeId) async {
    lastError = null;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/route/$routeId/path'),
      );
      if (response.statusCode == 200) {
        return RoutePathModel.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }
      lastError = _readError(response);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<RouteModel?> createRoute(
    String name,
    String? description,
    List<int> placeIds,
  ) async {
    lastError = null;
    final token = await _getToken();
    if (token == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/route'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'place_ids': placeIds,
        }),
      );
      if (response.statusCode == 200) {
        return RouteModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      lastError = _readError(response);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<RouteModel?> updateRoute(
    int routeId,
    String name,
    String? description,
    List<int> placeIds,
  ) async {
    lastError = null;
    final token = await _getToken();
    if (token == null) return null;
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/route/$routeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'description': description ?? '',
          'place_ids': placeIds,
        }),
      );
      if (response.statusCode == 200) {
        return RouteModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      lastError = _readError(response);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteRoute(int routeId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/route/$routeId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<RouteCommentModel>> getComments(int routeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/api/comment_routes?id_route=$routeId',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((j) => RouteCommentModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addComment(int routeId, String comment, int estimation) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/comment_routes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_route': routeId,
          'estimation': estimation,
          'comment': comment,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/comment_routes/$commentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCommentAdmin(int commentId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/comment_routes/$commentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(int routeId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}/api/favorites/toggle_route?id_route=$routeId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['is_favorite'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkFavorite(int routeId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/api/favorites/check_route?id_route=$routeId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['is_favorite'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<RouteModel>> getMyFavoriteRoutes() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/favorites/my_routes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((j) => RouteModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<RouteModel>> getMyRoutes() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/routes/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((j) => RouteModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
