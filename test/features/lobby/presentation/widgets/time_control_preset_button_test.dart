import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/lobby/presentation/widgets/time_control_preset_button.dart';

void main() {
  group('TimeControlPresetButton', () {
    Widget buildWidget({
      String timeControl = '5+0',
      String label = 'Blitz',
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TimeControlPresetButton(
            timeControl: timeControl,
            label: label,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('renders timeControl text', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(timeControl: '5+0', label: 'Blitz'));
      await tester.pumpAndSettle();

      expect(find.text('5+0'), findsOneWidget);
    });

    testWidgets('renders label text in uppercase', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(timeControl: '10+0', label: 'Rapide'));
      await tester.pumpAndSettle();

      // The widget calls label.toUpperCase() before rendering
      expect(find.text('RAPIDE'), findsOneWidget);
    });

    testWidgets('renders both timeControl and label', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(timeControl: '3+2', label: 'Blitz'));
      await tester.pumpAndSettle();

      expect(find.text('3+2'), findsOneWidget);
      expect(find.text('BLITZ'), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(buildWidget(
        timeControl: '5+0',
        label: 'Blitz',
        onTap: () => tapCount++,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    testWidgets('onTap is called exactly once per tap', (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(buildWidget(
        timeControl: '1+0',
        label: 'Bullet',
        onTap: () => tapCount++,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapCount, 2);
    });

    testWidgets('renders with InkWell for tap target', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
