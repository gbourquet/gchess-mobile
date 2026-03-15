import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/main.dart';

void main() {
  testWidgets('GChess app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GChessApp());

    // Verify that the app loads
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
