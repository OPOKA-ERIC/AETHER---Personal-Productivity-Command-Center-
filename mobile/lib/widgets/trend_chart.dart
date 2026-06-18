import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics.dart';
import '../theme/aether_theme.dart';

class TrendChart extends StatelessWidget {
  final List<TrendPoint> data;

  const TrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No trend data yet', style: TextStyle(color: AetherColors.textMuted)),
      );
    }

    final reversed = data.reversed.toList();
    final spots = List.generate(reversed.length, (i) => i.toDouble());

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AetherColors.glassBorder,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: AetherColors.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= reversed.length) return const SizedBox();
                  final date = reversed[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      date.length >= 5 ? date.substring(5) : date,
                      style: const TextStyle(fontSize: 9, color: AetherColors.textMuted),
                    ),
                  );
                },
                reservedSize: 20,
                interval: 1,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (reversed.length - 1).toDouble(),
          minY: 0,
          maxY: 10,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final label = ['Focus', 'Energy', 'Adherence'][spot.barIndex];
                  return LineTooltipItem(
                    '$label: ${spot.y.toStringAsFixed(1)}',
                    TextStyle(color: [
                      AetherColors.purple,
                      AetherColors.cyan,
                      AetherColors.emerald,
                    ][spot.barIndex], fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            _line(spots, reversed.map((e) => e.focus).toList(), AetherColors.purple),
            _line(spots, reversed.map((e) => e.energy).toList(), AetherColors.cyan),
            _line(spots, reversed.map((e) => e.adherence / 10).toList(), AetherColors.emerald),
          ],
        ),
      ),
    );
  }

  LineChartBarData _line(List<double> x, List<double> y, Color color) {
    return LineChartBarData(
      spots: List.generate(x.length, (i) => FlSpot(x[i], y[i])),
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }
}
