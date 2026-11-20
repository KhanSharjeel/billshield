import 'package:flutter_test/flutter_test.dart';
import 'package:billshield/main.dart';

void main() {
  testWidgets('BillShieldApp instantiates cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const BillShieldApp());
    expect(find.byType(BillShieldApp), findsOneWidget);
  });
}