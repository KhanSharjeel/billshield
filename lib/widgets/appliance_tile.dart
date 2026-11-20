import 'package:flutter/material.dart';
import 'package:billshield/models/appliance_item.dart';

class ApplianceTile extends StatelessWidget {
  final ApplianceItem item;
  final VoidCallback onDelete;
  final ValueChanged<bool> onPeakChanged;

  const ApplianceTile({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onPeakChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          '${item.name} (${item.quantity}x)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.watts.toStringAsFixed(0)}W • ${item.dailyHours.toStringAsFixed(1)} hrs/day • ${item.monthlyUnits.toStringAsFixed(1)} kWh/mo',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilterChip(
              label: const Text('Peak'),
              selected: item.isPeakHours,
              onSelected: onPeakChanged,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}