import 'package:http/http.dart' as http;
import 'package:spt/core/constant/api_constants.dart';
import 'dart:convert';

import 'package:spt/models/plots_model.dart';

class SearchPlots {
  Future<List<PlotsModel>> searchPlots({
    int? idCategory,
    int? idStatus,
    int? rating,
    String? country,
    String? region,
    String? city,
    String? name,
    double? distance,
    double? latitude,
    double? longitude,
  }) async {
    Map<String, String> data = {};
    if (idCategory != null) data['id_category'] = idCategory.toString();
    if (idStatus != null) data['id_status'] = idStatus.toString();
    if (rating != null) data['rating'] = rating.toString();
    if (country != null) data['country'] = country;
    if (region != null) data['region'] = region;
    if (city != null) data['city'] = city;
    if (name != null) data['name'] = name;
    if (distance != null) data['distance'] = distance.toString();
    if (latitude != null) data['latitude'] = latitude.toString();
    if (longitude != null) data['longitude'] = longitude.toString();

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/api/places/filter',
    ).replace(queryParameters: data);

    try {
      final response = await http.get(uri);
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
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
