import 'package:flutter/material.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/models/ups_battery.dart';
import 'package:billshield/widgets/ups_backup_card.dart';

class BackupScreen extends StatefulWidget {
  final List<ApplianceItem> appliances;

  const BackupScreen({super.key, required this.appliances});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  UpsBattery _battery = const UpsBattery(
    batteryVoltage: 12,
    capacityAh: 200.0,
    batteryType: 'Tubular Lead-Acid',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UPS & Battery Backup Sizing')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              UpsBackupCard(
                appliances: widget.appliances,
                initialBattery: _battery,
                onBatteryChanged: (updated) {
                  setState(() => _battery = updated);
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
                        'Battery Sizing & Maintenance Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Tubular Lead-Acid batteries support ~65% Depth of Discharge (DoD), whereas Lithium LiFePO4 batteries allow ~90% DoD.\n'
                        '• Keep heavy inductive motor loads (AC, Water Pumps) off basic UPS systems to prevent inverter overload.\n'
                        '• Charging efficiency loss (~15%) adds a slight increase to monthly grid kWh consumption during recovery hours.',
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
