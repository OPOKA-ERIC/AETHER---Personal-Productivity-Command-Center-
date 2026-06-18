import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reflection.dart';
import 'supabase_service.dart';

class ReflectionService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService().client;
  List<Reflection> _reflections = [];
  bool _loading = false;

  List<Reflection> get reflections => _reflections;
  bool get loading => _loading;

  Future<void> fetchReflections() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _client
          .from('reflections')
          .select()
          .order('date', ascending: false);
      _reflections = (data as List).map((j) => Reflection.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error fetching reflections: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> saveReflection(Reflection reflection) async {
    try {
      await _client.from('reflections').upsert(reflection.toJson(),
          onConflict: 'date,user_id');
      await fetchReflections();
      return null;
    } catch (e) {
      return 'Failed to save reflection: $e';
    }
  }
}
