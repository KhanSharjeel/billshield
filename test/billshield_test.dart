import 'package:flutter_test/flutter_test.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/services/nepra_tariff_service.dart';
import 'package:billshield/services/appliance_calculator.dart';

void main() {
  group('NepraTariffService.calculateBill', () {
    test('keeps consumption at or below 200 units in protected status', () {
      final result = NepraTariffService.calculateBill(
        provider: 'IESCO',
        appliances: const [
          ApplianceItem(
            name: 'Ceiling Fan',
            watts: 100,
            quantity: 2,
            dailyHours: 25,
          ),
        ],
      );

      expect(result.provider, 'IESCO');
      expect(result.totalUnits, closeTo(150.0, 0.001));
      expect(result.offPeakUnits, closeTo(150.0, 0.001));
      expect(result.peakUnits, closeTo(0.0, 0.001));
      expect(result.isProtected, isTrue);
      expect(result.excessUnitsOverProtected, 0.0);
      expect(result.estimatedSavingsIfProtected, 0.0);
      expect(
        result.baseEnergyCharge,
        closeTo((100 * 11.69) + (50 * 14.16), 0.01),
      );
      expect(result.totalBill, greaterThan(result.baseEnergyCharge));
    });

    test('switches to unprotected status above 200 units and separates peak vs off-peak', () {
      final result = NepraTariffService.calculateBill(
        provider: 'LESCO',
        appliances: const [
          ApplianceItem(
            name: 'Inverter AC',
            watts: 1500,
            quantity: 1,
            dailyHours: 5,
            isPeakHours: true,
          ),
          ApplianceItem(
            name: 'Refrigerator',
            watts: 200,
            quantity: 1,
            dailyHours: 10,
            isPeakHours: false,
          ),
        ],
      );

      expect(result.peakUnits, closeTo(225.0, 0.001));
      expect(result.offPeakUnits, closeTo(60.0, 0.001));
      expect(result.totalUnits, closeTo(285.0, 0.001));
      expect(result.isProtected, isFalse);
      expect(result.excessUnitsOverProtected, closeTo(85.0, 0.001));
      expect(result.estimatedSavingsIfProtected, greaterThan(0.0));

      const expectedBase = (60.0 * 23.59) + (225.0 * 48.00);
      const expectedFpa = 285.0 * 2.50;
      const expectedQta = 285.0 * 1.75;
      const expectedMeterRent = 50.0;
      const expectedGst = (expectedBase + expectedFpa + expectedQta) * 0.18;
      const expectedTotal = expectedBase +
          expectedFpa +
          expectedQta +
          expectedGst +
          expectedMeterRent;

      expect(result.baseEnergyCharge, closeTo(expectedBase, 0.01));
      expect(result.fpaCharge, closeTo(expectedFpa, 0.01));
      expect(result.qtaCharge, closeTo(expectedQta, 0.01));
      expect(result.meterRent, closeTo(expectedMeterRent, 0.01));
      expect(result.gstAndDuties, closeTo(expectedGst, 0.01));
      expect(result.totalBill, closeTo(expectedTotal, 0.01));
    });

    test('returns zeroed charges when appliances list is empty', () {
      final result = NepraTariffService.calculateBill(
        provider: 'K-Electric',
        appliances: const [],
      );

      expect(result.totalUnits, 0.0);
      expect(result.peakUnits, 0.0);
      expect(result.offPeakUnits, 0.0);
      expect(result.isProtected, isTrue);
      expect(result.baseEnergyCharge, 0.0);
      expect(result.fpaCharge, 0.0);
      expect(result.qtaCharge, 0.0);
      expect(result.fixedCharges, 0.0);
      expect(result.meterRent, 0.0);
      expect(result.gstAndDuties, 0.0);
      expect(result.totalBill, 0.0);
    });

    test('applies custom FPA, QTA, fixed charges, and optional meter rent accurately', () {
      final result = NepraTariffService.calculateBill(
        provider: 'IESCO',
        appliances: const [
          ApplianceItem(
            name: 'Fans',
            watts: 100,
            quantity: 2,
            dailyHours: 25,
          ),
        ],
        fpaRatePerUnit: 3.20,
        qtaRatePerUnit: 2.10,
        fixedChargesRate: 200.0,
        includeMeterRent: false,
      );

      expect(result.fpaCharge, closeTo(150.0 * 3.20, 0.01));
      expect(result.qtaCharge, closeTo(150.0 * 2.10, 0.01));
      expect(result.fixedCharges, closeTo(200.0, 0.01));
      expect(result.meterRent, 0.0);
    });

    test('applies Three-Phase meter rent of 100 PKR correctly', () {
      final result = NepraTariffService.calculateBill(
        provider: 'IESCO',
        appliances: const [
          ApplianceItem(
            name: 'Inverter AC',
            watts: 1500,
            quantity: 1,
            dailyHours: 4,
          ),
        ],
        isThreePhase: true,
      );

      expect(result.isThreePhase, isTrue);
      expect(result.meterRent, 100.0);
    });

    test('enforces 6-month unprotected lock rule even when units <= 200', () {
      final result = NepraTariffService.calculateBill(
        provider: 'LESCO',
        appliances: const [
          ApplianceItem(
            name: 'Fan',
            watts: 75,
            quantity: 2,
            dailyHours: 10,
          ),
        ],
        is6MonthUnprotectedLocked: true,
      );

      expect(result.totalUnits, 45.0);
      expect(result.isProtected, isFalse);
      expect(result.is6MonthUnprotectedLocked, isTrue);
    });
  });

  group('ApplianceCalculator.getTopActionableSuggestion', () {
    test('generates an actionable hour reduction suggestion when consumption > 200 units', () {
      const list = [
        ApplianceItem(
          name: '1.5T Inverter AC',
          watts: 1500,
          quantity: 1,
          dailyHours: 6.0,
        ),
        ApplianceItem(
          name: 'Ceiling Fan',
          watts: 75,
          quantity: 2,
          dailyHours: 10.0,
        ),
      ];

      final suggestion = ApplianceCalculator.getTopActionableSuggestion(list, 315.0);
      expect(suggestion, isNotNull);
      expect(suggestion!.targetAppliance.name, '1.5T Inverter AC');
      expect(suggestion.newDailyHours, lessThan(6.0));
      expect(suggestion.savedKwh, greaterThan(0.0));
    });
  });
}
