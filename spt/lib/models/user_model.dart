class UserModel {
  final int id;
  final String? avatar;
  final String first_name;
  final String last_name;
  final String? patronymic;
  final String email;
  final String? password;
  final bool banned;
  final int id_role;

  UserModel({
    required this.id,
    this.avatar,
    required this.first_name,
    required this.last_name,
    this.patronymic,
    required this.email,
    this.password,
    required this.banned,
    required this.id_role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      avatar: json['avatar'],
      first_name: json['first_name'],
      last_name: json['last_name'],
      patronymic: json['patronymic'],
      email: json['email'],
      password: json['password'],
      banned: json['banned'],
      id_role: json['id_role'],
    );
  }
}
