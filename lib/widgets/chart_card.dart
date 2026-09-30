import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

/// A chart in a sheet of real liquid glass — title, subtitle and the chart
/// itself all sit on the refracting surface.
class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: GlassPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: GlassPalette.textTertiary,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class PieChartDistributionWidget extends StatefulWidget {
  final Map<String, int> dataMap;

  const PieChartDistributionWidget({super.key, required this.dataMap});

  @override
  State<PieChartDistributionWidget> createState() => _PieChartDistributionWidgetState();
}

class _PieChartDistributionWidgetState extends State<PieChartDistributionWidget> {
  int touchedIndex = -1;

  final List<Color> _colors = const [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.dataMap.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize: 13,
            color: GlassPalette.textTertiary,
          ),
        ),
      );
    }

    final total = widget.dataMap.values.fold(0, (sum, count) => sum + count);
    final entries = widget.dataMap.entries.toList();

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 36,
              sections: List.generate(entries.length, (i) {
                final isTouched = i == touchedIndex;
                final fontSize = isTouched ? 16.0 : 12.0;
                final radius = isTouched ? 55.0 : 45.0;
                final entry = entries[i];
                final percentage = (entry.value / total * 100).toStringAsFixed(1);
                final color = _colors[i % _colors.length];

                return PieChartSectionData(
                  color: color,
                  value: entry.value.toDouble(),
                  title: '$percentage%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final color = _colors[index % _colors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: GlassPalette.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: GlassPalette.indigo,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BarChartTopModelsWidget extends StatelessWidget {
  final Map<String, int> dataMap;

  const BarChartTopModelsWidget({super.key, required this.dataMap});

  @override
  Widget build(BuildContext context) {
    if (dataMap.isEmpty) {
      return const Center(
        child: Text(
          'No model telemetry recorded',
          style: TextStyle(
            fontSize: 13,
            color: GlassPalette.textTertiary,
          ),
        ),
      );
    }

    // Sort and pick top 5
    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(5).toList();

    final maxVal = topEntries.fold(0, (max, e) => e.value > max ? e.value : max).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal == 0 ? 10 : maxVal * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final modelName = topEntries[group.x.toInt()].key;
              return BarTooltipItem(
                '$modelName\n${rod.toY.toInt()} devices',
                const TextStyle(
                  color: GlassPalette.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= topEntries.length) return const SizedBox.shrink();
                final name = topEntries[idx].key;
                final shortName = name.length > 8 ? '${name.substring(0, 7)}…' : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    shortName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: GlassPalette.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(topEntries.length, (i) {
          final entry = topEntries[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                gradient: const LinearGradient(
                  colors: [
                    GlassPalette.indigo,
                    GlassPalette.violet,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
