import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'dart:convert';

import 'package:spt/models/user_model.dart';
import 'package:spt/serv/auth_serv.dart';

class ProfileService {
  Future<bool> updateuserMe(
    XFile? avatar,
    String? first_name,
    String? last_name,
    String? patronymic,
    String? email,
    String? password,
  ) async {
    final token = await AuthService().getToken();
    Map<String, dynamic> data = {};
    if (avatar != null) {
      final bytes = await avatar.readAsBytes();
      final base64Image = base64Encode(bytes);
      data['avatar'] = base64Image;
    }
    if (first_name != null) data['first_name'] = first_name;
    if (last_name != null) data['last_name'] = last_name;
    if (patronymic != null) data['patronymic'] = patronymic;
    if (email != null) data['email'] = email;
    if (password != null && password.isNotEmpty) data['password'] = password;
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateuserAdmin(
    int id,
    String? avatar,
    String? first_name,
    String? last_name,
    String? patronymic,
    String? email,
    String? password,
    bool? banned,
    int? id_role,
  ) async {
    final token = await AuthService().getToken();
    Map<String, dynamic> data = {};
    if (avatar != null) data['avatar'] = avatar;
    if (first_name != null) data['first_name'] = first_name;
    if (last_name != null) data['last_name'] = last_name;
    if (patronymic != null) data['patronymic'] = patronymic;
    if (email != null) data['email'] = email;
    if (password != null && password.isNotEmpty) data['password'] = password;
    if (banned != null) data['banned'] = banned;
    if (id_role != null) data['id_role'] = id_role;
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> getuserMe() async {
    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/api/users/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        print(
          'Error status code: ${response.statusCode}, body: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error in getuserMe: $e');
      return null;
    }
  }
}
