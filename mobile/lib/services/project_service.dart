import 'package:flutter/foundation.dart';
import '../models/project.dart';
import 'api_service.dart';

class ProjectService extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Project> _projects = [];
  bool _loading = false;

  List<Project> get projects => _projects;
  bool get loading => _loading;

  Future<void> fetchProjects() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get('/projects');
      _projects = data.map((j) => Project.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching projects: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> createProject(String title, String description) async {
    try {
      await _api.post('/projects', {'title': title, 'description': description});
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to create project: $e';
    }
  }

  Future<String?> deleteProject(String id) async {
    try {
      await _api.delete('/projects/$id');
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to delete project: $e';
    }
  }

  Future<String?> createMilestone(String projectId, String title, String? dueDate) async {
    try {
      await _api.post('/projects/$projectId/milestones', {
        'title': title,
        'due_date': dueDate,
      });
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to create milestone: $e';
    }
  }

  Future<String?> toggleMilestone(String id, bool completed) async {
    try {
      await _api.put('/milestones/$id', {'completed': completed});
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to update milestone: $e';
    }
  }

  Future<String?> deleteMilestone(String id) async {
    try {
      await _api.delete('/milestones/$id');
      await fetchProjects();
      return null;
    } catch (e) {
      return 'Failed to delete milestone: $e';
    }
  }
}
