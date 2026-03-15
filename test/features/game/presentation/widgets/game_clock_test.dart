import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/game_clock.dart';

Widget _buildClock({
  required bool isCurrentTurn,
  required bool isWhite,
  required String playerName,
  required String playerColor,
  int? timeRemainingMs,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: GameClock(
          isCurrentTurn: isCurrentTurn,
          isWhite: isWhite,
          playerName: playerName,
          playerColor: playerColor,
          timeRemainingMs: timeRemainingMs,
        ),
      ),
    ),
  );
}

/// Pump and drain any RenderFlex overflow assertion from the fixed-height
/// internal SizedBox in _ClockTimeDisplay.
Future<void> pumpClock(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  tester.takeException(); // discard overflow assertion
}

void main() {
  group('GameClock', () {
    testWidgets('renders player name uppercased', (WidgetTester tester) async {
      await pumpClock(
        tester,
        _buildClock(
          isCurrentTurn: true,
          isWhite: true,
          playerName: 'Alice',
          playerColor: 'WHITE',
          timeRemainingMs: 600000,
        ),
      );

      expect(find.text('ALICE'), findsOneWidget);
    });

    testWidgets('renders JOUEUR BLANC for white player', (WidgetTester tester) async {
      await pumpClock(
        tester,
        _buildClock(
          isCurrentTurn: false,
          isWhite: true,
          playerName: 'Alice',
          playerColor: 'WHITE',
          timeRemainingMs: 600000,
        ),
      );

      expect(find.text('JOUEUR BLANC'), findsOneWidget);
    });

    testWidgets('renders JOUEUR NOIR for black player', (WidgetTester tester) async {
      await pumpClock(
        tester,
        _buildClock(
          isCurrentTurn: false,
          isWhite: false,
          playerName: 'Bob',
          playerColor: 'BLACK',
          timeRemainingMs: 300000,
        ),
      );

      expect(find.text('JOUEUR NOIR'), findsOneWidget);
    });

    testWidgets('formats 600000ms as 10:00', (WidgetTester tester) async {
      await pumpClock(
        tester,
        _buildClock(
          isCurrentTurn: true,
          isWhite: true,
          playerName: 'Alice',
          playerColor: 'WHITE',
          timeRemainingMs: 600000,
        ),
      );

      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('formats 0ms as 0:00', (WidgetTester tester) async {
      await pumpClock(
        tester,
        _buildClock(
          isCurrentTurn: false,
          isWhite: true,
          playerName: 'Alice',
          playerColor: 'WHITE',
          timeRemainingMs: 0,
        ),
      );

      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('shows first letter of player name as avatar', (WidgetTester tester) async {
      await pumpClock(
        tester,
        _buildClock(
          isCurrentTurn: false,
          isWhite: true,
          playerName: 'Bob',
          playerColor: 'WHITE',
          timeRemainingMs: 600000,
        ),
      );

      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('shows ? when player name is empty', (WidgetTester tester) async {
      await pumpClock(
        tester,
        _buildClock(
          isCurrentTurn: false,
          isWhite: true,
          playerName: '',
          playerColor: 'WHITE',
          timeRemainingMs: 600000,
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });
  });
}
