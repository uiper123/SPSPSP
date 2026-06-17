import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/auth/token_storage.dart';
import 'dart:convert';

class ReportTypeModel {
  final int id;
  final String name;

  ReportTypeModel({required this.id, required this.name});

  factory ReportTypeModel.fromJson(Map<String, dynamic> json) {
    return ReportTypeModel(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class ReportService {
  Future<List<ReportTypeModel>> getReportTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/type_reports'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((json) => ReportTypeModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendReport(int idPlace, int idTypeReport, String name) async {
    final token = await tokenStorage.readToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/report_places'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_place': idPlace,
          'id_user': 0,
          'report': name,
          'id_type_report': idTypeReport,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
