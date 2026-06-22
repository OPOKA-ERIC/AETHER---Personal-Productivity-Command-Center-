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
    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      return false;
    }
    return Task(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'personal',
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      milestoneId: json['milestone_id']?.toString(),
      alarmEnabled: _toBool(json['alarm_enabled']),
      actualMinutesSpent: (json['actual_minutes_spent'] ?? 0) is int
          ? json['actual_minutes_spent'] as int
          : int.tryParse(json['actual_minutes_spent']?.toString() ?? '') ?? 0,
      completed: _toBool(json['completed']),
      date: json['date']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
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
