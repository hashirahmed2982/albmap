import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:albmap/core/widgets/app_toast.dart';

void main() {
  Future<BuildContext> pumpAndCaptureContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  testWidgets('AppToast.error shows the given message', (tester) async {
    final ctx = await pumpAndCaptureContext(tester);

    AppToast.error(ctx, 'Something failed');
    await tester.pump();

    expect(find.text('Something failed'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('AppToast.success shows the given message', (tester) async {
    final ctx = await pumpAndCaptureContext(tester);

    AppToast.success(ctx, 'Saved successfully');
    await tester.pump();

    expect(find.text('Saved successfully'), findsOneWidget);
  });

  // Regression guard: before AppToast, screens called
  // ScaffoldMessenger.showSnackBar directly, and rapid consecutive calls
  // (e.g. two validation errors in a row) queued up instead of replacing
  // each other, so the user saw a stale message for several seconds
  // before the real one appeared.
  testWidgets('a second toast replaces the first instead of queuing behind it', (tester) async {
    final ctx = await pumpAndCaptureContext(tester);

    AppToast.error(ctx, 'First message');
    await tester.pump();
    AppToast.error(ctx, 'Second message');
    await tester.pump();

    expect(find.text('Second message'), findsOneWidget);
    expect(find.text('First message'), findsNothing);
  });
}
