import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/kpi_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/category_bars.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsService = context.watch<AnalyticsService>();
    final summary = analyticsService.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
          const SizedBox(height: 16),
          if (summary == null)
            GlassCard(
              padding: const EdgeInsets.all(32),
              child: const Center(child: Text('Loading analytics...', style: TextStyle(color: AetherColors.textMuted))),
            )
          else ...[
            Row(
              children: [
                Expanded(child: KpiCard(
                  label: 'Tasks Completed', color: AetherColors.purple,
                  value: '${summary.completedTasks}/${summary.totalTasks}',
                  icon: Icons.task_alt,
                )),
                const SizedBox(width: 8),
                Expanded(child: KpiCard(
                  label: 'Adherence Rate', color: AetherColors.emerald,
                  value: '${summary.completionRate.toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                )),
                const SizedBox(width: 8),
                Expanded(child: KpiCard(
                  label: 'Productive Hours', color: AetherColors.cyan,
                  value: '${(summary.actualMinutes / 60).toStringAsFixed(1)}h',
                  icon: Icons.access_time,
                )),
              ],
            ),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trends (Last 7 Days)',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                  const SizedBox(height: 16),
                  TrendChart(data: summary.trendData),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _legend('Focus', AetherColors.purple),
                      _legend('Energy', AetherColors.cyan),
                      _legend('Adherence', AetherColors.emerald),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category Distribution',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                  const SizedBox(height: 16),
                  CategoryBars(stats: summary.categoryStats),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
      ],
    );
  }
}
