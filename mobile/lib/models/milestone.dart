class Milestone {
  final String id;
  final String projectId;
  final String userId;
  final String title;
  final String? dueDate;
  final bool completed;

  Milestone({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.title,
    this.dueDate,
    this.completed = false,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      dueDate: json['due_date'],
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'due_date': dueDate,
    'completed': completed,
  };
}
