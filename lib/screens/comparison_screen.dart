import 'package:flutter/material.dart';
import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/models/scenario_comparison.dart';
import 'package:billshield/widgets/scenario_comparator_widget.dart';

class ComparisonScreen extends StatefulWidget {
  final BillCalculation currentBill;

  const ComparisonScreen({super.key, required this.currentBill});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  late double _optimizedUnits;

  @override
  void initState() {
    super.initState();
    _optimizedUnits = (widget.currentBill.totalUnits * 0.65).clamp(50.0, 1000.0);
  }

  @override
  Widget build(BuildContext context) {
    final currentBillVal = widget.currentBill.totalBill;
    final ratio = _optimizedUnits / (widget.currentBill.totalUnits > 0 ? widget.currentBill.totalUnits : 1.0);
    final optimizedBillVal = currentBillVal * ratio;

    final comparison = ScenarioComparison(
      scenarioNameA: 'Current Load',
      scenarioNameB: 'Optimized / Inverter',
      unitsA: widget.currentBill.totalUnits,
      unitsB: _optimizedUnits,
      billA: currentBillVal,
      billB: optimizedBillVal,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('What-If Scenario Comparison')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simulate Energy Efficiency Upgrades',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Adjust target monthly consumption for Scenario B to model savings from upgrading to inverter appliances or switching to LED lighting.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Scenario B Target Units: ${_optimizedUnits.toStringAsFixed(0)} kWh',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        value: _optimizedUnits,
                        min: 30.0,
                        max: (widget.currentBill.totalUnits * 1.5).clamp(100.0, 1500.0),
                        divisions: 50,
                        label: '${_optimizedUnits.toStringAsFixed(0)} kWh',
                        onChanged: (val) {
                          setState(() => _optimizedUnits = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ScenarioComparatorWidget(comparison: comparison),
            ],
          ),
        ),
      ),
    );
  }
}
