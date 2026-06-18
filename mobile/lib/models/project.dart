import 'milestone.dart';

class Project {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String status;
  final String createdAt;
  final List<Milestone> milestones;

  Project({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.status = 'active',
    required this.createdAt,
    this.milestones = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final milestoneList = <Milestone>[];
    if (json['milestones'] != null && json['milestones'] is List) {
      for (final m in json['milestones']) {
        milestoneList.add(Milestone.fromJson(m));
      }
    }
    return Project(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] ?? '',
      milestones: milestoneList,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'status': status,
  };

  double get completionPercent {
    if (milestones.isEmpty) return 0;
    final done = milestones.where((m) => m.completed).length;
    return done / milestones.length;
  }
}
