class Social {
  final int id;
  final String platform;
  final String url;
  final int coins;
  final String status;
  final DateTime createdAt;

  Social({
    required this.id,
    required this.platform,
    required this.url,
    required this.coins,
    required this.status,
    required this.createdAt,
  });

  factory Social.fromJson(Map<String, dynamic> json) {
    return Social(
      id: json["id"],
      platform: json["social_plateform"],
      url: json["social_url"],
      coins: json["coins"],
      status: json["status"],
      createdAt: DateTime.parse(json["created_at"]),
    );
  }
}


