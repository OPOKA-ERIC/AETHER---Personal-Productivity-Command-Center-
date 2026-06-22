class AnalyticsData {
  final AnalyticsSummary summary;
  final Map<String, CategoryStat> categoryStats;
  final Trends trends;
  final List<CoachingTip> suggestions;

  AnalyticsData({
    required this.summary,
    required this.categoryStats,
    required this.trends,
    required this.suggestions,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    final cats = <String, CategoryStat>{};
    if (json['categoryStats'] != null && json['categoryStats'] is Map) {
      (json['categoryStats'] as Map).forEach((key, val) {
        cats[key] = CategoryStat.fromJson(val);
      });
    }
    final tips = <CoachingTip>[];
    if (json['suggestions'] != null && json['suggestions'] is List) {
      for (final s in json['suggestions']) {
        tips.add(CoachingTip.fromJson(s));
      }
    }
    return AnalyticsData(
      summary: AnalyticsSummary.fromJson(json['summary'] ?? {}),
      categoryStats: cats,
      trends: Trends.fromJson(json['trends'] ?? {}),
      suggestions: tips,
    );
  }
}

class AnalyticsSummary {
  final int totalTasks;
  final int completedTasks;
  final int completionRate;
  final int scheduledMinutes;
  final int actualMinutes;

  AnalyticsSummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.scheduledMinutes,
    required this.actualMinutes,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: json['completionRate'] ?? 0,
      scheduledMinutes: json['scheduledMinutes'] ?? 0,
      actualMinutes: json['actualMinutes'] ?? 0,
    );
  }
}

class CategoryStat {
  final int scheduled;
  final int actual;
  final int tasksCount;
  final int completedCount;

  CategoryStat({
    required this.scheduled,
    required this.actual,
    required this.tasksCount,
    required this.completedCount,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      scheduled: json['scheduled'] ?? 0,
      actual: json['actual'] ?? 0,
      tasksCount: json['tasksCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
    );
  }
}

class Trends {
  final List<TrendPoint> focusTrend;
  final List<TrendPoint> energyTrend;
  final List<TrendPoint> adherenceTrend;

  Trends({
    required this.focusTrend,
    required this.energyTrend,
    required this.adherenceTrend,
  });

  factory Trends.fromJson(Map<String, dynamic> json) {
    return Trends(
      focusTrend: _parseTrend(json['focusTrend']),
      energyTrend: _parseTrend(json['energyTrend']),
      adherenceTrend: _parseTrend(json['adherenceTrend']),
    );
  }

  static List<TrendPoint> _parseTrend(dynamic arr) {
    final list = <TrendPoint>[];
    if (arr is List) {
      for (final item in arr) {
        list.add(TrendPoint.fromJson(item));
      }
    }
    return list;
  }
}

class TrendPoint {
  final String date;
  final int score;

  TrendPoint({required this.date, required this.score});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] ?? '',
      score: json['score'] ?? 0,
    );
  }
}

class CoachingTip {
  final String type;
  final String title;
  final String text;

  CoachingTip({
    required this.type,
    required this.title,
    required this.text,
  });

  factory CoachingTip.fromJson(Map<String, dynamic> json) {
    return CoachingTip(
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      text: json['text'] ?? '',
    );
  }
}
