import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/auth/token_storage.dart';
import 'package:spt/models/user_model.dart';
import 'package:spt/models/plots_model.dart';

class ReportPlacesModel {
  final int id;
  final int idPlace;
  final int idUser;
  final String report;
  final int idTypeReport;
  final DateTime createdAt;

  ReportPlacesModel({
    required this.id,
    required this.idPlace,
    required this.idUser,
    required this.report,
    required this.idTypeReport,
    required this.createdAt,
  });

  factory ReportPlacesModel.fromJson(Map<String, dynamic> json) {
    return ReportPlacesModel(
      id: json['id'] ?? 0,
      idPlace: json['id_place'] ?? 0,
      idUser: json['id_user'] ?? 0,
      report: json['report'] ?? '',
      idTypeReport: json['id_type_report'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class AdminService {
  Future<String?> _getToken() async {
    return tokenStorage.readToken();
  }

  Future<List<UserModel>> getUsers() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> toggleUserBan(int userId, bool isBanned) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/users/ban/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'banned': isBanned}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserRole(int userId, int newRoleId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id_role': newRoleId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<PlotsModel>> getPlacesByStatus(int statusId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/api/places/filter?id_status=$statusId',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((json) => PlotsModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<PlotsModel>> getAllPlaces() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/places/filter'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((json) => PlotsModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<PlotsModel?> getPlaceById(int placeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/places/filter?id=$placeId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        if (decoded.isNotEmpty) {
          return PlotsModel.fromJson(decoded.first);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updatePlace({
    required int placeId,
    String? name,
    String? description,
    String? address,
    String? coordinates,
    int? idCategory,
    List<String>? images,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (address != null) body['address'] = address;
      if (coordinates != null) body['coordinates'] = coordinates;
      if (idCategory != null) body['id_category'] = idCategory;
      if (images != null) body['images'] = images;

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/place/me/$placeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePlaceStatus(int placeId, int newStatusId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/place/status/$placeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id_status': newStatusId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePlace(int placeId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/place/$placeId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<ReportPlacesModel>> getReports() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/report_places'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((json) => ReportPlacesModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteReport(int reportId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/report_places/$reportId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addCategory(String name) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/categories/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCategory(int id, String name) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/category/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
