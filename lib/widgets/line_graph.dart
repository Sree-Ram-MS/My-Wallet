import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';

class LineGraph extends StatelessWidget {
  final List<Record> records;

  const LineGraph({
    Key? key,
    required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Calculate values for the last 7 days
    final DateTime now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateTime(date.year, date.month, date.day);
    });

    final Map<DateTime, double> incomePerDay = {for (var d in last7Days) d: 0.0};
    final Map<DateTime, double> expensePerDay = {for (var d in last7Days) d: 0.0};

    bool hasAnyData = false;

    for (var r in records) {
      final recordDate = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
      if (incomePerDay.containsKey(recordDate)) {
        hasAnyData = true;
        if (r.type == 'income') {
          incomePerDay[recordDate] = (incomePerDay[recordDate] ?? 0) + r.amount;
        } else if (r.type == 'expense') {
          expensePerDay[recordDate] = (expensePerDay[recordDate] ?? 0) + r.amount;
        }
      }
    }

    // 2. Prepare plot coordinates (Spot lists)
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];

    double maxVal = 1000.0; // Dynamic scaling ceiling

    for (int i = 0; i < 7; i++) {
      final date = last7Days[i];
      final inc = incomePerDay[date] ?? 0.0;
      final exp = expensePerDay[date] ?? 0.0;

      incomeSpots.add(FlSpot(i.toDouble(), inc));
      expenseSpots.add(FlSpot(i.toDouble(), exp));

      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }

    // Add extra padding to chart top
    maxVal = maxVal * 1.15;

    // Elegant placeholder graph in case of zero data
    final List<FlSpot> mockIncome = const [
      FlSpot(0, 100), FlSpot(1, 300), FlSpot(2, 200), FlSpot(3, 600), FlSpot(4, 400), FlSpot(5, 800), FlSpot(6, 700)
    ];
    final List<FlSpot> mockExpense = const [
      FlSpot(0, 50), FlSpot(1, 150), FlSpot(2, 250), FlSpot(3, 100), FlSpot(4, 300), FlSpot(5, 450), FlSpot(6, 200)
    ];

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INFLOW VS OUTFLOW (7 DAYS)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem(context, 'Inflow', const Color(0xFF66BB6A)),
                  const SizedBox(width: 12),
                  _buildLegendItem(context, 'Outflow', const Color(0xFFEF5350)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                    strokeWidth: 1.0,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        String label = '';
                        if (value >= 1000) {
                          label = '${(value / 1000).toStringAsFixed(0)}k';
                        } else {
                          label = value.toStringAsFixed(0);
                        }
                        return Text(
                          label,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final int idx = value.toInt();
                        if (idx >= 0 && idx < 7) {
                          final date = last7Days[idx];
                          return Text(
                            DateFormat('E').format(date),
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: !hasAnyData ? 1000 : maxVal,
                lineBarsData: [
                  LineChartBarData(
                    spots: !hasAnyData ? mockIncome : incomeSpots,
                    isCurved: true,
                    color: const Color(0xFF66BB6A),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF66BB6A).withOpacity(0.06),
                    ),
                  ),
                  LineChartBarData(
                    spots: !hasAnyData ? mockExpense : expenseSpots,
                    isCurved: true,
                    color: const Color(0xFFEF5350),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFEF5350).withOpacity(0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
