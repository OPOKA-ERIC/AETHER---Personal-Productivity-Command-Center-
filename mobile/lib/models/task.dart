class Task {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? milestoneId;
  final bool alarmEnabled;
  final int actualMinutesSpent;
  final bool completed;
  final String? date;
  final String createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.milestoneId,
    this.alarmEnabled = true,
    this.actualMinutesSpent = 0,
    this.completed = false,
    this.date,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'personal',
      dayOfWeek: json['day_of_week'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      milestoneId: json['milestone_id'],
      alarmEnabled: json['alarm_enabled'] ?? true,
      actualMinutesSpent: json['actual_minutes_spent'] ?? 0,
      completed: json['completed'] ?? false,
      date: json['date'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'milestone_id': milestoneId,
    'alarm_enabled': alarmEnabled,
    'actual_minutes_spent': actualMinutesSpent,
    'completed': completed,
    'date': date,
  };
}
