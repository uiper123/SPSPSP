class RoutePlaceItem {
  final int id;
  final String name;
  final String image;
  final String location;
  final String coordinates;
  final int position;

  RoutePlaceItem({
    required this.id,
    required this.name,
    required this.image,
    required this.location,
    required this.coordinates,
    required this.position,
  });

  factory RoutePlaceItem.fromJson(Map<String, dynamic> json) {
    return RoutePlaceItem(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      coordinates: (json['coordinates'] ?? '').toString(),
      position: json['position'] ?? 0,
    );
  }
}

class RoutePathPointModel {
  final double lat;
  final double lng;

  RoutePathPointModel({required this.lat, required this.lng});

  factory RoutePathPointModel.fromJson(Map<String, dynamic> json) {
    return RoutePathPointModel(
      lat: RouteModel._parseDouble(json['lat']),
      lng: RouteModel._parseDouble(json['lng']),
    );
  }
}

class RouteModel {
  final int id;
  final int idUser;
  final String name;
  final String? description;
  final String authorName;
  final String? authorAvatar;
  final double averageRating;
  final List<RoutePlaceItem> places;
  final String createdAt;

  RouteModel({
    required this.id,
    required this.idUser,
    required this.name,
    this.description,
    required this.authorName,
    this.authorAvatar,
    this.averageRating = 0.0,
    this.places = const [],
    required this.createdAt,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final List<RoutePlaceItem> placesList = [];
    if (json['places'] != null && json['places'] is List) {
      for (final p in json['places']) {
        placesList.add(RoutePlaceItem.fromJson(p));
      }
    }
    return RouteModel(
      id: json['id'] ?? 0,
      idUser: json['id_user'] ?? 0,
      name: (json['name'] ?? '').toString(),
      description: json['description'],
      authorName: (json['author_name'] ?? '').toString(),
      authorAvatar: json['author_avatar'],
      averageRating: _parseDouble(json['average_rating']),
      places: placesList,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class RoutePathModel {
  final int routeId;
  final String provider;
  final double distanceMeters;
  final double durationSeconds;
  final List<RoutePathPointModel> points;

  RoutePathModel({
    required this.routeId,
    required this.provider,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
  });

  factory RoutePathModel.fromJson(Map<String, dynamic> json) {
    final List<RoutePathPointModel> pointList = [];
    if (json['points'] != null && json['points'] is List) {
      for (final point in json['points']) {
        pointList.add(RoutePathPointModel.fromJson(point));
      }
    }

    return RoutePathModel(
      routeId: json['route_id'] ?? 0,
      provider: (json['provider'] ?? '').toString(),
      distanceMeters: RouteModel._parseDouble(json['distance_meters']),
      durationSeconds: RouteModel._parseDouble(json['duration_seconds']),
      points: pointList,
    );
  }
}

class RouteCommentModel {
  final int id;
  final int idRoute;
  final int idUser;
  final int estimation;
  final String comment;
  final String authorName;
  final String? authorAvatar;
  final String createdAt;

  RouteCommentModel({
    required this.id,
    required this.idRoute,
    required this.idUser,
    required this.estimation,
    required this.comment,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
  });

  factory RouteCommentModel.fromJson(Map<String, dynamic> json) {
    return RouteCommentModel(
      id: json['id'] ?? 0,
      idRoute: json['id_route'] ?? 0,
      idUser: json['id_user'] ?? 0,
      estimation: json['estimation'] ?? 0,
      comment: (json['comment'] ?? '').toString(),
      authorName: (json['author_name'] ?? '').toString(),
      authorAvatar: json['author_avatar'],
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
