import 'package:flutter/foundation.dart';
import '../models/analytics.dart';
import 'api_service.dart';

class AnalyticsService extends ChangeNotifier {
  final ApiService _api = ApiService();
  AnalyticsData? _data;
  bool _loading = false;

  AnalyticsData? get data => _data;
  bool get loading => _loading;

  AnalyticsSummary? get summary => _data?.summary;
  List<CoachingTip> get suggestions => _data?.suggestions ?? [];
  Trends? get trends => _data?.trends;
  Map<String, CategoryStat> get categoryStats => _data?.categoryStats ?? {};

  Future<void> fetchAnalytics() async {
    _loading = true;
    notifyListeners();
    try {
      final raw = await _api.getSingle('/analytics');
      _data = AnalyticsData.fromJson(raw);
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
    }
    _loading = false;
    notifyListeners();
  }
}
