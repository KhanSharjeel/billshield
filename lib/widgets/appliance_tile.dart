import 'package:flutter/material.dart';
import 'package:billshield/models/appliance_item.dart';

class ApplianceTile extends StatelessWidget {
  final ApplianceItem item;
  final double estimatedMonthlyCost;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onPeakChanged;
  final ValueChanged<int>? onQuantityChanged;

  const ApplianceTile({
    super.key,
    required this.item,
    required this.estimatedMonthlyCost,
    this.onTap,
    required this.onDelete,
    required this.onPeakChanged,
    this.onQuantityChanged,
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
    return Icons.power;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: item.isPeakHours
                    ? Colors.orange.shade100
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                child: Icon(
                  _getIconForAppliance(item.name),
                  color: item.isPeakHours
                      ? Colors.orange.shade900
                      : Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (item.isPeakHours)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PEAK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.watts.toStringAsFixed(0)}W • ${item.dailyHours.toStringAsFixed(1)} hrs/day • ${item.monthlyUnits.toStringAsFixed(1)} kWh',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Est. ~Rs. ${estimatedMonthlyCost.toStringAsFixed(0)} / month',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (item.quantity > 1 && onQuantityChanged != null) {
                            onQuantityChanged!(item.quantity - 1);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.remove, size: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (onQuantityChanged != null) {
                            onQuantityChanged!(item.quantity + 1);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          item.isPeakHours ? Icons.flash_on : Icons.flash_off,
                          size: 20,
                          color: item.isPeakHours ? Colors.orange : Colors.grey,
                        ),
                        tooltip: 'Toggle Peak Hours',
                        onPressed: () => onPeakChanged(!item.isPeakHours),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Remove',
                        onPressed: onDelete,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
