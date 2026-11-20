import 'package:material_ui/material_ui.dart';

class SlabStatusBanner extends StatelessWidget {
  final double totalUnits;
  final bool isProtected;
  final double excessUnits;
  final double potentialSavings;

  const SlabStatusBanner({
    super.key,
    required this.totalUnits,
    required this.isProtected,
    this.excessUnits = 0.0,
    this.potentialSavings = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isProtected ? Colors.green : Colors.orange.shade800;
    final remainingToThreshold = (200.0 - totalUnits).clamp(0.0, 200.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
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
                      : 'Cut ${excessUnits.toStringAsFixed(1)} kWh/mo to drop back under 200 units (~Rs. ${potentialSavings.toStringAsFixed(0)} potential savings).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}