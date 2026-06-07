import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/record.dart';
import '../models/category.dart';
import '../utils/currency_helper.dart';

class DonutChart extends StatelessWidget {
  final List<Record> records;
  final List<Category> categories;

  const DonutChart({
    Key? key,
    required this.records,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Filter expenses
    final expenses = records.where((r) => r.type == 'expense').toList();
    if (expenses.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Text(
          'No expenses registered yet.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    // 2. Aggregate expenses by category
    final Map<String, double> categorySums = {};
    double totalExpense = 0.0;
    for (var r in expenses) {
      final catId = r.categoryId ?? 'uncategorized';
      categorySums[catId] = (categorySums[catId] ?? 0.0) + r.amount;
      totalExpense += r.amount;
    }

    // 3. Build PieChart sections
    final List<PieChartSectionData> sections = [];
    categorySums.forEach((catId, sum) {
      // Find category
      final cat = categories.firstWhere((c) => c.id == catId, orElse: () => Category(
        id: 'uncategorized',
        name: 'Others',
        color: '0xFF9E9E9E',
        icon: 'category',
        isArchived: false,
      ));

      Color sectionColor;
      try {
        sectionColor = Color(int.parse(cat.color));
      } catch (_) {
        sectionColor = Colors.grey;
      }

      final double percentage = (sum / totalExpense) * 100;

      sections.add(
        PieChartSectionData(
          color: sectionColor,
          value: sum,
          title: percentage > 8 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 35,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    final String currency = records.isNotEmpty ? records.first.currency : 'INR';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'EXPENSE BREAKDOWN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                    sections: sections,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Outflow',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyHelper.format(totalExpense, currency),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF263238),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: categorySums.keys.map((catId) {
              final cat = categories.firstWhere((c) => c.id == catId, orElse: () => Category(
                id: 'uncategorized',
                name: 'Others',
                color: '0xFF9E9E9E',
                icon: 'category',
                isArchived: false,
              ));

              Color legendColor;
              try {
                legendColor = Color(int.parse(cat.color));
              } catch (_) {
                legendColor = Colors.grey;
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: legendColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF37474F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
