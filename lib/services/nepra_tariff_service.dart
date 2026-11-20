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

  static const double defaultMeterRent = 50.0;

  static BillCalculation calculateBill({
    required String provider,
    required List<ApplianceItem> appliances,
    double fpaRatePerUnit = 2.50,
    double qtaRatePerUnit = 1.75,
    bool includeMeterRent = true,
    double fixedChargesRate = 0.0,
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

    final baseEnergyCharge = _calculateBaseEnergy(
      totalUnits: totalUnits,
      offPeakUnits: offPeakUnits,
      peakUnits: peakUnits,
      isProtected: isProtected,
    );

    final fpaCharge = totalUnits * fpaRatePerUnit;
    final qtaCharge = totalUnits * qtaRatePerUnit;
    final fixedCharges = totalUnits > 0 ? fixedChargesRate : 0.0;
    final meterRent =
    (totalUnits > 0 && includeMeterRent) ? defaultMeterRent : 0.0;

    final taxableSubtotal =
        baseEnergyCharge + fpaCharge + qtaCharge + fixedCharges;
    final gstAndDuties = taxableSubtotal * 0.18;
    final totalBill = taxableSubtotal + gstAndDuties + meterRent;

    double excessUnitsOverProtected = 0.0;
    double estimatedSavingsIfProtected = 0.0;

    if (!isProtected && totalUnits > 0) {
      excessUnitsOverProtected = totalUnits - 200.0;
      final cappedBase = _calculateBaseEnergy(
        totalUnits: 200.0,
        offPeakUnits: 200.0,
        peakUnits: 0.0,
        isProtected: true,
      );
      final cappedFpa = 200.0 * fpaRatePerUnit;
      final cappedQta = 200.0 * qtaRatePerUnit;
      final cappedTaxable = cappedBase + cappedFpa + cappedQta + fixedCharges;
      final cappedGst = cappedTaxable * 0.18;
      final cappedTotal = cappedTaxable + cappedGst + meterRent;
      estimatedSavingsIfProtected =
          (totalBill - cappedTotal).clamp(0.0, totalBill);
    }

    return BillCalculation(
      provider: provider,
      totalUnits: totalUnits,
      peakUnits: peakUnits,
      offPeakUnits: offPeakUnits,
      isProtected: isProtected,
      excessUnitsOverProtected: excessUnitsOverProtected,
      estimatedSavingsIfProtected: estimatedSavingsIfProtected,
      baseEnergyCharge: baseEnergyCharge,
      fpaCharge: fpaCharge,
      qtaCharge: qtaCharge,
      fixedCharges: fixedCharges,
      meterRent: meterRent,
      gstAndDuties: gstAndDuties,
      totalBill: totalBill,
      timestamp: DateTime.now(),
    );
  }

  static double estimateApplianceMonthlyCost({
    required ApplianceItem item,
    required bool isProtected,
    double fpaRatePerUnit = 2.50,
    double qtaRatePerUnit = 1.75,
  }) {
    final units = item.monthlyUnits;
    if (units <= 0) return 0.0;

    final ratePerUnit =
    item.isPeakHours ? 48.00 : (isProtected ? 14.16 : 30.07);
    final energy = units * ratePerUnit;
    final adjustments = units * (fpaRatePerUnit + qtaRatePerUnit);
    return (energy + adjustments) * 1.18;
  }

  static double _calculateBaseEnergy({
    required double totalUnits,
    required double offPeakUnits,
    required double peakUnits,
    required bool isProtected,
  }) {
    if (totalUnits <= 0) return 0.0;
    if (isProtected) {
      if (totalUnits <= 100) {
        return totalUnits * 11.69;
      }
      return (100 * 11.69) + ((totalUnits - 100) * 14.16);
    }
    return _calculateUnprotectedSlabs(offPeakUnits) + (peakUnits * 48.00);
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