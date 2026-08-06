import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:albmap/core/widgets/primary_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('tapping the button while idle invokes onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Submit', onPressed: () => tapped = true)),
    );

    await tester.tap(find.byType(ElevatedButton));
    expect(tapped, isTrue);
  });

  // This is the guard against double-submission: without disabling the
  // button while a request is in flight, a slow network response plus an
  // impatient double-tap fires the submit handler twice (e.g. two
  // POST /businesses calls for the same form).
  testWidgets('isLoading disables the button so it cannot be tapped again', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Submit', isLoading: true, onPressed: () => tapCount++)),
    );

    final buttonWidget = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(buttonWidget.onPressed, isNull);

    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    expect(tapCount, 0);

    // Shows a spinner instead of the label while loading.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
  });

  testWidgets('outlined variant also disables while loading', (tester) async {
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Continue', outlined: true, isLoading: true, onPressed: () {})),
    );

    final buttonWidget = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(buttonWidget.onPressed, isNull);
  });
}
