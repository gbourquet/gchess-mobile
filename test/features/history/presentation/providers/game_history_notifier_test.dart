import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:gchess_mobile/features/history/data/repositories/history_remote_repository.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';
import 'package:gchess_mobile/features/history/presentation/providers/game_history_provider.dart';

void _setupFallbacks() {
  registerFallbackValue(
    const User(id: '', username: '', email: ''),
  );
}

class _MockRepo extends Mock implements HistoryRemoteRepository {}

class _FakeAuthNotifier extends AuthNotifier {
  final User? _user;
  _FakeAuthNotifier(this._user);

  @override
  Future<User?> build() async => _user;
}

const _alice = User(id: 'user-1', username: 'Alice', email: 'a@a.com');

GameRecord _makeRecord(String gameId) => GameRecord(
      gameId: gameId,
      playerId: 'user-1',
      whiteUsername: 'Alice',
      blackUsername: 'Bob',
      whitePlayerId: 'user-1',
      blackPlayerId: 'user-2',
      result: 'DRAW',
      winner: null,
      uciHistory: const [],
      sanHistory: const [],
      fenHistory: const [],
      finalFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      totalTimeSeconds: null,
      incrementSeconds: null,
      playedAt: DateTime.utc(2026, 3, 20),
    );

ProviderContainer _makeContainer({
  required _MockRepo repo,
  User? user = _alice,
}) {
  return ProviderContainer(
    overrides: [
      historyRemoteRepositoryProvider.overrideWithValue(repo),
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(user)),
    ],
  );
}

void main() {
  late _MockRepo mockRepo;

  setUpAll(_setupFallbacks);

  setUp(() {
    mockRepo = _MockRepo();
  });

  group('GameHistoryNotifier (AsyncNotifier)', () {
    test('retourne une liste vide si l\'API renvoie []', () async {
      when(() => mockRepo.fetchGames(_alice)).thenAnswer((_) async => []);
      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final result = await container.read(gameHistoryNotifierProvider.future);
      expect(result, isEmpty);
    });

    test('charge la liste de parties depuis le repo', () async {
      final records = [_makeRecord('g1'), _makeRecord('g2')];
      when(() => mockRepo.fetchGames(_alice)).thenAnswer((_) async => records);
      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final result = await container.read(gameHistoryNotifierProvider.future);
      expect(result, hasLength(2));
    });

    test('reload recharge la liste depuis le repo', () async {
      when(() => mockRepo.fetchGames(_alice))
          .thenAnswer((_) async => [_makeRecord('g1')]);
      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(gameHistoryNotifierProvider.future);

      when(() => mockRepo.fetchGames(_alice))
          .thenAnswer((_) async => [_makeRecord('g1'), _makeRecord('g2')]);

      await container.read(gameHistoryNotifierProvider.notifier).reload();
      final result = await container.read(gameHistoryNotifierProvider.future);
      expect(result, hasLength(2));
    });

    test('retourne [] si utilisateur non connecté', () async {
      final container = _makeContainer(repo: mockRepo, user: null);
      addTearDown(container.dispose);

      final result = await container.read(gameHistoryNotifierProvider.future);
      expect(result, isEmpty);
      // fetchGames should not have been called without a user
      verifyNever(() => mockRepo.fetchGames(const User(id: 'user-1', username: 'Alice', email: 'a@a.com')));
    });

    test('l\'état initial est AsyncLoading', () {
      when(() => mockRepo.fetchGames(_alice)).thenAnswer((_) async => []);
      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      // Before awaiting, the state should be loading
      final state = container.read(gameHistoryNotifierProvider);
      expect(state, isA<AsyncLoading<List<GameRecord>>>());
    });
  });
}
