// class UserModel {
//   final String name;
//   final String email;
//   final String avatar;
//   final int coins;
//   final int totalRedeem;
//
//   UserModel({
//     required this.name,
//     required this.email,
//     required this.avatar,
//     required this.coins,
//     required this.totalRedeem,
//   });
//
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       name: json['name'] ?? '',
//       email: json['email'] ?? '',
//       avatar: json['avatar'] ?? '',
//       coins: json['coins'] ?? 0,
//       totalRedeem: json['total_radeem'] ?? 0,
//     );
//   }
// }


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
    final user = json['user'] ?? json; // handles if 'user' key exists

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
}
