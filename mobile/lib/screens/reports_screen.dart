import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedRange = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final analyticsService = context.watch<AnalyticsService>();
    final summary = analyticsService.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress Reports',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
          const SizedBox(height: 16),
          Row(
            children: [
              DropdownButton<String>(
                value: _selectedRange,
                dropdownColor: const Color(0xFF1A1530),
                style: GoogleFonts.inter(color: AetherColors.textPrimary),
                underline: const SizedBox(),
                items: ['Weekly', 'Monthly', 'Quarterly', 'Yearly'].map((r) =>
                  DropdownMenuItem(value: r, child: Text(r))
                ).toList(),
                onChanged: (v) => setState(() => _selectedRange = v!),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  analyticsService.fetchAnalytics();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report generated!'), backgroundColor: AetherColors.purple),
                  );
                },
                child: const Text('Generate Report'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (summary != null)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_selectedRange Report',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                  Text(DateFormat('MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(color: AetherColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 20),
                  _statRow('Productive Time', '${(summary.actualMinutes / 60).toStringAsFixed(1)} hours'),
                  const Divider(height: 20),
                  _statRow('Plan Adherence', '${summary.completionRate.toStringAsFixed(1)}%'),
                  const Divider(height: 20),
                  _statRow('Tasks Completed', '${summary.completedTasks} / ${summary.totalTasks}'),
                  const Divider(height: 20),
                  Text('Category Breakdown',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AetherColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...summary.categoryStats.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(c.category[0].toUpperCase() + c.category.substring(1),
                            style: const TextStyle(color: AetherColors.textPrimary, fontSize: 13)),
                        const Spacer(),
                        Text('${c.scheduledHours.toStringAsFixed(1)}h / ${c.actualHours.toStringAsFixed(1)}h',
                            style: const TextStyle(color: AetherColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDF generation coming soon!'), backgroundColor: AetherColors.purple),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AetherColors.purple),
                        foregroundColor: AetherColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GlassCard(
              padding: const EdgeInsets.all(32),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.bar_chart, color: AetherColors.textMuted, size: 48),
                    SizedBox(height: 12),
                    Text('No report data yet', style: TextStyle(color: AetherColors.textMuted)),
                    SizedBox(height: 4),
                    Text('Generate a report to see your progress', style: TextStyle(color: AetherColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AetherColors.textMuted, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AetherColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
