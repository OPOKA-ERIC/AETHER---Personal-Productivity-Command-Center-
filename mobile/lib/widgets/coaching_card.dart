import 'package:flutter/material.dart';
import '../models/analytics.dart';
import '../theme/aether_theme.dart';

class CoachingCard extends StatelessWidget {
  final CoachingSuggestion suggestion;

  const CoachingCard({super.key, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (suggestion.type) {
      case 'success':
        color = AetherColors.emerald;
        icon = Icons.emoji_events;
        break;
      case 'warning':
        color = AetherColors.amber;
        icon = Icons.warning_amber_rounded;
        break;
      case 'danger':
        color = AetherColors.rose;
        icon = Icons.error_outline;
        break;
      default:
        color = AetherColors.cyan;
        icon = Icons.lightbulb_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              suggestion.message,
              style: TextStyle(
                fontSize: 13,
                color: AetherColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
