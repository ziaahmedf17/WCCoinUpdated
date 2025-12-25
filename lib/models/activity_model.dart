// class Activity {
//   final int id;
//   final String logName;
//   final String description;
//   final Map<String, dynamic> properties;
//   final DateTime createdAt;

//   Activity({
//     required this.id,
//     required this.logName,
//     required this.description,
//     required this.properties,
//     required this.createdAt,
//   });

//   factory Activity.fromJson(Map<String, dynamic> json) {
//     return Activity(
//       id: json['id'],
//       logName: json['log_name'],
//       description: json['description'],
//       properties: json['properties'] is Map<String, dynamic>
//           ? json['properties']
//           : {},
//       createdAt: DateTime.parse(json['created_at']),
//     );
//   }
// }




// activity_model.dart
class Activity {
  final int id;
  final String logName;
  final String description;
  final Map<String, dynamic> properties;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.logName,
    required this.description,
    required this.properties,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      logName: json['log_name'],
      description: json['description'],
      properties: json['properties'] is Map<String, dynamic>
          ? json['properties']
          : (json['properties'] is List && (json['properties'] as List).isEmpty)
              ? <String, dynamic>{}
              : json['properties'] ?? <String, dynamic>{},
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ActivityResponse {
  final List<Activity> data;
  final ActivityMeta meta;

  ActivityResponse({
    required this.data,
    required this.meta,
  });

  factory ActivityResponse.fromJson(Map<String, dynamic> json) {
    return ActivityResponse(
      data: (json['data'] as List)
          .map<Activity>((e) => Activity.fromJson(e))
          .toList(),
      meta: ActivityMeta.fromJson(json['meta']),
    );
  }
}

class ActivityMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  ActivityMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory ActivityMeta.fromJson(Map<String, dynamic> json) {
    return ActivityMeta(
      currentPage: json['current_page'],
      perPage: json['per_page'],
      total: json['total'],
      lastPage: json['last_page'],
    );
  }
}