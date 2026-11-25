import 'package:flutter/material.dart';
import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/models/solar_system.dart';
import 'package:billshield/widgets/solar_simulator_card.dart';

class SolarScreen extends StatefulWidget {
  final BillCalculation currentBill;

  const SolarScreen({super.key, required this.currentBill});

  @override
  State<SolarScreen> createState() => _SolarScreenState();
}

class _SolarScreenState extends State<SolarScreen> {
  SolarSystem _solarSystem = const SolarSystem(
    systemCapacityKw: 5.0,
    dailyPeakSunHours: 5.0,
    exportBuybackRate: 22.0,
    systemCostPkr: 850000.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solar PV & Net-Metering')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SolarSimulatorCard(
                currentBill: widget.currentBill,
                initialSolar: _solarSystem,
                onSolarChanged: (updated) {
                  setState(() => _solarSystem = updated);
                },
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About NEPRA Net-Metering Regulations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Grid-tied solar systems export excess daytime energy back to the local DISCO grid.\n'
                        '• DISCOs offset exported units against off-peak grid units on a 1:1 unit basis or at NEPRA buyback rate (~Rs 22/kWh).\n'
                        '• Substantial net-metering credits carry forward to offset peak winter grid bills.',
                        style: TextStyle(height: 1.4, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
