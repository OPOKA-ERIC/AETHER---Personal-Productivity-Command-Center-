class Milestone {
  final String id;
  final String userId;
  final String projectId;
  final String title;
  final String? dueDate;
  final bool completed;
  final String createdAt;

  Milestone({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.title,
    this.dueDate,
    this.completed = false,
    required this.createdAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      projectId: json['project_id'] ?? '',
      title: json['title'] ?? '',
      dueDate: json['due_date'],
      completed: json['completed'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'due_date': dueDate,
    'completed': completed,
  };
}
