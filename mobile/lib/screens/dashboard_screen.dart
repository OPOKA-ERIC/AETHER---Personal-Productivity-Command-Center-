import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/analytics_service.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/task_timeline_tile.dart';
import '../widgets/coaching_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  final Map<String, Stopwatch> _stopwatches = {};
  final Map<String, Timer> _uiTimers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskService>().fetchTasks();
      context.read<AnalyticsService>().fetchAnalytics();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      context.read<AnalyticsService>().fetchAnalytics();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final t in _uiTimers.values) { t.cancel(); }
    super.dispose();
  }

  void _toggleTimer(Task task) {
    if (_stopwatches.containsKey(task.id)) {
      final sw = _stopwatches[task.id]!;
      if (sw.isRunning) {
        sw.stop();
        _uiTimers[task.id]?.cancel();
      } else {
        sw.start();
        _uiTimers[task.id] = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
      }
    } else {
      final sw = Stopwatch()..start();
      _stopwatches[task.id] = sw;
      _uiTimers[task.id] = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
    setState(() {});
  }

  void _markDone(Task task) {
    final sw = _stopwatches[task.id];
    final minutes = sw != null ? (sw.elapsed.inSeconds ~/ 60) : 0;
    _stopwatches.remove(task.id);
    _uiTimers[task.id]?.cancel();
    _uiTimers.remove(task.id);
    context.read<TaskService>().markCompleted(task.id, minutes);
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final analyticsService = context.watch<AnalyticsService>();
    final tasks = taskService.todaysTasks;
    final summary = analyticsService.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good ${_timeOfDay()}.', style: GoogleFonts.outfit(
            fontSize: 28, fontWeight: FontWeight.w600, color: AetherColors.textBright,
          )),
          const SizedBox(height: 4),
          Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: const TextStyle(color: AetherColors.textMuted, fontSize: 14)),
          const SizedBox(height: 20),
          if (summary != null) ...[
            Row(
              children: [
                Expanded(child: _metricCard('Adherence', '${summary.completionRate.toStringAsFixed(0)}%', AetherColors.emerald)),
                const SizedBox(width: 12),
                Expanded(child: _metricCard('Completed', '${summary.completedTasks}/${summary.totalTasks}', AetherColors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _metricCard('Hours', '${(summary.actualMinutes / 60).toStringAsFixed(1)}h', AetherColors.cyan)),
              ],
            ),
            const SizedBox(height: 20),
          ],
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Schedule",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                const SizedBox(height: 12),
                tasks.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No tasks scheduled today', style: TextStyle(color: AetherColors.textMuted))),
                      )
                    : Column(
                        children: tasks.map((task) {
                          final sw = _stopwatches[task.id];
                          final isRunning = sw?.isRunning ?? false;
                          final elapsed = sw?.elapsed;
                          return TaskTimelineTile(
                            task: task,
                            isActive: isRunning,
                            elapsedText: elapsed != null ? _formatDuration(elapsed) : null,
                            onStart: !task.completed && !isRunning ? () => _toggleTimer(task) : null,
                            onPause: isRunning ? () => _toggleTimer(task) : null,
                            onResume: !task.completed && sw != null && !isRunning ? () => _toggleTimer(task) : null,
                            onDone: !task.completed && sw != null ? () => _markDone(task) : null,
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (summary != null && summary.suggestions.isNotEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Habit Coach',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                  const SizedBox(height: 12),
                  ...summary.suggestions.map((s) => CoachingCard(suggestion: s)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeOfDay() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _metricCard(String label, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class QuickAddTaskSheet extends StatefulWidget {
  const QuickAddTaskSheet({super.key});

  @override
  State<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends State<QuickAddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _startCtrl = TextEditingController(text: '09:00');
  final _endCtrl = TextEditingController(text: '10:00');
  String _category = 'coding';
  String _day = DateFormat('EEEE').format(DateTime.now()).toLowerCase();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = AetherColors.categoryColors.keys.toList();
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Add Task',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Task title', prefixIcon: Icon(Icons.task_alt, size: 20)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Day', prefixIcon: Icon(Icons.calendar_today, size: 20)),
            items: days.map((d) => DropdownMenuItem(value: d, child: Text(d[0].toUpperCase() + d.substring(1)))).toList(),
            onChanged: (v) => setState(() => _day = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(
                controller: _startCtrl,
                decoration: const InputDecoration(labelText: 'Start', prefixIcon: Icon(Icons.schedule, size: 20)),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _endCtrl,
                decoration: const InputDecoration(labelText: 'End', prefixIcon: Icon(Icons.schedule, size: 20)),
              )),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.label, size: 20)),
            items: categories.map((c) => DropdownMenuItem(
              value: c,
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: AetherColors.categoryColor(c), shape: BoxShape.circle,
                )),
                const SizedBox(width: 8),
                Text(c[0].toUpperCase() + c.substring(1)),
              ]),
            )).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.isNotEmpty) {
                  context.read<TaskService>().createTask(Task(
                    id: '',
                    userId: '',
                    title: _titleCtrl.text.trim(),
                    category: _category,
                    dayOfWeek: _day,
                    startTime: _startCtrl.text.trim(),
                    endTime: _endCtrl.text.trim(),
                    createdAt: DateTime.now().toIso8601String(),
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Task'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
