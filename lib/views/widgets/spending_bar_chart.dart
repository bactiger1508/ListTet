import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:person_app/theme/app_colors.dart';

class SpendingBarChart extends StatelessWidget {
  final Map<String, int> data; // date -> amount

  const SpendingBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? (maxVal * 1.3) : 100000.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Chi tiêu 7 ngày qua',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 4),
        Text('Tổng: ${_fmt(entries.fold(0, (s, e) => s + e.value))}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final amount = entries[group.x.toInt()].value;
                    return BarTooltipItem(
                      _fmt(amount),
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                      final parts = entries[idx].key.split('-');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${parts.last}/${parts[1]}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(entries.length, (i) {
                final val = entries[i].value.toDouble();
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: val > 0 ? val : 0,
                    width: 20,
                    gradient: val > 0 ? AppColors.goldGradient : null,
                    color: val > 0 ? null : AppColors.borderMuted.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ]);
              }),
            ),
          ),
        ),
      ]),
    );
  }

  String _fmt(int v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}tr ₫'
      : '${(v / 1000).round()}k ₫';
}
