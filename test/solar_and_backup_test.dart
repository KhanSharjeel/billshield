import 'package:flutter_test/flutter_test.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/models/solar_system.dart';
import 'package:billshield/models/ups_battery.dart';
import 'package:billshield/models/scenario_comparison.dart';
import 'package:billshield/services/nepra_tariff_service.dart';
import 'package:billshield/services/solar_calculator.dart';
import 'package:billshield/services/backup_calculator.dart';
import 'package:billshield/services/pdf_report_service.dart';

void main() {
  group('SolarCalculator & SolarSystem', () {
    test('calculates solar generation and net-metering bill offset', () {
      const solar = SolarSystem(
        systemCapacityKw: 5.0,
        dailyPeakSunHours: 5.0,
        exportBuybackRate: 22.0,
        systemCostPkr: 850000.0,
      );

      expect(solar.dailyGenerationKwh, 25.0);
      expect(solar.monthlyGenerationKwh, 750.0);

      final originalBill = NepraTariffService.calculateBill(
        provider: 'IESCO',
        appliances: const [
          ApplianceItem(
            name: 'Inverter AC',
            watts: 1500,
            quantity: 1,
            dailyHours: 6,
          ),
        ],
      );

      final result = SolarCalculator.calculateNetMetering(
        originalBill: originalBill,
        solarSystem: solar,
      );

      expect(result.solarGenerationKwh, 750.0);
      expect(result.netUnitsExported, greaterThan(0.0));
      expect(result.netBillPkr, lessThan(0.0)); // Credit balance
      expect(result.monthlySavingsPkr, greaterThan(0.0));
    });
  });

  group('BackupCalculator & UpsBattery', () {
    test('calculates UPS battery backup runtime correctly', () {
      const battery = UpsBattery(
        batteryVoltage: 12,
        capacityAh: 200.0,
        batteryType: 'Tubular Lead-Acid',
        inverterEfficiency: 0.85,
      );

      const appliances = [
        ApplianceItem(
          name: 'Ceiling Fan',
          watts: 75,
          quantity: 2,
          dailyHours: 10,
        ),
        ApplianceItem(
          name: 'LED Bulbs',
          watts: 12,
          quantity: 4,
          dailyHours: 6,
        ),
      ];

      final result = BackupCalculator.calculateBackup(
        essentialAppliances: appliances,
        battery: battery,
      );

      expect(result.activeLoadWatts, 198.0); // 150W + 48W
      expect(result.backupHours, greaterThan(5.0));
      expect(result.monthlyRechargeKwh, greaterThan(0.0));
    });
  });

  group('ScenarioComparison', () {
    test('calculates scenario delta savings and payback period', () {
      const comparison = ScenarioComparison(
        scenarioNameA: 'Current Load',
        scenarioNameB: 'Inverter Load',
        unitsA: 350.0,
        unitsB: 180.0,
        billA: 24000.0,
        billB: 4500.0,
        investmentCostPkr: 180000.0,
      );

      expect(comparison.monthlySavingsPkr, 19500.0);
      expect(comparison.annualSavingsPkr, 234000.0);
      expect(comparison.paybackMonths, closeTo(9.23, 0.1));
    });
  });

  group('PdfReportService', () {
    test('generates clean audit report text', () {
      final bill = NepraTariffService.calculateBill(
        provider: 'LESCO',
        appliances: const [
          ApplianceItem(name: 'Fan', watts: 75, quantity: 2, dailyHours: 10),
        ],
      );

      final text = PdfReportService.generateAuditReportText(
        calculation: bill,
        appliances: const [
          ApplianceItem(name: 'Fan', watts: 75, quantity: 2, dailyHours: 10),
        ],
      );

      expect(text, contains('BILLSHIELD — ENERGY AUDIT & TARIFF REPORT'));
      expect(text, contains('LESCO'));
      expect(text, contains('TOTAL ESTIMATED BILL'));
    });
  });
}
