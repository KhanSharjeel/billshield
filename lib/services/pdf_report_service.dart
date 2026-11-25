import 'package:billshield/models/bill_calculation.dart';
import 'package:billshield/services/appliance_calculator.dart';
import 'package:billshield/models/appliance_item.dart';

class PdfReportService {
  static String generateAuditReportText({
    required BillCalculation calculation,
    required List<ApplianceItem> appliances,
  }) {
    final categoryUnits = ApplianceCalculator.getUnitsByCategory(appliances);
    final tips = ApplianceCalculator.generateEnergyTips(
      appliances,
      calculation.isProtected,
    );

    final buffer = StringBuffer()
      ..writeln('====================================================')
      ..writeln('        BILLSHIELD — ENERGY AUDIT & TARIFF REPORT   ')
      ..writeln('====================================================')
      ..writeln('Provider (DISCO): ${calculation.provider}')
      ..writeln('Meter Type: ${calculation.isThreePhase ? "Three-Phase (3P)" : "Single-Phase (1P)"}')
      ..writeln(
        'Slab Status: ${calculation.is6MonthUnprotectedLocked ? "UNPROTECTED (6-Month Lock)" : (calculation.isProtected ? "PROTECTED (<=200 kWh)" : "UNPROTECTED (>200 kWh)")}',
      )
      ..writeln(
        'Date Generated: ${calculation.timestamp.day}/${calculation.timestamp.month}/${calculation.timestamp.year}',
      )
      ..writeln('----------------------------------------------------')
      ..writeln('CONSUMPTION SUMMARY')
      ..writeln('----------------------------------------------------')
      ..writeln('Total Monthly Units: ${calculation.totalUnits.toStringAsFixed(1)} kWh')
      ..writeln('Off-Peak Units:      ${calculation.offPeakUnits.toStringAsFixed(1)} kWh')
      ..writeln('Peak Hours Units:    ${calculation.peakUnits.toStringAsFixed(1)} kWh')
      ..writeln('----------------------------------------------------')
      ..writeln('ITEMIZED FINANCIAL BREAKDOWN (PKR)')
      ..writeln('----------------------------------------------------')
      ..writeln('Base Energy Charge:      Rs. ${calculation.baseEnergyCharge.toStringAsFixed(2)}')
      ..writeln('Fuel Price Adj. (FPA):   Rs. ${calculation.fpaCharge.toStringAsFixed(2)}')
      ..writeln('Quarterly Adj. (QTA):    Rs. ${calculation.qtaCharge.toStringAsFixed(2)}');

    if (calculation.fixedCharges > 0) {
      buffer.writeln('Fixed Charges:           Rs. ${calculation.fixedCharges.toStringAsFixed(2)}');
    }
    if (calculation.meterRent > 0) {
      buffer.writeln('Meter Rent:              Rs. ${calculation.meterRent.toStringAsFixed(2)}');
    }
    if (calculation.tvFee > 0) {
      buffer.writeln('PTV Fee:                 Rs. ${calculation.tvFee.toStringAsFixed(2)}');
    }
    if (calculation.electricityDuty > 0) {
      buffer.writeln('Electricity Duty:        Rs. ${calculation.electricityDuty.toStringAsFixed(2)}');
    }

    buffer
      ..writeln('GST & Duties (18%):      Rs. ${calculation.gstAndDuties.toStringAsFixed(2)}')
      ..writeln('----------------------------------------------------')
      ..writeln('TOTAL ESTIMATED BILL:    Rs. ${calculation.totalBill.toStringAsFixed(2)}')
      ..writeln('====================================================')
      ..writeln('APPLIANCE CATEGORY BREAKDOWN')
      ..writeln('----------------------------------------------------');

    categoryUnits.forEach((category, units) {
      if (units > 0) {
        final pct = (units / (calculation.totalUnits > 0 ? calculation.totalUnits : 1.0)) * 100;
        buffer.writeln('• $category: ${units.toStringAsFixed(1)} kWh (${pct.toStringAsFixed(0)}%)');
      }
    });

    buffer
      ..writeln('----------------------------------------------------')
      ..writeln('ENERGY SAVINGS RECOMMENDATIONS')
      ..writeln('----------------------------------------------------');

    for (final tip in tips) {
      buffer.writeln('✔ $tip');
    }

    buffer.writeln('====================================================');
    return buffer.toString();
  }
}
