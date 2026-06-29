import 'package:flutter/foundation.dart';
import '../models/task.dart';
import 'api_service.dart';

class TaskService extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Task> _tasks = [];
  bool _loading = false;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;

  List<Task> tasksForDay(String dayOfWeek, {String? date}) {
    return _tasks
        .where((t) {
          final dayMatch = t.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase();
          if (date != null && t.date != null && t.date!.isNotEmpty) {
            return dayMatch && t.date == date;
          }
          return dayMatch;
        })
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<Task> get todaysTasks {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final todayName = days[now.weekday - 1];
    return _tasks
        .where((t) {
          final dayMatch = t.dayOfWeek.toLowerCase() == todayName;
          if (t.date != null && t.date!.isNotEmpty) {
            return dayMatch && t.date == dateStr;
          }
          return dayMatch;
        })
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> fetchTasks() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get('/tasks');
      _tasks = data.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> createTask(Task task) async {
    try {
      await _api.post('/tasks', task.toJson());
      await fetchTasks();
      return null;
    } catch (e) {
      return 'Failed to create task: $e';
    }
  }

  Future<String?> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      await _api.put('/tasks/$id', updates);
      await fetchTasks();
      return null;
    } catch (e) {
      return 'Failed to update task: $e';
    }
  }

  Future<String?> deleteTask(String id) async {
    try {
      await _api.delete('/tasks/$id');
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
      for (final task in _tasks.where((t) => t.completed)) {
        await updateTask(task.id, {'completed': false, 'actual_minutes_spent': 0});
      }
      await fetchTasks();
    } catch (e) {
      debugPrint('Error resetting tasks: $e');
    }
  }
}
