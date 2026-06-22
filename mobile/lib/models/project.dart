import 'milestone.dart';

class Project {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<Milestone> milestones;
  final String createdAt;

  Project({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.milestones = const [],
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final ms = <Milestone>[];
    if (json['milestones'] != null && json['milestones'] is List) {
      for (final m in json['milestones']) {
        ms.add(Milestone.fromJson(m));
      }
    }
    return Project(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      milestones: ms,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
  };
}
