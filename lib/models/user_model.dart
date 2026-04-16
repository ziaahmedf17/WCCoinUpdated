

class UserModel {
  final int id;
  final String name;
  final String email;
  final String avatar;
  final String googleId;
  final int coins;
  final String referralCode;
  final int totalRedeem;
  final String status;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.googleId,
    required this.coins,
    required this.referralCode,
    required this.totalRedeem,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;

    return UserModel(
      id: user['id'] ?? 0,
      name: user['name'] ?? '',
      email: user['email'] ?? '',
      avatar: user['avatar'] ?? '',
      googleId: user['google_id'] ?? '',
      coins: user['coins'] ?? 0,
      referralCode: user['referral_code'] ?? '',
      totalRedeem: user['total_radeem'] ?? 0,
      status: user['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'google_id': googleId,
      'coins': coins,
      'referral_code': referralCode,
      'total_radeem': totalRedeem, // keep original key to match fromJson
      'status': status,
    };
  }
}
