class CommentModel {
  final int id;
  final int idPlace;
  final int idUser;
  final int estimation;
  final String comment;
  final String authorName;
  final String? authorAvatar;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.idPlace,
    required this.idUser,
    required this.estimation,
    required this.comment,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? 0,
      idPlace: json['id_place'] ?? 0,
      idUser: json['id_user'] ?? 0,
      estimation: json['estimation'] ?? 0,
      comment: json['comment'] ?? '',
      authorName: json['author_name'] ?? '',
      authorAvatar: json['author_avatar'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
