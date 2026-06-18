import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/category_badge.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _weekStart = _getWeekStart(DateTime.now());
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  static DateTime _getWeekStart(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskService>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final tasks = taskService.tasks;
    final weekNumber = ((_weekStart.difference(DateTime(_weekStart.year, 1, 1)).inDays / 7) + 1).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Week $weekNumber',
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                    Text('${_weekStart.year}',
                        style: const TextStyle(color: AetherColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AetherColors.textMuted),
                    onPressed: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                  ),
                  Text('${DateFormat('MMM d').format(_weekStart)} - ${DateFormat('MMM d').format(_weekStart.add(const Duration(days: 6)))}',
                      style: const TextStyle(color: AetherColors.textPrimary, fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AetherColors.textMuted),
                    onPressed: () {
                      final next = _weekStart.add(const Duration(days: 7));
                      if (!next.isAfter(DateTime.now().add(const Duration(days: 7)))) {
                        setState(() => _weekStart = next);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(7, (i) {
                final day = _weekStart.add(Duration(days: i));
                final dayName = DateFormat('EEEE').format(day).toLowerCase();
                final dayTasks = tasks.where((t) => t.dayOfWeek.toLowerCase() == dayName).toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));
                return _buildDayColumn(day, dayTasks);
              }),
            ),
          ),
          const SizedBox(height: 20),
          _buildCalendar(taskService),
        ],
      ),
    );
  }

  Widget _buildDayColumn(DateTime day, List<Task> tasks) {
    final isToday = DateFormat('yyyyMMdd').format(day) == DateFormat('yyyyMMdd').format(DateTime.now());
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(DateFormat('EEE').format(day).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: isToday ? AetherColors.purple : AetherColors.textMuted,
                    )),
                const Spacer(),
                Text('${tasks.length}',
                    style: TextStyle(fontSize: 11, color: isToday ? AetherColors.purple : AetherColors.textMuted)),
              ],
            ),
            Text(day.day.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: isToday ? AetherColors.purple : AetherColors.textBright,
                )),
            const Divider(height: 12),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('No tasks', style: TextStyle(color: AetherColors.textMuted, fontSize: 11)))
                  : ListView(
                      children: tasks.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AetherColors.categoryColor(t.category).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border(
                            left: BorderSide(
                              color: AetherColors.categoryColor(t.category),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AetherColors.textPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${t.startTime}-${t.endTime}',
                                style: const TextStyle(fontSize: 9, color: AetherColors.textMuted)),
                          ],
                        ),
                      )).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(TaskService taskService) {
    final firstDay = DateTime(_currentYear, _currentMonth, 1);
    final lastDay = DateTime(_currentYear, _currentMonth + 1, 0);
    final firstWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;

    final allTasks = taskService.tasks;
    final Set<String> taskDays = {};
    for (final t in allTasks) {
      final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      final taskDayIdx = dayNames.indexOf(t.dayOfWeek.toLowerCase());
      if (taskDayIdx >= 0) {
        for (int d = 1; d <= daysInMonth; d++) {
          final dt = DateTime(_currentYear, _currentMonth, d);
          if (dt.weekday - 1 == taskDayIdx && !dt.isAfter(DateTime.now())) {
            taskDays.add(DateFormat('yyyyMMdd').format(dt));
          }
        }
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AetherColors.textMuted),
                onPressed: () {
                  setState(() {
                    if (_currentMonth == 1) { _currentMonth = 12; _currentYear--; }
                    else { _currentMonth--; }
                  });
                },
              ),
              Text('${DateFormat('MMMM').format(firstDay)} $_currentYear',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AetherColors.textMuted),
                onPressed: () {
                  setState(() {
                    if (_currentMonth == 12) { _currentMonth = 1; _currentYear++; }
                    else { _currentMonth++; }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (ctx, i) {
              if (i < firstWeekday) return const SizedBox();
              final day = i - firstWeekday + 1;
              final dateStr = DateFormat('yyyyMMdd').format(DateTime(_currentYear, _currentMonth, day));
              final isToday = dateStr == DateFormat('yyyyMMdd').format(DateTime.now());
              final hasTask = taskDays.contains(dateStr);

              return GestureDetector(
                onTap: () => _showDayDetail(context, day, taskService),
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday ? AetherColors.purple.withValues(alpha: 0.2) : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday ? Border.all(color: AetherColors.purple.withValues(alpha: 0.5)) : null,
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(day.toString(),
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: isToday ? AetherColors.purple : AetherColors.textPrimary,
                            )),
                        if (hasTask)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 5, height: 5,
                              decoration: const BoxDecoration(
                                color: AetherColors.cyan, shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDayDetail(BuildContext context, int day, TaskService taskService) {
    final dt = DateTime(_currentYear, _currentMonth, day);
    final dayName = DateFormat('EEEE').format(dt).toLowerCase();
    final dayTasks = taskService.tasks.where((t) => t.dayOfWeek.toLowerCase() == dayName).toList();

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEEE, MMMM d').format(dt),
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
            const SizedBox(height: 16),
            if (dayTasks.isEmpty)
              const Text('No tasks for this day', style: TextStyle(color: AetherColors.textMuted))
            else
              ...dayTasks.map((t) => ListTile(
                leading: CategoryBadge(category: t.category, size: 12),
                title: Text(t.title, style: const TextStyle(color: AetherColors.textPrimary, fontSize: 14)),
                subtitle: Text('${t.startTime} - ${t.endTime}', style: const TextStyle(color: AetherColors.textMuted, fontSize: 12)),
                trailing: t.completed
                    ? const Icon(Icons.check_circle, color: AetherColors.emerald, size: 18)
                    : null,
              )),
          ],
        ),
      ),
    );
  }
}
