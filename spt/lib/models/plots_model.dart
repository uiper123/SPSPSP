class PlotsModel {
  final int id;
  final String name;
  final String description;
  final String image;
  final List<String> images;
  final String location;
  final String coordinates;
  final String type;
  final String status;
  final int id_user;
  final String authorName;
  final String? authorAvatar;
  final double averageRating;

  PlotsModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.images = const [],
    required this.location,
    required this.coordinates,
    required this.type,
    required this.status,
    required this.id_user,
    required this.authorName,
    this.authorAvatar,
    this.averageRating = 0.0,
  });

  factory PlotsModel.fromJson(Map<String, dynamic> json) {
    return PlotsModel(
      id: json['id'] is int ? json['id'] : 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      images: json['images'] != null && json['images'] is List
          ? List<String>.from(
              (json['images'] as List).map((e) => e?.toString() ?? ''),
            )
          : [],
      location: (json['location'] ?? '').toString(),
      coordinates: (json['coordinates'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      id_user: json['id_user'] is int ? json['id_user'] : 0,
      authorName: (json['author_name'] ?? '').toString(),
      authorAvatar: json['author_avatar'],
      averageRating: _parseDouble(json['average_rating']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
