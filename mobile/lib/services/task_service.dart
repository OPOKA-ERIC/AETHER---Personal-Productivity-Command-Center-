import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import 'supabase_service.dart';

class TaskService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService().client;
  List<Task> _tasks = [];
  bool _loading = false;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;

  List<Task> tasksForDay(String dayOfWeek) {
    return _tasks
        .where((t) => t.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase())
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<Task> get todaysTasks {
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final today = DateTime.now().weekday - 1;
    return tasksForDay(dayNames[today]);
  }

  Future<void> fetchTasks() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _client
          .from('tasks')
          .select()
          .order('start_time');
      _tasks = (data as List).map((j) => Task.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> createTask(Task task) async {
    try {
      await _client.from('tasks').insert(task.toJson());
      await fetchTasks();
      return null;
    } catch (e) {
      return 'Failed to create task: $e';
    }
  }

  Future<String?> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('tasks').update(updates).eq('id', id);
      await fetchTasks();
      return null;
    } catch (e) {
      return 'Failed to update task: $e';
    }
  }

  Future<String?> deleteTask(String id) async {
    try {
      await _client.from('tasks').delete().eq('id', id);
      await fetchTasks();
      return null;
    } catch (e) {
      return 'Failed to delete task: $e';
    }
  }

  Future<String?> markCompleted(String id, int minutesSpent) async {
    return updateTask(id, {
      'completed': true,
      'actual_minutes_spent': minutesSpent,
    });
  }

  Future<void> resetWeeklyCompletions() async {
    try {
      await _client
          .from('tasks')
          .update({'completed': false, 'actual_minutes_spent': 0})
          .eq('completed', true);
      await fetchTasks();
    } catch (e) {
      debugPrint('Error resetting tasks: $e');
    }
  }
}
