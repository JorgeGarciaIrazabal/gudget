import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/hive_service.dart';

class EvolutionScreen extends StatelessWidget {
  const EvolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetService = Provider.of<BudgetService>(context);
    final monthlySummaries = budgetService.getMonthlySummaries();
    final Color? leftTitleColor = Theme.of(context).textTheme.bodySmall?.color;

    if (monthlySummaries.isEmpty) {
      return const Center(child: Text('Not enough data to show evolution. Add transactions for multiple months.'));
    }

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    List<FlSpot> balanceSpots = [];
    List<String> monthLabels = [];

    double minYValue = 0;
    double maxYValue = 0;

    // Initial pass to find overall min/max for Y-axis scaling
    monthlySummaries.forEach((monthKey, summary) {
      final income = summary['income'] ?? 0.0;
      final expense = summary['expense'] ?? 0.0;
      final balance = summary['balance'] ?? 0.0;

      if (income > maxYValue) maxYValue = income;
      if (expense > maxYValue) maxYValue = expense; // Expense is positive on chart
      if (balance > maxYValue) maxYValue = balance;
      if (balance < minYValue) minYValue = balance;
    });
    
    // If all values are 0 or positive, start Y axis at 0
    if (minYValue > 0) minYValue = 0;
    // Add padding to Y axis
    maxYValue = (maxYValue * 1.2).ceilToDouble();
    minYValue = (minYValue * (minYValue < 0 ? 1.2 : 0.8)).floorToDouble();
    if (maxYValue == 0 && minYValue == 0) maxYValue = 100; // Default if no data


    int i = 0;
    // Sort keys to ensure chronological order for spots and labels
    List<String> sortedMonthKeys = monthlySummaries.keys.toList()..sort();

    for (String monthKey in sortedMonthKeys) {
      final summary = monthlySummaries[monthKey]!;
      final income = summary['income'] ?? 0.0;
      final expense = summary['expense'] ?? 0.0;
      final balance = summary['balance'] ?? 0.0;

      incomeSpots.add(FlSpot(i.toDouble(), income));
      expenseSpots.add(FlSpot(i.toDouble(), expense));
      balanceSpots.add(FlSpot(i.toDouble(), balance));
      
      try {
        final date = DateFormat('yyyy-MM').parse(monthKey);
        monthLabels.add(DateFormat('MMM yy').format(date));
      } catch (e) {
        monthLabels.add(monthKey); // Fallback
      }
      i++;
    }
    
    final double maxXValue = (monthLabels.length -1).toDouble();
    if (monthLabels.isEmpty) { // Handle edge case for chart if somehow it's empty
         return const Center(child: Text('Not enough data points for chart.'));
    }


    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text("Financial Evolution", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (value, meta) => leftTitleWidgets(value, meta, minYValue, maxYValue, leftTitleColor))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < monthLabels.length) {
                        int labelDisplayFrequency = 1;
                        if (monthLabels.length > 18) {
                          labelDisplayFrequency = 3;
                        } else if (monthLabels.length > 9) labelDisplayFrequency = 2;

                        if (index % labelDisplayFrequency == 0) {
                             return SideTitleWidget(axisSide: meta.axisSide, space: 8.0, child: Text(monthLabels[index], style: const TextStyle(fontSize: 10)));
                        }
                        return Container();
                      }
                      return Container();
                    }),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Theme.of(context).dividerColor, width: 1)),
                minX: 0,
                maxX: maxXValue < 0 ? 0 : maxXValue, // Ensure maxX is not negative
                minY: minYValue,
                maxY: maxYValue,
                lineBarsData: [
                  _lineBarData(incomeSpots, Colors.green, "Income"),
                  _lineBarData(expenseSpots, Colors.red, "Expense"),
                  _lineBarData(balanceSpots, Theme.of(context).colorScheme.primary, "Balance", isCurved: false, isDashed: true),
                ],
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((LineBarSpot spot) {
                                String text;
                                String monthLabel = "";
                                if (spot.x.toInt() >= 0 && spot.x.toInt() < monthLabels.length) {
                                    monthLabel = "${monthLabels[spot.x.toInt()]}: ";
                                }

                                final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

                                switch (spot.barIndex) {
                                    case 0: text = 'Income: ${currencyFormatter.format(spot.y)}'; break;
                                    case 1: text = 'Expense: ${currencyFormatter.format(spot.y)}'; break;
                                    case 2: text = 'Balance: ${currencyFormatter.format(spot.y)}'; break;
                                    default: throw Error();
                                }
                                return LineTooltipItem(
                                    '$monthLabel$text', // Add month label to tooltip
                                    TextStyle(color: spot.bar.gradient?.colors.first ?? spot.bar.color ?? Colors.blueGrey, fontWeight: FontWeight.bold),
                                );
                            }).toList();
                        }
                    )
                ),
              ),
            ),
          ),
           const SizedBox(height: 20),
          _buildLegend(context),
        ],
      ),
    );
  }

  LineChartBarData _lineBarData(List<FlSpot> spots, Color color, String title, {bool isCurved = true, bool isDashed = false}) {
    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: spots.length < 15 && spots.isNotEmpty), // Show dots if few data points
      belowBarData: BarAreaData(show: false),
      dashArray: isDashed ? [5, 5] : null, // [dash_length, space_length]
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta, double minY, double maxY, Color? titleColor) {
    final style = TextStyle(
      color: titleColor,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    
    // Determine the interval based on the range
    double range = maxY - minY;
    if (range == 0) range = 100; // Avoid division by zero if min=max
    double interval = (range / 5).ceilToDouble(); // Show ~5-6 labels
    if (interval == 0) interval = (maxY/5).ceilToDouble();
    if (interval == 0) interval = 20; // fallback


    // Only show labels at calculated intervals, plus min, max, and 0 if in range
    bool showThisLabel = (value == minY || value == maxY || (value == 0 && minY <=0 && maxY >=0));
    if (!showThisLabel && interval > 0) {
        showThisLabel = (value % interval == 0);
    }
    // For very small ranges, the above might not work well, simple fallback:
    if (range < 10 && range > 0) {
        showThisLabel = true; // Show all if range is tiny
    }


    if (!showThisLabel && value != 0) return Container();


    if (value.abs() >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      text = '${(value / 1000).toStringAsFixed(value.abs() >= 10000 ? 0 : 1)}k';
    } else {
       text = value.toStringAsFixed(0);
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

   Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.green, "Income"),
        const SizedBox(width: 16),
        _legendItem(Colors.red, "Expense"),
        const SizedBox(width: 16),
        _legendItem(Theme.of(context).colorScheme.primary, "Balance"),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
