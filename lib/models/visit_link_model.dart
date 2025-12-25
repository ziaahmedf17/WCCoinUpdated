class VisitLink {
  final int id;
  final String linkUrl;
  final int coins;
  final String status;
  final DateTime createdAt;
  // final DateTime updatedAt;

  VisitLink({
    required this.id,
    required this.linkUrl,
    required this.coins,
    required this.status,
    required this.createdAt,
    // required this.updatedAt,
  });

  factory VisitLink.fromJson(Map<String, dynamic> json) {
    return VisitLink(
      id: json['id'],
      linkUrl: json['link_url'],
      coins: json['coins'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      // updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
