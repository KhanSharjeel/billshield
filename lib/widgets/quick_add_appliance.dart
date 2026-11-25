import 'package:flutter/material.dart';
import 'package:billshield/models/appliance_item.dart';

class QuickAddApplianceSection extends StatelessWidget {
  final ValueChanged<ApplianceItem> onAddPreset;
  final ValueChanged<List<ApplianceItem>> onApplyHouseholdBundle;

  const QuickAddApplianceSection({
    super.key,
    required this.onAddPreset,
    required this.onApplyHouseholdBundle,
  });

  IconData _getIconForAppliance(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ac')) return Icons.ac_unit;
    if (lower.contains('fan')) return Icons.toys;
    if (lower.contains('refrigerator') || lower.contains('fridge')) {
      return Icons.kitchen;
    }
    if (lower.contains('iron')) return Icons.iron;
    if (lower.contains('pump')) return Icons.water_drop;
    if (lower.contains('tv')) return Icons.tv;
    if (lower.contains('bulb') || lower.contains('light')) return Icons.lightbulb;
    if (lower.contains('washing')) return Icons.local_laundry_service;
    return Icons.bolt;
  }

  static const List<Map<String, dynamic>> householdBundles = [
    {
      'title': '🎓 1-Room / Student',
      'unitsHint': '~60 units (Protected)',
      'appliances': [
        ApplianceItem(name: 'Ceiling Fan', watts: 75, quantity: 1, dailyHours: 12),
        ApplianceItem(name: 'LED Bulbs', watts: 12, quantity: 2, dailyHours: 6),
        ApplianceItem(name: 'Laptop / Charger', watts: 60, quantity: 1, dailyHours: 6),
      ],
    },
    {
      'title': '🏡 Standard Family',
      'unitsHint': '~180 units (Protected)',
      'appliances': [
        ApplianceItem(name: 'Ceiling Fan', watts: 75, quantity: 3, dailyHours: 10),
        ApplianceItem(name: 'LED Bulbs', watts: 12, quantity: 6, dailyHours: 6),
        ApplianceItem(name: 'Refrigerator', watts: 160, quantity: 1, dailyHours: 14),
        ApplianceItem(name: 'LED TV', watts: 80, quantity: 1, dailyHours: 4, isPeakHours: true),
        ApplianceItem(name: 'Water Pump (1 HP)', watts: 746, quantity: 1, dailyHours: 1),
        ApplianceItem(name: 'Electric Iron', watts: 1000, quantity: 1, dailyHours: 0.8),
      ],
    },
    {
      'title': '❄️ Summer AC Load',
      'unitsHint': '~350 units (Unprotected)',
      'appliances': [
        ApplianceItem(name: '1.5T Inverter AC', watts: 1500, quantity: 1, dailyHours: 6, isPeakHours: true),
        ApplianceItem(name: 'Ceiling Fan', watts: 75, quantity: 4, dailyHours: 12),
        ApplianceItem(name: 'LED Bulbs', watts: 12, quantity: 8, dailyHours: 6),
        ApplianceItem(name: 'Refrigerator', watts: 160, quantity: 1, dailyHours: 14),
        ApplianceItem(name: 'Water Pump (1 HP)', watts: 746, quantity: 1, dailyHours: 1),
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Household Load Bundles',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: householdBundles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final bundle = householdBundles[index];
              return ActionChip(
                elevation: 1,
                avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                label: Text(
                  '${bundle['title']} (${bundle['unitsHint']})',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  final list = List<ApplianceItem>.from(
                    bundle['appliances'] as List<ApplianceItem>,
                  );
                  onApplyHouseholdBundle(list);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(
              Icons.flash_on,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Quick-Add Pakistani Appliances',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ApplianceItem.quickAddPresets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = ApplianceItem.quickAddPresets[index];
              return ActionChip(
                avatar: Icon(
                  _getIconForAppliance(preset.name),
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  '${preset.name} (${preset.watts.toInt()}W)',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => onAddPreset(preset),
              );
            },
          ),
        ),
      ],
    );
  }
}
