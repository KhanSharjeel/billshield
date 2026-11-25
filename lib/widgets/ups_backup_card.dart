import 'package:flutter/material.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/models/ups_battery.dart';
import 'package:billshield/services/backup_calculator.dart';

class UpsBackupCard extends StatefulWidget {
  final List<ApplianceItem> appliances;
  final UpsBattery initialBattery;
  final ValueChanged<UpsBattery> onBatteryChanged;

  const UpsBackupCard({
    super.key,
    required this.appliances,
    required this.initialBattery,
    required this.onBatteryChanged,
  });

  @override
  State<UpsBackupCard> createState() => _UpsBackupCardState();
}

class _UpsBackupCardState extends State<UpsBackupCard> {
  late int _voltage;
  late double _capacityAh;
  late String _type;

  @override
  void initState() {
    super.initState();
    _voltage = widget.initialBattery.batteryVoltage;
    _capacityAh = widget.initialBattery.capacityAh;
    _type = widget.initialBattery.batteryType;
  }

  void _update() {
    final updated = UpsBattery(
      batteryVoltage: _voltage,
      capacityAh: _capacityAh,
      batteryType: _type,
    );
    widget.onBatteryChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final battery = UpsBattery(
      batteryVoltage: _voltage,
      capacityAh: _capacityAh,
      batteryType: _type,
    );

    final result = BackupCalculator.calculateBackup(
      essentialAppliances: widget.appliances,
      battery: battery,
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
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.battery_charging_full,
                      color: Colors.blue.shade900),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Load-Shedding & Battery Backup Sizing',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'UPS runtime calculator & grid recharge consumption',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _voltage,
                    decoration: const InputDecoration(labelText: 'System Voltage'),
                    items: const [
                      DropdownMenuItem(value: 12, child: Text('12 V (1 Battery)')),
                      DropdownMenuItem(value: 24, child: Text('24 V (2 Batteries)')),
                      DropdownMenuItem(value: 48, child: Text('48 V (4 Batteries)')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _voltage = v);
                        _update();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Battery Type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Tubular Lead-Acid',
                        child: Text('Tubular (65% DoD)'),
                      ),
                      DropdownMenuItem(
                        value: 'Lithium LiFePO4',
                        child: Text('Lithium (90% DoD)'),
                      ),
                    ],
                    onChanged: (t) {
                      if (t != null) {
                        setState(() => _type = t);
                        _update();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Battery Capacity: ${_capacityAh.toInt()} Ah',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _capacityAh,
              min: 50.0,
              max: 600.0,
              divisions: 22,
              label: '${_capacityAh.toInt()} Ah',
              onChanged: (val) {
                setState(() => _capacityAh = val);
                _update();
              },
            ),
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Active Load:'),
                      Text(
                        '${result.activeLoadWatts.toStringAsFixed(0)} Watts',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Backup Runtime:'),
                      Text(
                        '${result.backupHours.toStringAsFixed(1)} Hours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grid Recharge Energy (2 outages/day):'),
                      Text(
                        '~${result.monthlyRechargeKwh.toStringAsFixed(1)} kWh / mo',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
