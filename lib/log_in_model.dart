class Loginmodel{
  final String id;
  final String password;

  Loginmodel({
    required this.id,
    required this.password,
  });
  factory Loginmodel.fromJson(Map<String, dynamic> json) {
    return Loginmodel(
      id: json['id'],
      password: json['password'],
    );
  }
}