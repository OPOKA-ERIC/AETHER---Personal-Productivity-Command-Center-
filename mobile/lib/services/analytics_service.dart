import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics.dart';
import 'supabase_service.dart';

class AnalyticsService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService().client;
  AnalyticsSummary? _summary;
  bool _loading = false;

  AnalyticsSummary? get summary => _summary;
  bool get loading => _loading;

  Future<void> fetchAnalytics() async {
    _loading = true;
    notifyListeners();
    try {
      final session = _client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null) {
        _loading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('https://aether-personal-productivity-command.onrender.com/api/analytics'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        _summary = AnalyticsSummary.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
    }
    _loading = false;
    notifyListeners();
  }
}
