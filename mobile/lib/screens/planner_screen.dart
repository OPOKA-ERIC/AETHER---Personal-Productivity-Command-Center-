import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/project_service.dart';
import '../services/reflection_service.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _calendarDate = DateTime.now();
  int _weekOffset = 0;

  DateTime get _anchorDate {
    final today = DateTime.now();
    return today.add(Duration(days: _weekOffset * 7));
  }

  String _dateStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<String> _weekDateRange() {
    final anchor = _anchorDate;
    final diff = anchor.weekday - 1;
    final mon = anchor.subtract(Duration(days: diff));
    final sun = mon.add(const Duration(days: 6));
    return [_dateStr(mon), _dateStr(sun)];
  }

  String _dateForDay(String dayName) {
    final anchor = _anchorDate;
    final diff = anchor.weekday - 1;
    final mon = anchor.subtract(Duration(days: diff));
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final idx = days.indexOf(dayName);
    if (idx == -1) return '';
    final d = mon.add(Duration(days: idx));
    return _dateStr(d);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskService>().fetchTasks();
      context.read<ProjectService>().fetchProjects();
      context.read<ReflectionService>().fetchReflections();
    });
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    return ((date.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
  }

  String _weekLabel(DateTime now) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    final wn = _getWeekOfMonth(now);
    return 'Week $wn of ${months[now.month - 1]} ${now.year}';
  }

  String _weekDates(DateTime now) {
    final day = now.weekday; // 1=Mon
    final diff = day - 1;
    final mon = now.subtract(Duration(days: diff));
    final sun = mon.add(const Duration(days: 6));
    final fmt = DateFormat('d MMM');
    return '${fmt.format(mon)} – ${fmt.format(sun)}';
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.watch<TaskService>();
    final anchor = _anchorDate;
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.auto_fix_high, size: 16, color: AetherColors.purple),
                  label: Text('Sunday Planning Ritual',
                      style: TextStyle(fontSize: 12, color: AetherColors.textMuted)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: AetherColors.glassBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddTaskModal(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Schedule Time Block', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AetherColors.glass,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AetherColors.glassBorder),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _weekOffset--);
                    context.read<TaskService>().fetchTasks();
                  },
                  child: const Icon(Icons.chevron_left, color: AetherColors.textMuted, size: 20),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_month, color: AetherColors.purple, size: 16),
                const SizedBox(width: 8),
                Text(_weekLabel(anchor),
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                const Spacer(),
                Text(_weekDates(anchor),
                    style: const TextStyle(fontSize: 12, color: AetherColors.textMuted)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    setState(() => _weekOffset++);
                    context.read<TaskService>().fetchTasks();
                  },
                  child: const Icon(Icons.chevron_right, color: AetherColors.textMuted, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 400,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: days.map((day) {
                final dayDate = _dateForDay(day);
                final dayTasks = ts.tasks.where((t) {
                  if (t.date != null && t.date!.isNotEmpty) return t.date == dayDate;
                  return t.dayOfWeek.toLowerCase() == day.toLowerCase() && _weekOffset == 0;
                }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0x7316112B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AetherColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(day.substring(0, 3),
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AetherColors.textBright)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${dayTasks.length}',
                                style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Divider(height: 1, color: AetherColors.glassBorder),
                      const SizedBox(height: 8),
                      Expanded(
                        child: dayTasks.isEmpty
                            ? const Center(child: Text('No blocks', style: TextStyle(fontSize: 11, color: AetherColors.textMuted)))
                            : ListView(
                                children: dayTasks.map((t) => _plannerBlock(t)).toList(),
                              ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),
          _buildCalendar(ts),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _plannerBlock(dynamic task) {
    final color = AetherColors.categoryColor(task.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x05FFFFFF),
            border: Border(
              left: BorderSide(color: color, width: 2.5),
              top: const BorderSide(color: AetherColors.glassBorder),
              right: const BorderSide(color: AetherColors.glassBorder),
              bottom: const BorderSide(color: AetherColors.glassBorder),
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: task.completed ? AetherColors.textMuted : AetherColors.textPrimary,
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${task.startTime} - ${task.endTime}',
                  style: const TextStyle(fontSize: 10, color: AetherColors.textMuted, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(task.category,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                  Row(
                    children: [
                      if (task.alarmEnabled)
                        const Icon(Icons.notifications, color: AetherColors.textMuted, size: 10),
                      if (task.milestoneId != null)
                        const SizedBox(width: 4),
                      if (task.milestoneId != null)
                        const Icon(Icons.account_tree, color: AetherColors.textMuted, size: 10),
                      if (task.completed)
                        const Icon(Icons.check_circle, color: AetherColors.emerald, size: 12),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(TaskService ts) {
    final year = _calendarDate.year;
    final month = _calendarDate.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = (firstDay.weekday + 6) % 7;
    final today = DateTime.now();

    final reflections = context.watch<ReflectionService>().reflections;
    final reflectionDates = reflections.map((r) => r.date).toSet();
    final taskDates = ts.tasks
        .where((t) => t.date != null && t.date!.isNotEmpty)
        .map((t) => t.date!)
        .toSet();

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AetherColors.purple, size: 16),
              const SizedBox(width: 8),
              Text('History Calendar',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _calendarDate = DateTime(year, month - 1, 1)),
                child: const Icon(Icons.chevron_left, color: AetherColors.textMuted, size: 20),
              ),
              const SizedBox(width: 8),
              Text(DateFormat('MMMM yyyy').format(_calendarDate),
                  style: const TextStyle(fontSize: 12, color: AetherColors.textMuted)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _calendarDate = DateTime(year, month + 1, 1)),
                child: const Icon(Icons.chevron_right, color: AetherColors.textMuted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 7 + offset + daysInMonth,
            itemBuilder: (ctx, i) {
              if (i < 7) {
                final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Center(
                  child: Text(dayNames[i],
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AetherColors.textMuted, letterSpacing: 0.05)),
                );
              }
              final dayNum = i - 7 - offset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }
              return _calDay(dayNum, year, month, today, reflectionDates, taskDates, ts);
            },
          ),
        ],
      ),
    );
  }

  Widget _calDay(int d, int year, int month, DateTime today, Set<String> reflectionDates, Set<String> taskDates, TaskService ts) {
    final dateStr = '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final isToday = d == today.day && month == today.month && year == today.year;
    final hasReflection = reflectionDates.contains(dateStr);
    final hasTask = taskDates.contains(dateStr);
    final hasData = hasReflection || hasTask;

    return GestureDetector(
      onTap: hasData ? () => _showDayDetail(dateStr, d, ts) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? AetherColors.purple.withValues(alpha: 0.12) : const Color(0x03FFFFFF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isToday ? AetherColors.purple.withValues(alpha: 0.35) : const Color(0x0AFFFFFF)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$d',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                  color: isToday ? AetherColors.purple : (hasData ? AetherColors.textBright : AetherColors.textMuted),
                )),
            if (hasData)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasReflection)
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: AetherColors.purple, shape: BoxShape.circle)),
                  if (hasTask) ...[
                    const SizedBox(width: 3),
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: AetherColors.cyan, shape: BoxShape.circle)),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDayDetail(String dateStr, int day, TaskService ts) {
    final ref = context.read<ReflectionService>().reflections.where((r) => r.date == dateStr).firstOrNull;
    final dayOfWeek = DateFormat('EEEE').format(DateTime(_calendarDate.year, _calendarDate.month, day));
    final dayTasks = ts.tasks.where((t) {
      if (t.date != null && t.date!.isNotEmpty) return t.date == dateStr;
      return t.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase();
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1530),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(DateFormat('MMMM d, yyyy').format(DateTime(_calendarDate.year, _calendarDate.month, day)),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ref != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _drCol('Adherence', '${ref.adherenceScore}%', AetherColors.emerald),
                    _drCol('Focus', '${ref.focusScore}/10', AetherColors.purple),
                    _drCol('Energy', '${ref.energyScore}/10', AetherColors.cyan),
                  ],
                ),
                const Divider(color: AetherColors.glassBorder, height: 20),
                _drNote('What went well', ref.notesSuccess, AetherColors.emerald),
                const SizedBox(height: 8),
                _drNote('Struggles', ref.notesStruggles, AetherColors.rose),
                const SizedBox(height: 8),
                _drNote('Improvements', ref.notesImprovements, AetherColors.purple),
                if (dayTasks.isNotEmpty) const Divider(color: AetherColors.glassBorder, height: 20),
              ],
              if (dayTasks.isNotEmpty) ...[
                Text('$dayOfWeek Schedule',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AetherColors.textMuted, letterSpacing: 0.05)),
                const SizedBox(height: 8),
                ...dayTasks.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: AetherColors.categoryColor(t.category), width: 3)),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(t.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AetherColors.textBright))),
                    Text('${t.startTime} – ${t.endTime}',
                        style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
                  ]),
                )),
              ],
              if (ref == null && dayTasks.isEmpty)
                const Text('No data for this day.',
                    style: TextStyle(color: AetherColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AetherColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _drCol(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color, fontFamily: 'Outfit')),
      Text(label, style: const TextStyle(fontSize: 10, color: AetherColors.textMuted)),
    ]);
  }

  Widget _drNote(String title, String content, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.circle, color: color, size: 8),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
      const SizedBox(height: 2),
      Text(content.isNotEmpty ? content : '—',
          style: const TextStyle(fontSize: 12, color: AetherColors.textPrimary)),
    ]);
  }

  void _showAddTaskModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '08:00');
    final endCtrl = TextEditingController(text: '09:00');
    String category = 'study';
    String day = 'Monday';
    bool alarm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1530),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final categories = AetherColors.categoryColors.keys.toList();
        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return StatefulBuilder(builder: (ctx, setInnerState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule Time Block',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(hintText: 'Task title...'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AetherColors.categoryColor(c), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(c[0].toUpperCase() + c.substring(1)),
                    ]),
                  )).toList(),
                  onChanged: (v) => setInnerState(() => category = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: day,
                        items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setInnerState(() => day = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 70, child: TextField(controller: startCtrl, style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 4),
                    const Text('-', style: TextStyle(color: AetherColors.textMuted)),
                    const SizedBox(width: 4),
                    SizedBox(width: 70, child: TextField(controller: endCtrl, style: const TextStyle(fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: AetherColors.purple, size: 14),
                    const SizedBox(width: 8),
                    Text(_dateForDay(day),
                        style: const TextStyle(fontSize: 13, color: AetherColors.textMuted, fontFamily: 'monospace')),
                  ]),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18, height: 18,
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
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isNotEmpty) {
                        context.read<TaskService>().createTask(Task(
                          id: '', userId: '',
                          title: titleCtrl.text.trim(),
                          category: category,
                          dayOfWeek: day.toLowerCase(),
                          startTime: startCtrl.text.trim(),
                          endTime: endCtrl.text.trim(),
                          alarmEnabled: alarm,
                          date: _dateForDay(day),
                          createdAt: DateTime.now().toIso8601String(),
                        ));
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Confirm Slot'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
