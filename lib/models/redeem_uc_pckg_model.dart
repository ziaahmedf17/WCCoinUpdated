class Package {
  final int id;
  final int coins;
  final int ucValue;
  final String status;
  final String createdAt;
  final String updatedAt;

  Package({
    required this.id,
    required this.coins,
    required this.ucValue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'],
      coins: json['coins'],
      ucValue: json['uc_value'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}