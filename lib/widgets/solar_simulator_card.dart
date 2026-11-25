import 'package:flutter/material.dart';
import 'package:billshield/models/solar_system.dart';
import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/services/solar_calculator.dart';

class SolarSimulatorCard extends StatefulWidget {
  final BillCalculation currentBill;
  final SolarSystem initialSolar;
  final ValueChanged<SolarSystem> onSolarChanged;

  const SolarSimulatorCard({
    super.key,
    required this.currentBill,
    required this.initialSolar,
    required this.onSolarChanged,
  });

  @override
  State<SolarSimulatorCard> createState() => _SolarSimulatorCardState();
}

class _SolarSimulatorCardState extends State<SolarSimulatorCard> {
  late double _capacityKw;
  late double _sunHours;
  late double _buybackRate;
  late double _systemCost;

  @override
  void initState() {
    super.initState();
    _capacityKw = widget.initialSolar.systemCapacityKw;
    _sunHours = widget.initialSolar.dailyPeakSunHours;
    _buybackRate = widget.initialSolar.exportBuybackRate;
    _systemCost = widget.initialSolar.systemCostPkr;
  }

  void _update() {
    final updated = SolarSystem(
      systemCapacityKw: _capacityKw,
      dailyPeakSunHours: _sunHours,
      exportBuybackRate: _buybackRate,
      systemCostPkr: _systemCost,
    );
    widget.onSolarChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final currentSolar = SolarSystem(
      systemCapacityKw: _capacityKw,
      dailyPeakSunHours: _sunHours,
      exportBuybackRate: _buybackRate,
      systemCostPkr: _systemCost,
    );

    final result = SolarCalculator.calculateNetMetering(
      originalBill: widget.currentBill,
      solarSystem: currentSolar,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wb_sunny, color: Colors.amber.shade900),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solar PV & Net-Metering Simulator',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Offset grid consumption with solar energy & NEPRA buyback',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Solar Capacity: ${_capacityKw.toStringAsFixed(1)} kW',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _capacityKw,
              min: 1.0,
              max: 20.0,
              divisions: 38,
              label: '${_capacityKw.toStringAsFixed(1)} kW',
              onChanged: (val) {
                setState(() => _capacityKw = val);
                _update();
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Peak Sun Hours: ${_sunHours.toStringAsFixed(1)}h',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Export Buyback Rate: Rs. ${_buybackRate.toStringAsFixed(0)}/u',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monthly Solar Generation:'),
                      Text(
                        '${result.solarGenerationKwh.toStringAsFixed(0)} kWh',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Grid Units Payable:'),
                      Text(
                        '${result.netUnitsImported.toStringAsFixed(1)} kWh',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('New Monthly Net Bill:'),
                      Text(
                        result.netBillPkr >= 0
                            ? 'Rs. ${result.netBillPkr.toStringAsFixed(0)}'
                            : 'Credit: Rs. ${(-result.netBillPkr).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: result.netBillPkr <= 0
                              ? Colors.green.shade800
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monthly Bill Savings:'),
                      Text(
                        'Rs. ${result.monthlySavingsPkr.toStringAsFixed(0)} / mo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated ROI Payback:'),
                      Text(
                        '${result.paybackYears.toStringAsFixed(1)} Years',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
