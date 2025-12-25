class LeaderboardUser {
  final int rank;
  final int id;
  final String name;
  final String? avatar;
  final int coins;

  LeaderboardUser({
    required this.rank,
    required this.id,
    required this.name,
    this.avatar,
    required this.coins,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      rank: json['rank'],
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      coins: json['coins'],
    );
  }
}
