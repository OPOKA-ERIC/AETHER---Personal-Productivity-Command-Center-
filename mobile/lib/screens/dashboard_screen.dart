import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/project_service.dart';
import '../services/analytics_service.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/coaching_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  Timer? _activeTimer;
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
    _activeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _activeTimer?.cancel();
    for (final t in _uiTimers.values) { t.cancel(); }
    super.dispose();
  }

  void _toggleTimer(Task task) {
    if (_stopwatches.containsKey(task.id)) {
      final sw = _stopwatches[task.id]!;
      sw.isRunning ? sw.stop() : sw.start();
      if (sw.isRunning) {
        _uiTimers[task.id] = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
      } else {
        _uiTimers[task.id]?.cancel();
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

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  String _fmtElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.watch<TaskService>();
    final as = context.watch<AnalyticsService>();
    final tasks = ts.todaysTasks;
    final summary = as.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(summary?.summary),
          const SizedBox(height: 16),
          _buildScheduleFlow(tasks),
          const SizedBox(height: 16),
          _buildQuickAdd(),
          const SizedBox(height: 16),
          if (summary != null && summary.suggestions.isNotEmpty)
            _buildCoachInsights(summary.suggestions),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHero(dynamic s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x1E8B5CF6), Color(0x0D06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AetherColors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ready to crush your goals today?",
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AetherColors.textBright)),
          const SizedBox(height: 4),
          Text('Welcome to Sunday Planning season. Keep following your blocks and track your study milestones.',
              style: const TextStyle(fontSize: 13, color: AetherColors.textMuted)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statCard('${s?.completionRate ?? 0}%', 'Plan Adherence')),
              const SizedBox(width: 12),
              Expanded(child: _statCard(
                s != null ? '${(s.actualMinutes / 60).toStringAsFixed(1)}h' : '0h',
                'Productive Time',
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x59130E26),
        border: Border.all(color: AetherColors.glassBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AetherColors.textBright)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildScheduleFlow(List<Task> tasks) {
    final todayName = DateFormat('EEEE').format(DateTime.now());
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.hourglass_bottom, color: AetherColors.purple, size: 18),
                const SizedBox(width: 8),
                Text("Today's Schedule Flow",
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AetherColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AetherColors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Text(todayName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AetherColors.purple)),
                ),
              ],
            ),
          ),
          tasks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.calendar_month, color: AetherColors.textMuted, size: 40),
                        SizedBox(height: 8),
                        Text('No tasks scheduled for today.',
                            style: TextStyle(color: AetherColors.textMuted, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Head to the Weekly Planner to time-block your week!',
                            style: TextStyle(color: AetherColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) => _timelineItem(tasks[i]),
                ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext ctx, Task task) {
    final titleCtrl = TextEditingController(text: task.title);
    String category = task.category;
    bool alarm = task.alarmEnabled;
    bool completed = task.completed;
    final actualCtrl = TextEditingController(text: task.actualMinutesSpent.toString());

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1530),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final categories = AetherColors.categoryColors.keys.toList();
        return StatefulBuilder(builder: (ctx, setInnerState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modify Time Block',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Task title...')),
                const SizedBox(height: 10),
                Autocomplete<String>(
                  optionsBuilder: (val) {
                    if (val.text.isEmpty) return categories;
                    return categories.where((c) => c.toLowerCase().contains(val.text.toLowerCase()));
                  },
                  initialValue: TextEditingValue(text: category),
                  onSelected: (v) => category = v,
                  fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
                    ctrl.text = category;
                    return TextField(
                      controller: ctrl, focusNode: focusNode,
                      style: const TextStyle(fontSize: 13, color: AetherColors.textBright),
                      decoration: InputDecoration(
                        labelText: 'Category', hintText: 'e.g. coding, study...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 12, height: 12, margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AetherColors.categoryColor(ctrl.text), shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (v) => category = v,
                    );
                  },
                  optionsViewBuilder: (ctx, onSelected, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                      decoration: BoxDecoration(
                        color: Color(0xFF0C091A), borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AetherColors.glassBorder),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (ctx, i) {
                          final cat = options.elementAt(i);
                          return InkWell(
                            onTap: () => onSelected(cat),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: AetherColors.categoryColor(cat), shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Text(cat[0].toUpperCase() + cat.substring(1),
                                    style: const TextStyle(color: AetherColors.textBright, fontSize: 13)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(width: 18, height: 18,
                      child: Checkbox(
                        value: alarm,
                        onChanged: (v) => setInnerState(() => alarm = v!),
                        fillColor: WidgetStateProperty.resolveWith((_) => AetherColors.rose),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.notifications_outlined, color: AetherColors.textMuted, size: 14),
                    const SizedBox(width: 2),
                    const Text('Alarm', style: TextStyle(fontSize: 12, color: AetherColors.textMuted)),
                    const Spacer(),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: actualCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Min spent', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(width: 18, height: 18,
                      child: Checkbox(
                        value: completed,
                        onChanged: (v) => setInnerState(() => completed = v!),
                        fillColor: WidgetStateProperty.resolveWith((_) => AetherColors.emerald),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_outline, color: AetherColors.textMuted, size: 14),
                    const SizedBox(width: 2),
                    const Text('Completed', style: TextStyle(fontSize: 12, color: AetherColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Delete task?'),
                              content: Text('"${task.title}" will be gone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Delete', style: TextStyle(color: AetherColors.rose))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await context.read<TaskService>().deleteTask(task.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 16, color: AetherColors.rose),
                        label: const Text('Delete', style: TextStyle(color: AetherColors.rose, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AetherColors.rose),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleCtrl.text.trim().isNotEmpty) {
                              final err = await context.read<TaskService>().updateTask(task.id, {
                                'title': titleCtrl.text.trim(),
                                'category': category,
                                'alarm_enabled': alarm,
                                'completed': completed,
                                'actual_minutes_spent': int.tryParse(actualCtrl.text.trim()) ?? 0,
                              });
                              if (err != null && ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err)));
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _timelineItem(Task task) {
    final color = AetherColors.categoryColor(task.category);
    final active = task.isActive();
    final sw = _stopwatches[task.id];
    final running = sw?.isRunning ?? false;
    final paused = sw != null && !sw.isRunning;
    final elapsed = sw?.elapsed;
    final elapsedSecs = task.actualMinutesSpent * 60;

    return GestureDetector(
      onTap: () => _showEditTaskDialog(context, task),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(task.startTime,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600, color: AetherColors.textMuted),
                    textAlign: TextAlign.right),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 14,
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: active
                          ? AetherColors.rose
                          : (task.completed ? AetherColors.emerald : AetherColors.textMuted),
                      shape: BoxShape.circle,
                      border: Border.all(color: AetherColors.bg, width: 2),
                      boxShadow: active
                          ? [BoxShadow(color: AetherColors.rose.withValues(alpha: 0.4), blurRadius: 6)]
                          : (task.completed
                              ? [BoxShadow(color: AetherColors.emerald.withValues(alpha: 0.4), blurRadius: 6)]
                              : null),
                    ),
                  ),
                  Expanded(child: Container(width: 2, color: AetherColors.glassBorder)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x05FFFFFF),
                    border: Border(
                      left: BorderSide(color: active ? AetherColors.rose : color, width: 3),
                      top: const BorderSide(color: AetherColors.glassBorder),
                      right: const BorderSide(color: AetherColors.glassBorder),
                      bottom: const BorderSide(color: AetherColors.glassBorder),
                    ),
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(task.title,
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                  color: task.completed ? AetherColors.textMuted : AetherColors.textBright,
                                  decoration: task.completed ? TextDecoration.lineThrough : null,
                              ))),
                        if (active)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AetherColors.rose.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AetherColors.rose, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AetherColors.rose)),
                                ],
                              ),
                            ),
                          ),
                        if (task.completed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AetherColors.emerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: AetherColors.emerald, size: 14),
                                SizedBox(width: 4),
                                Text('Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AetherColors.emerald)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(task.category,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, color: AetherColors.textMuted, size: 11),
                        const SizedBox(width: 3),
                        Text('${task.startTime} – ${task.endTime}',
                            style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
                        const SizedBox(width: 12),
                        if (!task.completed) ...[
                          const Icon(Icons.alarm, color: AetherColors.textMuted, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            elapsed != null ? _fmt(elapsed) : _fmtElapsed(elapsedSecs),
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AetherColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                    if (!task.completed) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!running && !paused)
                            _timerBtn(Icons.play_arrow, 'Start', AetherColors.emerald, () => _toggleTimer(task)),
                          if (running)
                            _timerBtn(Icons.pause, 'Pause', AetherColors.amber, () => _toggleTimer(task)),
                          if (paused)
                            _timerBtn(Icons.play_arrow, 'Resume', AetherColors.cyan, () => _toggleTimer(task)),
                          const SizedBox(width: 4),
                          _timerBtn(Icons.check, 'Done', AetherColors.purple, () => _markDone(task)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ],
          ),
        ),
      ),
      );
  }

  Widget _timerBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAdd() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AetherColors.rose, size: 18),
              const SizedBox(width: 8),
              Text('Inject Task Into Schedule',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
            ],
          ),
          const SizedBox(height: 12),
          _QuickAddForm(onAdded: () {
            context.read<TaskService>().fetchTasks();
            context.read<AnalyticsService>().fetchAnalytics();
          }),
        ],
      ),
    );
  }

  Widget _buildCoachInsights(List<dynamic> suggestions) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AetherColors.emerald, size: 18),
              const SizedBox(width: 8),
              Text('Habit Coach Insights',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map((s) => CoachingCard(tip: s)),
        ],
      ),
    );
  }
}

class _QuickAddForm extends StatefulWidget {
  final VoidCallback onAdded;
  const _QuickAddForm({required this.onAdded});

  @override
  State<_QuickAddForm> createState() => _QuickAddFormState();
}

class _QuickAddFormState extends State<_QuickAddForm> {
  final _titleCtrl = TextEditingController();
  final _startCtrl = TextEditingController(text: '16:00');
  final _endCtrl = TextEditingController(text: '17:00');
  String _category = 'coding';
  String _day = DateFormat('EEEE').format(DateTime.now());
  bool _alarm = true;
  String _milestoneId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectService>().fetchProjects();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final t = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(ctrl.text.split(':').first) ?? t.hour,
        minute: int.tryParse(ctrl.text.split(':').last) ?? t.minute,
      ),
      builder: (ctx, child) => Theme(data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.dark(
          primary: AetherColors.purple,
          onPrimary: Colors.white,
          surface: const Color(0xFF0C091A),
          onSurface: AetherColors.textBright,
        ),
      ), child: child!),
    );
    if (picked != null) {
      ctrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = AetherColors.categoryColors.keys.toList();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _titleCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Task title...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Autocomplete<String>(
                optionsBuilder: (val) {
                  if (val.text.isEmpty) return categories;
                  return categories.where((c) => c.toLowerCase().contains(val.text.toLowerCase()));
                },
                initialValue: TextEditingValue(text: _category),
                onSelected: (v) => _category = v,
                fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
                  ctrl.text = _category;
                  return TextField(
                    controller: ctrl,
                    focusNode: focusNode,
                    style: const TextStyle(fontSize: 13, color: AetherColors.textBright),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. coding, study...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 12, height: 12, margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AetherColors.categoryColor(ctrl.text),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    onChanged: (v) => _category = v,
                  );
                },
                optionsViewBuilder: (ctx, onSelected, options) => Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C091A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AetherColors.glassBorder),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (ctx, i) {
                        final cat = options.elementAt(i);
                        return InkWell(
                          onTap: () => onSelected(cat),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: AetherColors.categoryColor(cat), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(cat[0].toUpperCase() + cat.substring(1),
                                  style: const TextStyle(color: AetherColors.textBright, fontSize: 13)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: _day,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13, color: AetherColors.textBright),
                items: days.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: AetherColors.textBright)))).toList(),
                onChanged: (v) => setState(() => _day = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _startCtrl,
                readOnly: true,
                onTap: () => _pickTime(_startCtrl),
                style: const TextStyle(fontSize: 13, color: AetherColors.textBright),
                decoration: const InputDecoration(
                  labelText: 'Start',
                  suffixIcon: Icon(Icons.access_time, size: 16, color: AetherColors.textMuted),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text('-', style: TextStyle(color: AetherColors.textMuted, fontSize: 16)),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _endCtrl,
                readOnly: true,
                onTap: () => _pickTime(_endCtrl),
                style: const TextStyle(fontSize: 13, color: AetherColors.textBright),
                decoration: const InputDecoration(
                  labelText: 'End',
                  suffixIcon: Icon(Icons.access_time, size: 16, color: AetherColors.textMuted),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: _milestoneId.isEmpty ? null : _milestoneId,
                decoration: const InputDecoration(
                  labelText: 'Milestone',
                  hintText: 'No milestone',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13, color: AetherColors.textBright),
                items: () {
                  final proj = context.watch<ProjectService>();
                  final items = <DropdownMenuItem<String>>[
                    const DropdownMenuItem(value: '', child: Text('No milestone')),
                  ];
                  for (final p in proj.projects) {
                    for (final m in p.milestones) {
                      items.add(DropdownMenuItem(
                        value: m.id,
                        child: Text('${p.title} › ${m.title}', overflow: TextOverflow.ellipsis),
                      ));
                    }
                  }
                  return items;
                }(),
                onChanged: (v) => setState(() => _milestoneId = v ?? ''),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: Checkbox(
                      value: _alarm,
                      onChanged: (v) => setState(() => _alarm = v!),
                      fillColor: WidgetStateProperty.resolveWith((_) => AetherColors.rose),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.notifications_outlined, color: AetherColors.textMuted, size: 16),
                  const SizedBox(width: 4),
                  const Text('Alarm', style: TextStyle(fontSize: 13, color: AetherColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_titleCtrl.text.trim().isNotEmpty) {
                final err = await context.read<TaskService>().createTask(Task(
                  id: '', userId: '',
                  title: _titleCtrl.text.trim(),
                  category: _category,
                  dayOfWeek: _day.toLowerCase(),
                  startTime: _startCtrl.text.trim(),
                  endTime: _endCtrl.text.trim(),
                  alarmEnabled: _alarm,
                  milestoneId: _milestoneId.isNotEmpty ? _milestoneId : null,
                  createdAt: DateTime.now().toIso8601String(),
                ));
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                }
                _titleCtrl.clear();
                widget.onAdded();
              }
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Inject Into Schedule', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AetherColors.rose,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
