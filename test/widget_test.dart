import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iot_protector/auth/atsign_gate_screen.dart';

void main() {
  testWidgets('Atsign gate blocks first-run app access', (tester) async {
    var continued = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AtsignGateScreen(onContinue: () => continued = true),
      ),
    );

    expect(find.text('An atSign is required'), findsOneWidget);
    expect(find.text('Get Starter Pack'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(continued, isTrue);
  });
}
