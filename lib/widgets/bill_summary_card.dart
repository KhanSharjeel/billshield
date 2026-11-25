import 'package:flutter/material.dart';
import 'package:billshield/models/bill_calculation.dart';

class BillSummaryCard extends StatelessWidget {
  final BillCalculation calculation;
  final VoidCallback onBreakdownPressed;

  const BillSummaryCard({
    super.key,
    required this.calculation,
    required this.onBreakdownPressed,
  });

  @override
  Widget build(BuildContext context) {
    final slabProgress = (calculation.totalUnits / 200.0).clamp(0.0, 1.0);
    final isOverLimit = calculation.totalUnits > 200.0;
    final progressColor = isOverLimit
        ? const Color(0xFFD32F2F)
        : (calculation.totalUnits > 150
            ? const Color(0xFFFF8F00)
            : Theme.of(context).colorScheme.primary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Estimated Monthly Bill',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          'Rs. ${calculation.totalBill.toStringAsFixed(0)}',
                          key: ValueKey(calculation.totalBill.round()),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${calculation.totalUnits.toStringAsFixed(1)} kWh / month',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (calculation.peakUnits > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Off-Peak: ${calculation.offPeakUnits.toStringAsFixed(1)} kWh • Peak: ${calculation.peakUnits.toStringAsFixed(1)} kWh',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onBreakdownPressed,
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Breakdown'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Protected Slab Threshold (200 kWh)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '${calculation.totalUnits.toStringAsFixed(0)} / 200 units',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: slabProgress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
