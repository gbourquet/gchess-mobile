import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/history/data/repositories/game_history_repository.dart';
import 'package:gchess_mobile/features/history/data/repositories/history_storage_port.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';
import 'package:gchess_mobile/features/history/presentation/providers/game_history_provider.dart';

class FakeStorage implements HistoryStoragePort {
  final Map<String, String> _store = {};

  @override
  String? getString(String key) => _store[key];

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }
}

GameRecord _makeRecord(String gameId) => GameRecord.fromGame(
      gameId: gameId,
      playerId: 'player-white',
      whiteUsername: 'Alice',
      blackUsername: 'Bob',
      whitePlayerId: 'player-white',
      blackPlayerId: 'player-black',
      result: 'CHECKMATE',
      winner: 'player-white',
      uciHistory: const ['e2-e4'],
      finalFen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      playedAt: DateTime.utc(2026, 3, 17),
    );

void main() {
  late FakeStorage fakeStorage;
  late ProviderContainer container;

  setUp(() {
    fakeStorage = FakeStorage();
    container = ProviderContainer(
      overrides: [
        gameHistoryRepositoryProvider
            .overrideWithValue(GameHistoryRepository(fakeStorage)),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('état initial est une liste vide', () {
    expect(container.read(gameHistoryNotifierProvider), isEmpty);
  });

  test('addRecord ajoute la partie et met à jour l\'état', () async {
    final record = _makeRecord('game-1');
    await container
        .read(gameHistoryNotifierProvider.notifier)
        .addRecord(record);

    final state = container.read(gameHistoryNotifierProvider);
    expect(state, hasLength(1));
    expect(state.first.gameId, 'game-1');
  });

  test('addRecord ajoute plusieurs parties dans l\'ordre inverse', () async {
    await container
        .read(gameHistoryNotifierProvider.notifier)
        .addRecord(_makeRecord('game-1'));
    await container
        .read(gameHistoryNotifierProvider.notifier)
        .addRecord(_makeRecord('game-2'));

    final state = container.read(gameHistoryNotifierProvider);
    expect(state.first.gameId, 'game-2');
    expect(state[1].gameId, 'game-1');
  });

  test('deleteRecord supprime la partie de l\'état', () async {
    await container
        .read(gameHistoryNotifierProvider.notifier)
        .addRecord(_makeRecord('game-1'));
    await container
        .read(gameHistoryNotifierProvider.notifier)
        .addRecord(_makeRecord('game-2'));

    await container
        .read(gameHistoryNotifierProvider.notifier)
        .deleteRecord('game-1');

    final state = container.read(gameHistoryNotifierProvider);
    expect(state, hasLength(1));
    expect(state.first.gameId, 'game-2');
  });

  test('clearAll vide l\'état', () async {
    await container
        .read(gameHistoryNotifierProvider.notifier)
        .addRecord(_makeRecord('game-1'));

    await container.read(gameHistoryNotifierProvider.notifier).clearAll();

    expect(container.read(gameHistoryNotifierProvider), isEmpty);
  });

  test('reload relit depuis le stockage', () async {
    // Simuler des données déjà présentes dans le stockage
    final repo = container.read(gameHistoryRepositoryProvider);
    await repo.save(_makeRecord('game-preloaded'));

    container.read(gameHistoryNotifierProvider.notifier).reload();

    expect(container.read(gameHistoryNotifierProvider).first.gameId,
        'game-preloaded');
  });
}
