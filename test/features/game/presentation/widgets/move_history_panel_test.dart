import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/move_history_panel.dart';

void main() {
  group('MoveHistoryPanel', () {
    // Callbacks stubs
    void noop() {}
    void noopIndex(int _) {}

    Widget buildPanel({
      List<String> sanHistory = const [],
      int reviewIndex = -1,
      Function(int)? onMoveSelected,
      VoidCallback? onFirst,
      VoidCallback? onPrevious,
      VoidCallback? onNext,
      VoidCallback? onLast,
      VoidCallback? onReturnToLive,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MoveHistoryPanel(
            sanHistory: sanHistory,
            reviewIndex: reviewIndex,
            onMoveSelected: onMoveSelected ?? noopIndex,
            onFirst: onFirst ?? noop,
            onPrevious: onPrevious ?? noop,
            onNext: onNext ?? noop,
            onLast: onLast ?? noop,
            onReturnToLive: onReturnToLive ?? noop,
          ),
        ),
      );
    }

    testWidgets('shows empty state message when no moves', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(sanHistory: []));
      await tester.pumpAndSettle();

      expect(find.text('Aucun coup joué'), findsOneWidget);
    });

    testWidgets('shows em dash in nav bar when no moves and live', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(sanHistory: []));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('displays move SAN text for first white move', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(sanHistory: ['e4']));
      await tester.pumpAndSettle();

      expect(find.text('e4'), findsOneWidget);
    });

    testWidgets('displays both white and black moves', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(sanHistory: ['e4', 'e5']));
      await tester.pumpAndSettle();

      expect(find.text('e4'), findsOneWidget);
      expect(find.text('e5'), findsOneWidget);
    });

    testWidgets('displays move number prefix', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(sanHistory: ['e4', 'e5']));
      await tester.pumpAndSettle();

      expect(find.text('1.'), findsOneWidget);
    });

    testWidgets('displays correct move count label when live', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5', 'Nf3'],
        reviewIndex: -1,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Coup 3'), findsOneWidget);
    });

    testWidgets('shows LIVE button when in review mode', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5', 'Nf3', 'Nc6'],
        reviewIndex: 1,
      ));
      // Use pump (not pumpAndSettle) — _PulsingDot has a repeating animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // In review mode a button with "Coup X · LIVE" should appear
      expect(find.textContaining('LIVE'), findsOneWidget);
    });

    testWidgets('does not show LIVE button when in live mode', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5'],
        reviewIndex: -1,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('LIVE'), findsNothing);
    });

    testWidgets('calls onReturnToLive when LIVE button is tapped', (WidgetTester tester) async {
      bool returnToLiveCalled = false;

      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5', 'Nf3', 'Nc6'],
        reviewIndex: 0,
        onReturnToLive: () => returnToLiveCalled = true,
      ));
      // Use pump (not pumpAndSettle) — _PulsingDot has a repeating animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.textContaining('LIVE'));
      await tester.pump();

      expect(returnToLiveCalled, isTrue);
    });

    testWidgets('calls onMoveSelected when a move chip is tapped', (WidgetTester tester) async {
      int? selectedIndex;

      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5'],
        reviewIndex: -1,
        onMoveSelected: (index) => selectedIndex = index,
      ));
      await tester.pumpAndSettle();

      // Tap the white move chip 'e4' (index 0)
      await tester.tap(find.text('e4'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 0);
    });

    testWidgets('calls onFirst when first-page button is tapped', (WidgetTester tester) async {
      bool called = false;

      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5'],
        onFirst: () => called = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.first_page_rounded));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('calls onPrevious when chevron-left button is tapped', (WidgetTester tester) async {
      bool called = false;

      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5'],
        onPrevious: () => called = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('calls onNext when chevron-right button is tapped', (WidgetTester tester) async {
      bool called = false;

      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5'],
        onNext: () => called = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('calls onLast when last-page button is tapped', (WidgetTester tester) async {
      bool called = false;

      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5'],
        onLast: () => called = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.last_page_rounded));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('renders multiple move pairs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        sanHistory: ['e4', 'e5', 'Nf3', 'Nc6', 'd4'],
      ));
      await tester.pumpAndSettle();

      // 3 pairs → move numbers 1., 2., 3.
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('3.'), findsOneWidget);

      expect(find.text('e4'), findsOneWidget);
      expect(find.text('e5'), findsOneWidget);
      expect(find.text('Nf3'), findsOneWidget);
      expect(find.text('Nc6'), findsOneWidget);
      expect(find.text('d4'), findsOneWidget);
    });
  });
}
