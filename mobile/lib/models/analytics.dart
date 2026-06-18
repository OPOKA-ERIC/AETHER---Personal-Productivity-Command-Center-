class AnalyticsSummary {
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final int scheduledMinutes;
  final int actualMinutes;
  final List<CategoryStat> categoryStats;
  final List<TrendPoint> trendData;
  final List<CoachingSuggestion> suggestions;

  AnalyticsSummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.scheduledMinutes,
    required this.actualMinutes,
    this.categoryStats = const [],
    this.trendData = const [],
    this.suggestions = const [],
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final cats = <CategoryStat>[];
    if (json['category_stats'] != null && json['category_stats'] is List) {
      for (final c in json['category_stats']) {
        cats.add(CategoryStat.fromJson(c));
      }
    }
    final trends = <TrendPoint>[];
    if (json['trend_data'] != null && json['trend_data'] is List) {
      for (final t in json['trend_data']) {
        trends.add(TrendPoint.fromJson(t));
      }
    }
    final tips = <CoachingSuggestion>[];
    if (json['suggestions'] != null && json['suggestions'] is List) {
      for (final s in json['suggestions']) {
        tips.add(CoachingSuggestion.fromJson(s));
      }
    }
    return AnalyticsSummary(
      totalTasks: json['total_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0).toDouble(),
      scheduledMinutes: json['scheduled_minutes'] ?? 0,
      actualMinutes: json['actual_minutes'] ?? 0,
      categoryStats: cats,
      trendData: trends,
      suggestions: tips,
    );
  }
}

class CategoryStat {
  final String category;
  final double scheduledHours;
  final double actualHours;

  CategoryStat({
    required this.category,
    required this.scheduledHours,
    required this.actualHours,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] ?? '',
      scheduledHours: (json['scheduled_hours'] ?? 0).toDouble(),
      actualHours: (json['actual_hours'] ?? 0).toDouble(),
    );
  }
}

class TrendPoint {
  final double focus;
  final double energy;
  final double adherence;
  final String date;

  TrendPoint({
    required this.focus,
    required this.energy,
    required this.adherence,
    required this.date,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      focus: (json['focus'] ?? 0).toDouble(),
      energy: (json['energy'] ?? 0).toDouble(),
      adherence: (json['adherence'] ?? 0).toDouble(),
      date: json['date'] ?? '',
    );
  }
}

class CoachingSuggestion {
  final String type;
  final String message;

  CoachingSuggestion({
    required this.type,
    required this.message,
  });

  factory CoachingSuggestion.fromJson(Map<String, dynamic> json) {
    return CoachingSuggestion(
      type: json['type'] ?? 'info',
      message: json['message'] ?? '',
    );
  }
}
