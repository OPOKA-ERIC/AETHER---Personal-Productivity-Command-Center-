import 'package:flutter/material.dart';
import '../models/analytics.dart';
import '../theme/aether_theme.dart';

class CategoryBars extends StatelessWidget {
  final List<CategoryStat> stats;

  const CategoryBars({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Center(
        child: Text('No category data', style: TextStyle(color: AetherColors.textMuted)),
      );
    }

    final maxHours = stats.fold<double>(0, (max, s) => s.scheduledHours > max ? s.scheduledHours : max);

    return Column(
      children: stats.map((stat) => _buildBar(stat, maxHours)).toList(),
    );
  }

  Widget _buildBar(CategoryStat stat, double maxHours) {
    final color = AetherColors.categoryColor(stat.category);
    final scheduledWidth = maxHours > 0 ? stat.scheduledHours / maxHours : 0.0;
    final actualWidth = maxHours > 0 ? stat.actualHours / maxHours : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                stat.category[0].toUpperCase() + stat.category.substring(1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AetherColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${stat.scheduledHours.toStringAsFixed(1)}h / ${stat.actualHours.toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 11, color: AetherColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Flexible(
                    flex: (scheduledWidth * 1000).toInt().clamp(1, 1000),
                    child: Container(color: color.withValues(alpha: 0.3)),
                  ),
                  if (scheduledWidth < 1)
                    Flexible(
                      flex: (1000 - (scheduledWidth * 1000).toInt()).clamp(1, 1000),
                      child: Container(color: AetherColors.glass),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Flexible(
                    flex: (actualWidth * 1000).toInt().clamp(1, 1000),
                    child: Container(color: color),
                  ),
                  if (actualWidth < 1)
                    Flexible(
                      flex: (1000 - (actualWidth * 1000).toInt()).clamp(1, 1000),
                      child: Container(color: Colors.transparent),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
