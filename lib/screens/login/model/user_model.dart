

// User model to handle the response
class User {
  final int id;
  final String name;
  final String email;
  final String? googleId;
  final String? avatar;
  final String status;
  final int coins;
  final int totalRedeem;
  final int totalPurchased;
  final String referralCode;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.googleId,
    this.avatar,
    required this.status,
    required this.coins,
    required this.totalRedeem,
    required this.totalPurchased,
    required this.referralCode,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      googleId: json['google_id'],
      avatar: json['avatar'],
      status: json['status'] ?? 'active',
      coins: json['coins'] ?? 0,
      totalRedeem: json['total_radeem'] ?? 0,
      totalPurchased: json['total_purchased'] ?? 0,
      referralCode: json['referral_code'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'google_id': googleId,
      'avatar': avatar,
      'status': status,
      'coins': coins,
      'total_radeem': totalRedeem,
      'total_purchased': totalPurchased,
      'referral_code': referralCode,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
// // User model to handle the response
// class User {
//   final int id;
//   final String name;
//   final String email;
//   final String googleId;
//   final String avatar;
//   final String status;
//   final int coins;
//   final int totalRedeem;
//   final String referralCode;
//   final String createdAt;
//   final String updatedAt;
//
//   User({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.googleId,
//     required this.avatar,
//     required this.status,
//     required this.coins,
//     required this.totalRedeem,
//     required this.referralCode,
//     required this.createdAt,
//     required this.updatedAt,
//   });
//
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['id'],
//       name: json['name'],
//       email: json['email'],
//       googleId: json['google_id'],
//       avatar: json['avatar'],
//       status: json['status'],
//       coins: json['coins'],
//       totalRedeem: json['total_radeem'],
//       referralCode: json['referral_code'],
//       createdAt: json['created_at'],
//       updatedAt: json['updated_at'],
//     );
//   }
// }


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
