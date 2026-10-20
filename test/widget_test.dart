import 'package:flutter_test/flutter_test.dart';
import 'package:billshield/main.dart';
import 'package:billshield/models/nepra_engine.dart';

void main() {
  test('NepraEngine calculation test', () {
    final resultProtected = NepraEngine.calculateMonthlyBill(
      offPeakUnits: 150,
      peakUnits: 0,
      isProtected: true,
      sanctionedLoadKw: 1.0,
      provider: 'IESCO (Islamabad)',
    );

    expect(resultProtected['energyCharge'], equals(1704.5));
    expect(resultProtected['fixedCharge'], equals(300.0));
    expect(resultProtected['isDangerZone'], equals(false));

    final resultDanger = NepraEngine.calculateMonthlyBill(
      offPeakUnits: 185,
      peakUnits: 0,
      isProtected: true,
      sanctionedLoadKw: 1.0,
      provider: 'IESCO (Islamabad)',
    );
    expect(resultDanger['isDangerZone'], equals(true));
  });

  testWidgets('BillShieldApp loads correctly and transitions from splash to dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const BillShieldApp());

    // Initially displays Splash Screen
    expect(find.text('BillShield'), findsWidgets);

    // Fast-forward 6 seconds for splash screen transition
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 500));

    // After splash screen, Dashboard is displayed
    expect(find.text('BillShield — Unit Predictor'), findsOneWidget);
    expect(find.text('Appliance Simulator'), findsOneWidget);
    expect(find.text('Account Details & Adjustments'), findsOneWidget);
  });
}
