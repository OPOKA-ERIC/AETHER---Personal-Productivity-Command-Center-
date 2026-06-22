import 'package:flutter/foundation.dart';
import '../models/reflection.dart';
import 'api_service.dart';

class ReflectionService extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Reflection> _reflections = [];
  bool _loading = false;

  List<Reflection> get reflections => _reflections;
  bool get loading => _loading;

  Future<void> fetchReflections() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get('/reflections');
      _reflections = data.map((j) => Reflection.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching reflections: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> saveReflection(Map<String, dynamic> data) async {
    try {
      await _api.post('/reflections', data);
      await fetchReflections();
      return null;
    } catch (e) {
      return 'Failed to save reflection: $e';
    }
  }
}
