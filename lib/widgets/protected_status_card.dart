import 'package:flutter/material.dart';

class ProtectedStatusCard extends StatelessWidget {
  final double totalUnits;
  final bool isProtected;
  final bool is6MonthLocked;
  final bool isThreePhase;
  final double excessUnits;
  final double potentialSavings;

  const ProtectedStatusCard({
    super.key,
    required this.totalUnits,
    required this.isProtected,
    this.is6MonthLocked = false,
    this.isThreePhase = false,
    this.excessUnits = 0.0,
    this.potentialSavings = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isWarning = isProtected && totalUnits > 150.0;

    final Color color = !isProtected
        ? const Color(0xFFD32F2F)
        : (isWarning ? const Color(0xFFFF8F00) : const Color(0xFF00C853));

    final IconData icon = !isProtected
        ? Icons.warning_amber_rounded
        : (isWarning ? Icons.report_problem_outlined : Icons.shield_outlined);

    String title;
    if (is6MonthLocked) {
      title = 'UNPROTECTED (6-Month >200u Rule)';
    } else if (!isProtected) {
      title = 'UNPROTECTED CONSUMER (> 200 Units)';
    } else if (isWarning) {
      title = 'APPROACHING THRESHOLD (150–200 Units)';
    } else {
      title = 'PROTECTED CONSUMER (≤ 200 Units)';
    }

    final double remainingToThreshold = (200.0 - totalUnits).clamp(0.0, 200.0);

    String description;
    if (is6MonthLocked) {
      description =
          'Your meter is locked into Unprotected slab rates due to >200 kWh consumption in previous months. Current usage: ${totalUnits.toStringAsFixed(1)} kWh.';
    } else if (!isProtected) {
      description =
          'Your consumption exceeds 200 kWh by ${excessUnits.toStringAsFixed(1)} units. Unprotected slab rates active. Drop below 200 kWh to save ~Rs. ${potentialSavings.toStringAsFixed(0)}/mo.';
    } else if (isWarning) {
      description =
          'Used ${totalUnits.toStringAsFixed(1)} kWh! Only ${remainingToThreshold.toStringAsFixed(1)} units left before crossing into the expensive unprotected slab range.';
    } else {
      description =
          'Subsidized protected consumer slab active. ${remainingToThreshold.toStringAsFixed(1)} units remaining before 200 kWh threshold.';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Current Total: ${totalUnits.toStringAsFixed(1)} kWh',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (isThreePhase) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '3-Phase',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}
