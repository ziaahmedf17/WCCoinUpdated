// class Quiz {
//   final int id;
//   final String question;
//   final int rewardCoin;
//   final String status;
//   final List<QuizOption> options;
//
//   Quiz({
//     required this.id,
//     required this.question,
//     required this.rewardCoin,
//     required this.status,
//     required this.options,
//   });
//
//   factory Quiz.fromJson(Map<String, dynamic> json) {
//     return Quiz(
//       id: json["id"],
//       question: json["question"],
//       rewardCoin: json["reward_coin"],
//       status: json["status"],
//       options:
//       (json["options"] as List).map((e) => QuizOption.fromJson(e)).toList(),
//     );
//   }
// }
//
//
// class QuizOption {
//   final int id;
//   final String text;
//
//   QuizOption({
//     required this.id,
//     required this.text,
//   });
//
//   factory QuizOption.fromJson(Map<String, dynamic> json) {
//     return QuizOption(
//       id: json["id"],
//       text: json["option_text"],
//     );
//   }
// }



class Quiz {
  final int id;
  final String question;
  final int rewardCoin;
  final String status;
  final List<QuizOption> options;

  Quiz({
    required this.id,
    required this.question,
    required this.rewardCoin,
    required this.status,
    required this.options,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json["id"],
      question: json["question"],
      rewardCoin: json["reward_coin"],
      status: json["status"],
      options: (json["options"] as List)
          .map((e) => QuizOption.fromJson(e))
          .toList(),
    );
  }
}

class QuizOption {
  final int id;
  final String text;

  QuizOption({
    required this.id,
    required this.text,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json["id"],
      text: json["option_text"],
    );
  }
}
