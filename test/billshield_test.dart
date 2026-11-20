import 'package:flutter_test/flutter_test.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/services/nepra_tariff_service.dart';

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
      expect(result.baseEnergyCharge, closeTo((100 * 11.69) + (50 * 14.16), 0.01));
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

      final expectedBase = (60.0 * 23.59) + (225.0 * 48.00);
      final expectedFpa = 285.0 * 2.50;
      final expectedQta = 285.0 * 1.75;
      final expectedGst = (expectedBase + expectedFpa + expectedQta) * 0.18;
      final expectedTotal = expectedBase + expectedFpa + expectedQta + expectedGst;

      expect(result.baseEnergyCharge, closeTo(expectedBase, 0.01));
      expect(result.fpaCharge, closeTo(expectedFpa, 0.01));
      expect(result.qtaCharge, closeTo(expectedQta, 0.01));
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
      expect(result.gstAndDuties, 0.0);
      expect(result.totalBill, 0.0);
    });
  });
}
