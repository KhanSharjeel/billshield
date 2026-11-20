import 'package:flutter/material.dart';

class SlabStatusBanner extends StatelessWidget {
  final double totalUnits;
  final bool isProtected;

  const SlabStatusBanner({
    super.key,
    required this.totalUnits,
    required this.isProtected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isProtected ? Colors.green : Colors.orange.shade800;
    final remainingToThreshold = (200.0 - totalUnits).clamp(0.0, 200.0);

    return Card(
      color: color.withValues(alpha: 0.12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              isProtected ? Icons.shield_outlined : Icons.warning_amber_rounded,
              color: color,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProtected
                        ? 'Protected Consumer (≤ 200 Units)'
                        : 'Unprotected Consumer (> 200 Units)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isProtected
                        ? '${remainingToThreshold.toStringAsFixed(1)} units remaining before unprotected slab jump.'
                        : '200-unit threshold exceeded. Higher tariff slabs & peak rates apply.',
                    style: Theme.of(context).textTheme.bodySmall,
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