import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:person_app/theme/app_colors.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, int> data; // categoryName -> totalSpent

  const CategoryPieChart({super.key, required this.data});

  static const _colors = [
    AppColors.primary,
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.values.every((v) => v == 0)) return const SizedBox.shrink();

    final total = data.values.fold(0, (s, v) => s + v);
    final entries = data.entries.where((e) => e.value > 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Phân bổ theo hạng mục',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Row(children: [
            Expanded(
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: List.generate(entries.length, (i) {
                  final pct = (entries[i].value / total * 100);
                  return PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: _colors[i % _colors.length],
                    radius: 50,
                    title: '${pct.round()}%',
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }),
              )),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(
                      color: _colors[i % _colors.length], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text(entries[i].key,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMain)),
                ]),
              )),
            ),
          ]),
        ),
      ]),
    );
  }
}
