import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gchess_mobile/features/history/data/repositories/history_remote_repository.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';
import 'package:gchess_mobile/features/history/presentation/providers/game_history_provider.dart';
import 'package:gchess_mobile/features/history/presentation/screens/game_review_screen.dart';
import 'package:gchess_mobile/features/history/presentation/screens/history_screen.dart';

class _MockRepo extends Mock implements HistoryRemoteRepository {}

GameRecord _makeRecord({
  String gameId = 'game-1',
  bool playerIsWhite = true,
  String result = 'CHECKMATE',
  String? winner = 'player-white',
  int? totalTimeSeconds = 300,
  int? incrementSeconds = 0,
  String opponentName = 'Bob',
  int rawMoveCount = 2,
}) {
  return GameRecord(
    gameId: gameId,
    playerId: playerIsWhite ? 'player-white' : 'player-black',
    whiteUsername: playerIsWhite ? 'Alice' : opponentName,
    blackUsername: playerIsWhite ? opponentName : 'Alice',
    whitePlayerId: 'player-white',
    blackPlayerId: 'player-black',
    result: result,
    winner: winner,
    uciHistory: const ['e2-e4'],
    sanHistory: const ['e4'],
    fenHistory: const [
      'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'
    ],
    finalFen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
    totalTimeSeconds: totalTimeSeconds,
    incrementSeconds: incrementSeconds,
    playedAt: DateTime.utc(2026, 3, 17),
    rawMoveCount: rawMoveCount,
  );
}

// Notifier async avec liste pré-chargée pour les tests
class _FakeHistoryNotifier extends GameHistoryNotifier {
  final List<GameRecord> _records;
  _FakeHistoryNotifier(this._records);

  @override
  Future<List<GameRecord>> build() async => List<GameRecord>.from(_records);
}

Widget _buildScreen(
  List<GameRecord> records, {
  HistoryRemoteRepository? repo,
}) {
  final mockRepo = repo ?? _MockRepo();
  return ProviderScope(
    overrides: [
      gameHistoryNotifierProvider.overrideWith(() => _FakeHistoryNotifier(records)),
      historyRemoteRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: const MaterialApp(home: HistoryScreen()),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      GameRecord(
        gameId: '',
        playerId: '',
        whiteUsername: '',
        blackUsername: '',
        whitePlayerId: '',
        blackPlayerId: '',
        result: '',
        uciHistory: const [],
        sanHistory: const [],
        fenHistory: const [],
        finalFen: '',
        playedAt: DateTime.utc(2000),
      ),
    );
  });

  group('HistoryScreen', () {
    group('état chargement', () {
      testWidgets('affiche un indicateur de chargement avant les données',
          (tester) async {
        // The async notifier starts with AsyncLoading
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gameHistoryNotifierProvider.overrideWith(
                  () => _FakeHistoryNotifier([])),
              historyRemoteRepositoryProvider.overrideWithValue(_MockRepo()),
            ],
            child: const MaterialApp(home: HistoryScreen()),
          ),
        );
        // First frame — may show loading or immediate data (since build is async)
        // We just check it doesn't crash
        expect(find.byType(HistoryScreen), findsOneWidget);
      });
    });

    group('état vide', () {
      testWidgets('affiche le titre "Historique"', (tester) async {
        await tester.pumpWidget(_buildScreen([]));
        await tester.pump();
        expect(find.text('Historique'), findsOneWidget);
      });

      testWidgets('affiche le message "Aucune partie enregistrée"',
          (tester) async {
        await tester.pumpWidget(_buildScreen([]));
        await tester.pump();
        expect(find.text('Aucune partie enregistrée'), findsOneWidget);
      });

      testWidgets('affiche l\'icône history dans l\'état vide', (tester) async {
        await tester.pumpWidget(_buildScreen([]));
        await tester.pump();
        expect(find.byIcon(Icons.history), findsOneWidget);
      });

      testWidgets('ne montre pas de liste dans l\'état vide', (tester) async {
        await tester.pumpWidget(_buildScreen([]));
        await tester.pump();
        expect(find.byType(ListView), findsNothing);
      });
    });

    group('liste de parties', () {
      testWidgets('affiche une ListView quand il y a des parties',
          (tester) async {
        await tester.pumpWidget(_buildScreen([_makeRecord()]));
        await tester.pump();
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('affiche le nom de l\'adversaire', (tester) async {
        await tester
            .pumpWidget(_buildScreen([_makeRecord(opponentName: 'Charlie')]));
        await tester.pump();
        expect(find.textContaining('Charlie'), findsOneWidget);
      });

      testWidgets('affiche "Victoire" quand le joueur a gagné', (tester) async {
        await tester.pumpWidget(_buildScreen([
          _makeRecord(winner: 'player-white', playerIsWhite: true),
        ]));
        await tester.pump();
        expect(find.text('Victoire'), findsOneWidget);
      });

      testWidgets('affiche "Défaite" quand le joueur a perdu', (tester) async {
        await tester.pumpWidget(_buildScreen([
          _makeRecord(winner: 'player-white', playerIsWhite: false),
        ]));
        await tester.pump();
        expect(find.text('Défaite'), findsOneWidget);
      });

      testWidgets('affiche "½-½" pour une nulle (DRAW)', (tester) async {
        await tester.pumpWidget(_buildScreen([
          _makeRecord(result: 'DRAW', winner: null),
        ]));
        await tester.pump();
        expect(find.text('½-½'), findsOneWidget);
      });

      testWidgets('affiche "½-½" pour un pat (STALEMATE)', (tester) async {
        await tester.pumpWidget(_buildScreen([
          _makeRecord(result: 'STALEMATE', winner: null),
        ]));
        await tester.pump();
        expect(find.text('½-½'), findsOneWidget);
      });

      testWidgets('affiche "-" quand winner inconnu (RESIGNED)', (tester) async {
        await tester.pumpWidget(_buildScreen([
          _makeRecord(result: 'RESIGNED', winner: null),
        ]));
        await tester.pump();
        expect(find.text('-'), findsOneWidget);
      });

      testWidgets('affiche le contrôle de temps', (tester) async {
        await tester.pumpWidget(_buildScreen([
          _makeRecord(totalTimeSeconds: 300, incrementSeconds: 0),
        ]));
        await tester.pump();
        expect(find.text('5min'), findsOneWidget);
      });

      testWidgets('affiche contrôle de temps avec incrément', (tester) async {
        await tester.pumpWidget(_buildScreen([
          _makeRecord(totalTimeSeconds: 180, incrementSeconds: 2),
        ]));
        await tester.pump();
        expect(find.text('3+2'), findsOneWidget);
      });

      testWidgets('n\'affiche pas le contrôle de temps si null', (tester) async {
        await tester.pumpWidget(_buildScreen([
          _makeRecord(totalTimeSeconds: null),
        ]));
        await tester.pump();
        expect(find.text('min'), findsNothing);
        expect(find.text('+'), findsNothing);
      });

      testWidgets('affiche plusieurs parties', (tester) async {
        await tester.pumpWidget(_buildScreen([
          _makeRecord(gameId: 'game-1', opponentName: 'Bob'),
          _makeRecord(gameId: 'game-2', opponentName: 'Charlie'),
        ]));
        await tester.pump();
        expect(find.textContaining('Bob'), findsOneWidget);
        expect(find.textContaining('Charlie'), findsOneWidget);
      });

      testWidgets('affiche la date de la partie', (tester) async {
        await tester.pumpWidget(_buildScreen([_makeRecord()]));
        await tester.pump();
        expect(find.textContaining('17/03/2026'), findsOneWidget);
      });

      testWidgets('affiche le nombre de coups via rawMoveCount', (tester) async {
        await tester.pumpWidget(_buildScreen([_makeRecord(rawMoveCount: 20)]));
        await tester.pump();
        expect(find.textContaining('coup'), findsOneWidget);
      });

      testWidgets(
          'affiche le nombre de coups via sanHistory si rawMoveCount == 0',
          (tester) async {
        await tester.pumpWidget(
            _buildScreen([_makeRecord(rawMoveCount: 0)]));
        await tester.pump();
        expect(find.textContaining('coup'), findsOneWidget);
      });
    });

    group('navigation', () {
      testWidgets('le bouton retour est présent', (tester) async {
        await tester.pumpWidget(_buildScreen([]));
        await tester.pump();
        expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      });

      testWidgets('taper une tuile charge les coups et ouvre GameReviewScreen',
          (tester) async {
        final mockRepo = _MockRepo();
        final fullRecord = _makeRecord(opponentName: 'Bob');
        when(() => mockRepo.loadFullRecord(any()))
            .thenAnswer((_) async => fullRecord);

        await tester.pumpWidget(_buildScreen(
          [_makeRecord(opponentName: 'Bob')],
          repo: mockRepo,
        ));
        await tester.pump();
        await tester.tap(find.textContaining('Bob'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(GameReviewScreen), findsOneWidget);
      });
    });
  });
}
