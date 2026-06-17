import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/auth/token_storage.dart';
import 'dart:convert';

import 'package:spt/models/comment_model.dart';

class CommentService {
  Future<List<CommentModel>> getComments(int idPlace) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/comment_places?id_place=$idPlace',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return decoded.map((json) => CommentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addComment(int idPlace, String comment, int estimation) async {
    final token = await tokenStorage.readToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/comment_places'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_place': idPlace,
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
    final token = await tokenStorage.readToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/comment_places/$commentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
