
// User model to handle the response
class User {
  final int id;
  final String name;
  final String email;
  final String googleId;
  final String avatar;
  final String status;
  final int coins;
  final int totalRedeem;
  final String referralCode;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.googleId,
    required this.avatar,
    required this.status,
    required this.coins,
    required this.totalRedeem,
    required this.referralCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      googleId: json['google_id'],
      avatar: json['avatar'],
      status: json['status'],
      coins: json['coins'],
      totalRedeem: json['total_radeem'],
      referralCode: json['referral_code'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}


class LoginResponse {
  final User user;
  final String token;

  LoginResponse({
    required this.user,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user']),
      token: json['token'],
    );
  }
}
