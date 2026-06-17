import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'dart:convert';

class CategoryModel {
  final int id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class CategoryService {
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/categories'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<CategoryModel> result = [];
        for (var json in data) {
          try {
            result.add(CategoryModel.fromJson(json));
          } catch (e) {
            continue;
          }
        }
        return result;
      } else {
        return [];
      }
    } catch (e) {
      print('Ошибка при загрузке категорий: $e');
      return [];
    }
  }
}
