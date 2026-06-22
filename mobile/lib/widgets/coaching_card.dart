import 'package:flutter/material.dart';
import '../models/analytics.dart';
import '../theme/aether_theme.dart';

class CoachingCard extends StatelessWidget {
  final CoachingTip tip;

  const CoachingCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (tip.type) {
      case 'success':
        color = AetherColors.emerald;
        icon = Icons.check_circle;
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AetherColors.textBright)),
                const SizedBox(height: 3),
                Text(tip.text,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AetherColors.textMuted,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
