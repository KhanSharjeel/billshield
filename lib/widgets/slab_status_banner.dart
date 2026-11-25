import 'package:flutter/material.dart';
import 'package:billshield/widgets/protected_status_card.dart';

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
    return ProtectedStatusCard(
      totalUnits: totalUnits,
      isProtected: isProtected,
      excessUnits: excessUnits,
      potentialSavings: potentialSavings,
    );
  }
}
