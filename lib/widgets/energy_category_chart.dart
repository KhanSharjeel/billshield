import 'package:flutter/material.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/services/appliance_calculator.dart';

class EnergyCategoryChart extends StatelessWidget {
  final List<ApplianceItem> appliances;

  const EnergyCategoryChart({super.key, required this.appliances});

  static const Map<String, Color> categoryColors = {
    'Cooling & HVAC': Colors.blue,
    'Refrigeration': Colors.cyan,
    'Water & Heating': Colors.orange,
    'Lighting': Colors.amber,
    'Electronics': Colors.purple,
    'Other': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final categoryUnits = ApplianceCalculator.getUnitsByCategory(appliances);
    final totalUnits = ApplianceCalculator.calculateTotalMonthlyUnits(appliances);
    final safeTotal = totalUnits > 0 ? totalUnits : 1.0;

    final activeCategories = categoryUnits.entries
        .where((e) => e.value > 0)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Energy Draw by Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No active appliances to analyze.'),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    children: activeCategories.map((entry) {
                      final flex = ((entry.value / safeTotal) * 1000).round().clamp(1, 1000);
                      return Expanded(
                        flex: flex,
                        child: Container(
                          color: categoryColors[entry.key] ?? Colors.teal,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: activeCategories.map((entry) {
                  final pct = (entry.value / safeTotal) * 100;
                  final color = categoryColors[entry.key] ?? Colors.teal;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${entry.key}: ${entry.value.toStringAsFixed(1)} kWh (${pct.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
