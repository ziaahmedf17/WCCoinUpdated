class RewardsModel {
  final int daily;
  final int hourly;
  final int social;
  final int link;
  final int promocode;
  final int ads;

  RewardsModel({
    required this.daily,
    required this.hourly,
    required this.social,
    required this.link,
    required this.promocode,
    required this.ads,
  });

  factory RewardsModel.fromJson(Map<String, dynamic> json) {
    return RewardsModel(
      daily: json['daily'] ?? 0,
      hourly: json['hourly'] ?? 0,
      social: json['social'] ?? 0,
      link: json['link'] ?? 0,
      promocode: json['promocode'] ?? 0,
      ads: json['ads'] ?? 0,
    );
  }

  /// Fallback defaults if API fails
  factory RewardsModel.defaults() {
    return RewardsModel(
      daily: 0,
      hourly: 0,
      social: 0,
      link: 0,
      promocode: 0,
      ads: 0,
    );
  }
}
