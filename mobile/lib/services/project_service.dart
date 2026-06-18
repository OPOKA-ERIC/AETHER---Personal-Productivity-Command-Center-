import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';
import 'supabase_service.dart';

class ProjectService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService().client;
  List<Project> _projects = [];
  bool _loading = false;

  List<Project> get projects => _projects;
  bool get loading => _loading;

  Future<void> fetchProjects() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _client
          .from('projects')
          .select('*, milestones(*)')
          .order('created_at', ascending: false);
      _projects = (data as List).map((j) => Project.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error fetching projects: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> createProject(String title, String? description) async {
    try {
      await _client.from('projects').insert({
        'title': title,
        'description': description,
      });
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to create project: $e';
    }
  }

  Future<String?> deleteProject(String id) async {
    try {
      await _client.from('projects').delete().eq('id', id);
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to delete project: $e';
    }
  }

  Future<String?> addMilestone(String projectId, String title, String? dueDate) async {
    try {
      await _client.from('milestones').insert({
        'project_id': projectId,
        'title': title,
        'due_date': dueDate,
      });
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to add milestone: $e';
    }
  }

  Future<String?> toggleMilestone(String id, bool completed) async {
    try {
      await _client.from('milestones').update({'completed': completed}).eq('id', id);
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to update milestone: $e';
    }
  }

  Future<String?> deleteMilestone(String id) async {
    try {
      await _client.from('milestones').delete().eq('id', id);
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to delete milestone: $e';
    }
  }
}
