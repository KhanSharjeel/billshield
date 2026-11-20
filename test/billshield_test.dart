import 'package:flutter_test/flutter_test.dart';
import 'package:billshield/models/appliance_item.dart';
import 'package:billshield/services/nepra_tariff_service.dart';

void main() {
  test('Calculates units and protected status under 200 kWh', () {
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
}
