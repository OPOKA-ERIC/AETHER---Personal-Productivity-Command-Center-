import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsService>().fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final as = context.watch<AnalyticsService>();
    final data = as.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data != null) ...[
            Row(
              children: [
                _kpiCard(Icons.check_circle_outline, '${data.summary.completedTasks} / ${data.summary.totalTasks}', 'Tasks Completed', AetherColors.purple),
                const SizedBox(width: 8),
                _kpiCard(Icons.percent, '${data.summary.completionRate}%', 'Task Adherence Rate', AetherColors.emerald),
                const SizedBox(width: 8),
                _kpiCard(Icons.access_time, '${data.summary.actualMinutes ~/ 60}h ${data.summary.actualMinutes % 60}m', 'Productive Hours', AetherColors.cyan),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: AetherColors.purple, size: 18),
                      const SizedBox(width: 8),
                      Text('Daily Metrics Trends',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: CustomPaint(
                      size: const Size(double.infinity, 220),
                      painter: _TrendChartPainter(data.trends),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot('Plan Adherence', AetherColors.emerald),
                      const SizedBox(width: 16),
                      _legendDot('Focus Rating', AetherColors.purple),
                      const SizedBox(width: 16),
                      _legendDot('Energy Level', AetherColors.cyan),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart, color: AetherColors.purple, size: 18),
                      const SizedBox(width: 8),
                      Text('Category Time Breakdown',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (data.categoryStats.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No categories active in your planner schedules.',
                          style: TextStyle(color: AetherColors.textMuted, fontSize: 13)),
                    ))
                  else
                    ...data.categoryStats.entries.map((e) => _categoryBar(e.key, e.value, data.categoryStats)),
                ],
              ),
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(Icons.analytics, color: AetherColors.textMuted, size: 48),
                    SizedBox(height: 12),
                    Text('Loading analytics...', style: TextStyle(color: AetherColors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _kpiCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AetherColors.glass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AetherColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AetherColors.textBright)),
                  Text(label,
                      style: const TextStyle(fontSize: 10, color: AetherColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AetherColors.textMuted)),
      ],
    );
  }

  Widget _categoryBar(String cat, dynamic stat, Map<String, dynamic> allStats) {
    final color = AetherColors.categoryColor(cat);
    final maxMinutes = allStats.values.fold<int>(0, (m, s) => s.scheduled > m ? s.scheduled : m);
    final widthPercent = maxMinutes > 0 ? (stat.scheduled / maxMinutes) * 100 : 0.0;
    final schedHr = (stat.scheduled / 60).toStringAsFixed(1);
    final actHr = (stat.actual / 60).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AetherColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AetherColors.textPrimary)),
                ],
              ),
              Text('${actHr}h done / ${schedHr}h scheduled',
                  style: const TextStyle(fontSize: 10, color: AetherColors.textMuted, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: widthPercent / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final dynamic trends;

  _TrendChartPainter(this.trends);

  @override
  void paint(Canvas canvas, Size size) {
    final adherence = trends.adherenceTrend;
    final focus = trends.focusTrend;
    final energy = trends.energyTrend;

    if (adherence.length < 2) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'Log at least 2 daily reflections to view performance charts.',
          style: TextStyle(color: AetherColors.textMuted, fontSize: 12, fontFamily: 'Inter'),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 40);
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }

    final padding = const EdgeInsets.only(left: 40, right: 20, top: 20, bottom: 30);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    void drawGrid() {
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 1;
      for (int i = 0; i <= 4; i++) {
        final y = padding.top + chartHeight - (chartHeight * (i / 4));
        canvas.drawLine(Offset(padding.left, y), Offset(size.width - padding.right, y), paint);
      }
    }

    void drawYLabels() {
      for (int i = 0; i <= 4; i++) {
        final y = padding.top + chartHeight - (chartHeight * (i / 4));
        final tp = TextPainter(
          text: TextSpan(text: '${i * 25}%', style: const TextStyle(color: AetherColors.textMuted, fontSize: 10, fontFamily: 'monospace')),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(padding.left - tp.width - 6, y - tp.height / 2));
      }
    }

    void drawXLabels(List<dynamic> records) {
      final xSpacing = chartWidth / (records.length - 1);
      for (int i = 0; i < records.length; i++) {
        final x = padding.left + i * xSpacing;
        final parts = records[i].date.split('-');
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final label = '${months[int.parse(parts[1]) - 1]} ${int.parse(parts[2])}';
        final tp = TextPainter(
          text: TextSpan(text: label, style: const TextStyle(color: AetherColors.textMuted, fontSize: 9, fontFamily: 'Inter')),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - padding.bottom + 8));
      }
    }

    void drawMetricLine(List<dynamic> records, Color color, int scale) {
      if (records.length < 2) return;
      final xSpacing = chartWidth / (records.length - 1);

      final path = Path();
      final pts = <Offset>[];
      for (int i = 0; i < records.length; i++) {
        final score = scale == 10 ? records[i].score * 10 : records[i].score;
        final x = padding.left + i * xSpacing;
        final y = padding.top + chartHeight - (chartHeight * (score / 100));
        pts.add(Offset(x, y));
        if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
      }

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);

      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, padding.top, size.width, chartHeight));
      final areaPath = Path.from(path);
      areaPath.lineTo(pts.last.dx, padding.top + chartHeight);
      areaPath.lineTo(pts.first.dx, padding.top + chartHeight);
      areaPath.close();
      canvas.drawPath(areaPath, areaPaint);

      for (final pt in pts) {
        canvas.drawCircle(pt, 3.5, Paint()..color = color);
        canvas.drawCircle(pt, 3.5, Paint()..color = AetherColors.bg..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }

    drawGrid();
    drawYLabels();
    drawXLabels(adherence);
    drawMetricLine(adherence, AetherColors.emerald, 1);
    drawMetricLine(focus, AetherColors.purple, 10);
    drawMetricLine(energy, AetherColors.cyan, 10);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
