import 'package:flutter_test/flutter_test.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/services/nepra_tariff_service.dart';

void main() {
  test('Units <= 200 remain in protected status', () {
    final result = NepraTariffService.calculateBill(
      provider: 'IESCO',
      appliances: const [
        ApplianceItem(name: 'Fans', watts: 100, quantity: 2, dailyHours: 25),
      ],
    );

    expect(result.totalUnits, 150.0);
    expect(result.isProtected, isTrue);
    expect(result.totalBill, greaterThan(0));
  });

  test('Units > 200 switch to unprotected status', () {
    final result = NepraTariffService.calculateBill(
      provider: 'LESCO',
      appliances: const [
        ApplianceItem(name: 'AC', watts: 1500, quantity: 1, dailyHours: 6),
      ],
    );

    expect(result.totalUnits, 270.0);
    expect(result.isProtected, isFalse);
  });
}