import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/models/solar_system.dart';

class SolarResult {
  final double gridUnits;
  final double solarGenerationKwh;
  final double netUnitsImported;
  final double netUnitsExported;
  final double netBillPkr;
  final double monthlySavingsPkr;
  final double paybackYears;

  const SolarResult({
    required this.gridUnits,
    required this.solarGenerationKwh,
    required this.netUnitsImported,
    required this.netUnitsExported,
    required this.netBillPkr,
    required this.monthlySavingsPkr,
    required this.paybackYears,
  });
}

class SolarCalculator {
  static SolarResult calculateNetMetering({
    required BillCalculation originalBill,
    required SolarSystem solarSystem,
  }) {
    final gridUnits = originalBill.totalUnits;
    final solarGen = solarSystem.monthlyGenerationKwh;

    double netImported = 0.0;
    double netExported = 0.0;

    if (solarGen >= gridUnits) {
      netExported = solarGen - gridUnits;
      netImported = 0.0;
    } else {
      netImported = gridUnits - solarGen;
      netExported = 0.0;
    }

    double netBillPkr = 0.0;
    if (netImported > 0) {
      // Calculate net grid energy charge for netImported units
      final unitRatio = netImported / (gridUnits > 0 ? gridUnits : 1.0);
      netBillPkr = originalBill.totalBill * unitRatio;
    } else if (netExported > 0) {
      final exportCredit = netExported * solarSystem.exportBuybackRate;
      netBillPkr = -exportCredit; // Negative bill indicates credit carry-forward
    }

    final monthlySavings = originalBill.totalBill - netBillPkr;
    final annualSavings = monthlySavings * 12.0;

    double paybackYears = 0.0;
    if (annualSavings > 0 && solarSystem.systemCostPkr > 0) {
      paybackYears = solarSystem.systemCostPkr / annualSavings;
    }

    return SolarResult(
      gridUnits: gridUnits,
      solarGenerationKwh: solarGen,
      netUnitsImported: netImported,
      netUnitsExported: netExported,
      netBillPkr: netBillPkr,
      monthlySavingsPkr: monthlySavings,
      paybackYears: paybackYears,
    );
  }
}
