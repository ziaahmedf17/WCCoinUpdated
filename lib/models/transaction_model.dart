// class Transaction {
//   final int id;
//   final String type;
//   final String status;
//   final double amount;
//   final String description;
//   final DateTime createdAt;
//
//   Transaction({
//     required this.id,
//     required this.type,
//     required this.status,
//     required this.amount,
//     required this.description,
//     required this.createdAt,
//   });
//
//   factory Transaction.fromJson(Map<String, dynamic> json) {
//     return Transaction(
//       id: json['id'] ?? 0,
//       type: json['type'] ?? '',
//       status: json['status'] ?? '',
//       amount: (json['amount'] ?? 0).toDouble(),
//       description: json['description'] ?? '',
//       createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'type': type,
//       'status': status,
//       'amount': amount,
//       'description': description,
//       'created_at': createdAt.toIso8601String(),
//     };
//   }
// }


class Transaction {
  final int id;
  final String transactionId;
  final double withdrawCoins;
  final double totalUc;
  final String status;
  final String message;
  final String? transactionImageUrl;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.transactionId,
    required this.withdrawCoins,
    required this.totalUc,
    required this.status,
    required this.message,
    this.transactionImageUrl,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      transactionId: json['transaction_id'] ?? '',
      withdrawCoins: (json['withdraw_coins'] ?? 0).toDouble(),
      totalUc: (json['total_uc'] ?? 0).toDouble(),
      status: json['status'] ?? 'unknown',
      message: json['message'] ?? '',
      transactionImageUrl: json['transaction_image_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Backward compatibility properties for existing UI code
  String get type => 'withdrawal'; // Since this is withdrawal history
  String get description => message.isNotEmpty ? message : 'Withdrawal Transaction';
  double get amount => withdrawCoins;
}