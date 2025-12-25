class Announcement {
  final int id;
  final String title;
  final String type;
  final String? details; // Added details field
  final String status;
  final String createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.type,
    this.details, // Made optional as it might be null
    required this.status,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      details: json['details'], // Added details parsing
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}
