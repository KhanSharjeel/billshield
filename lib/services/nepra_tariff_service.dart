import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/models/bill_calculation.dart';

class NepraTariffService {
  static const List<String> providers = [
    'IESCO',
    'LESCO',
    'K-Electric',
    'MEPCO',
    'FESCO',
    'PESCO',
    'GEPCO',
    'HESCO',
    'QESCO',
  ];

  static BillCalculation calculateBill({
    required String provider,
    required List<ApplianceItem> appliances,
    double fpaRatePerUnit = 2.50,
    double qtaRatePerUnit = 1.75,
  }) {
    double peakUnits = 0.0;
    double offPeakUnits = 0.0;

    for (final item in appliances) {
      final units = item.monthlyUnits;
      if (item.isPeakHours) {
        peakUnits += units;
      } else {
        offPeakUnits += units;
      }
    }

    final totalUnits = peakUnits + offPeakUnits;
    final isProtected = totalUnits <= 200.0;

    double baseEnergyCharge = 0.0;
    if (totalUnits > 0) {
      if (isProtected) {
        if (totalUnits <= 100) {
          baseEnergyCharge = totalUnits * 11.69;
        } else {
          baseEnergyCharge = (100 * 11.69) + ((totalUnits - 100) * 14.16);
        }
      } else {
        baseEnergyCharge = _calculateUnprotectedSlabs(offPeakUnits) +
            (peakUnits * 48.00);
      }
    }

    final fpaCharge = totalUnits * fpaRatePerUnit;
    final qtaCharge = totalUnits * qtaRatePerUnit;
    final subtotal = baseEnergyCharge + fpaCharge + qtaCharge;
    final gstAndDuties = subtotal * 0.18;
    final totalBill = subtotal + gstAndDuties;

    return BillCalculation(
      provider: provider,
      totalUnits: totalUnits,
      peakUnits: peakUnits,
      offPeakUnits: offPeakUnits,
      isProtected: isProtected,
      baseEnergyCharge: baseEnergyCharge,
      fpaCharge: fpaCharge,
      qtaCharge: qtaCharge,
      gstAndDuties: gstAndDuties,
      totalBill: totalBill,
      timestamp: DateTime.now(),
    );
  }

  static double _calculateUnprotectedSlabs(double units) {
    if (units <= 0) return 0.0;
    double cost = 0.0;
    double remaining = units;

    final first100 = remaining.clamp(0.0, 100.0);
    cost += first100 * 23.59;
    remaining -= first100;

    if (remaining > 0) {
      final next100 = remaining.clamp(0.0, 100.0);
      cost += next100 * 30.07;
      remaining -= next100;
    }

    if (remaining > 0) {
      final next100 = remaining.clamp(0.0, 100.0);
      cost += next100 * 34.26;
      remaining -= next100;
    }

    if (remaining > 0) {
      cost += remaining * 39.15;
    }

    return cost;
  }
}