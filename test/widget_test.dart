import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billshield/main.dart';
import 'package:billshield/nepra_engine.dart';

void main() {
  test('NepraEngine calculation test', () {
    final resultProtected = NepraEngine.calculateMonthlyBill(
      consumedUnits: 150,
      isProtected: true,
      sanctionedLoadKw: 1.0,
    );

    expect(resultProtected['energyCharge'], equals(1704.5)); // (100 * 10.54) + (50 * 13.01) = 1054 + 650.5
    expect(resultProtected['fixedCharge'], equals(300.0));
    expect(resultProtected['isDangerZone'], equals(false));

    final resultDanger = NepraEngine.calculateMonthlyBill(
      consumedUnits: 185,
      isProtected: true,
      sanctionedLoadKw: 1.0,
    );
    expect(resultDanger['isDangerZone'], equals(true));
  });

  testWidgets('BillShieldApp loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const BillShieldApp());

    expect(find.text('BillShield'), findsWidgets);
    expect(find.text('ESTIMATED MONTHLY BILL'), findsOneWidget);
    expect(find.text('Usage & Account Settings'), findsOneWidget);
    expect(find.text('Detailed Bill Breakdown'), findsOneWidget);
  });
}
