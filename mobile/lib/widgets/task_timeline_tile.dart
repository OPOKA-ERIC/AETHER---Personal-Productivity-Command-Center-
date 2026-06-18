import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/aether_theme.dart';
import 'category_badge.dart';

class TaskTimelineTile extends StatelessWidget {
  final Task task;
  final bool isActive;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onDone;
  final String? elapsedText;

  const TaskTimelineTile({
    super.key,
    required this.task,
    this.isActive = false,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onDone,
    this.elapsedText,
  });

  @override
  Widget build(BuildContext context) {
    final color = AetherColors.categoryColor(task.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AetherColors.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.5) : AetherColors.glassBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CategoryBadge(category: task.category),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: task.completed
                                  ? AetherColors.textMuted
                                  : AetherColors.textPrimary,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (task.completed)
                          const Icon(Icons.check_circle,
                              color: AetherColors.emerald, size: 18)
                        else if (elapsedText != null)
                          Text(
                            elapsedText!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: AetherColors.cyan,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${task.startTime} - ${task.endTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AetherColors.textMuted,
                      ),
                    ),
                    if (!task.completed) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onStart != null)
                            _actionButton('Start', AetherColors.emerald, onStart!),
                          if (onPause != null)
                            _actionButton('Pause', AetherColors.amber, onPause!),
                          if (onResume != null)
                            _actionButton('Resume', AetherColors.cyan, onResume!),
                          if (onDone != null)
                            _actionButton('Done', AetherColors.purple, onDone!),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
