import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/models/electricity_provider.dart';

class NepraTariffService {
  static List<String> get providers => ElectricityProvider.providerCodes;

  static const double defaultMeterRentSinglePhase = 50.0;
  static const double defaultMeterRentThreePhase = 100.0;
  static const double defaultMeterRent = defaultMeterRentSinglePhase;
  static const double defaultTvFee = 35.0;

  static BillCalculation calculateBill({
    required String provider,
    required List<ApplianceItem> appliances,
    double fpaRatePerUnit = 2.50,
    double qtaRatePerUnit = 1.75,
    bool includeMeterRent = true,
    double fixedChargesRate = 0.0,
    bool includeTvFee = false,
    double electricityDutyPercent = 0.0,
    bool isThreePhase = false,
    bool is6MonthUnprotectedLocked = false,
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
    if (totalUnits <= 0) {
      return BillCalculation(
        provider: provider,
        totalUnits: 0.0,
        peakUnits: 0.0,
        offPeakUnits: 0.0,
        isProtected: !is6MonthUnprotectedLocked,
        is6MonthUnprotectedLocked: is6MonthUnprotectedLocked,
        isThreePhase: isThreePhase,
        excessUnitsOverProtected: 0.0,
        estimatedSavingsIfProtected: 0.0,
        baseEnergyCharge: 0.0,
        fpaCharge: 0.0,
        qtaCharge: 0.0,
        fixedCharges: 0.0,
        meterRent: 0.0,
        tvFee: 0.0,
        electricityDuty: 0.0,
        gstAndDuties: 0.0,
        totalBill: 0.0,
        timestamp: DateTime.now(),
      );
    }

    // A consumer is Protected if totalUnits <= 200 AND NOT locked by 6-month unprotected rule
    final isProtected = (totalUnits <= 200.0) && !is6MonthUnprotectedLocked;

    final baseEnergyCharge = _calculateBaseEnergy(
      totalUnits: totalUnits,
      offPeakUnits: offPeakUnits,
      peakUnits: peakUnits,
      isProtected: isProtected,
    );

    final fpaCharge = totalUnits * fpaRatePerUnit;
    final qtaCharge = totalUnits * qtaRatePerUnit;
    final fixedCharges = totalUnits > 0 ? fixedChargesRate : 0.0;

    final standardMeterRent =
        isThreePhase ? defaultMeterRentThreePhase : defaultMeterRentSinglePhase;
    final meterRent = (totalUnits > 0 && includeMeterRent) ? standardMeterRent : 0.0;

    final tvFee = (totalUnits > 0 && includeTvFee) ? defaultTvFee : 0.0;
    final electricityDuty = baseEnergyCharge * (electricityDutyPercent / 100.0);

    final taxableSubtotal =
        baseEnergyCharge + fpaCharge + qtaCharge + fixedCharges + electricityDuty;
    final gstAndDuties = taxableSubtotal * 0.18;
    final totalBill = taxableSubtotal + gstAndDuties + meterRent + tvFee;

    double excessUnitsOverProtected = 0.0;
    double estimatedSavingsIfProtected = 0.0;

    if (!isProtected && totalUnits > 0) {
      excessUnitsOverProtected = totalUnits > 200.0 ? totalUnits - 200.0 : 0.0;
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
      final cappedTotal = cappedTaxable + cappedGst + meterRent + tvFee;
      estimatedSavingsIfProtected =
          (totalBill - cappedTotal).clamp(0.0, totalBill);
    }

    return BillCalculation(
      provider: provider,
      totalUnits: totalUnits,
      peakUnits: peakUnits,
      offPeakUnits: offPeakUnits,
      isProtected: isProtected,
      is6MonthUnprotectedLocked: is6MonthUnprotectedLocked,
      isThreePhase: isThreePhase,
      excessUnitsOverProtected: excessUnitsOverProtected,
      estimatedSavingsIfProtected: estimatedSavingsIfProtected,
      baseEnergyCharge: baseEnergyCharge,
      fpaCharge: fpaCharge,
      qtaCharge: qtaCharge,
      fixedCharges: fixedCharges,
      meterRent: meterRent,
      tvFee: tvFee,
      electricityDuty: electricityDuty,
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
