import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/history/data/repositories/game_history_repository.dart';
import 'package:gchess_mobile/features/history/data/repositories/history_storage_port.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';

// Stub minimal de HistoryStoragePort pour les tests
class FakePreferencesStorage implements HistoryStoragePort {
  final Map<String, String> _store = {};

  String? getString(String key) => _store[key];

  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }

  Future<void> remove(String key) async {
    _store.remove(key);
  }
}

GameRecord _makeRecord(String gameId, {String? playerId}) => GameRecord.fromGame(
      gameId: gameId,
      playerId: playerId ?? 'player-white',
      whiteUsername: 'Alice',
      blackUsername: 'Bob',
      whitePlayerId: 'player-white',
      blackPlayerId: 'player-black',
      result: 'CHECKMATE',
      winner: 'player-white',
      uciHistory: const ['e2-e4', 'e7-e5'],
      finalFen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
      totalTimeSeconds: 300,
      incrementSeconds: 0,
      playedAt: DateTime.utc(2026, 3, 17),
    );

void main() {
  late FakePreferencesStorage fakePrefs;
  late GameHistoryRepository repo;

  setUp(() {
    fakePrefs = FakePreferencesStorage();
    repo = GameHistoryRepository(fakePrefs);
  });

  group('loadAll', () {
    test('retourne une liste vide quand aucune donnée stockée', () {
      expect(repo.loadAll(), isEmpty);
    });

    test('retourne une liste vide si la valeur stockée est corrompue', () {
      fakePrefs._store['game_history'] = 'not-valid-json{{{';
      expect(repo.loadAll(), isEmpty);
    });
  });

  group('save', () {
    test('sauvegarde un enregistrement et le recharge', () async {
      final record = _makeRecord('game-1');
      await repo.save(record);

      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.gameId, 'game-1');
    });

    test('insère le plus récent en tête de liste', () async {
      await repo.save(_makeRecord('game-1'));
      await repo.save(_makeRecord('game-2'));

      final loaded = repo.loadAll();
      expect(loaded.first.gameId, 'game-2');
      expect(loaded[1].gameId, 'game-1');
    });

    test('n\'ajoute pas de doublon si le même gameId est sauvegardé deux fois', () async {
      final record = _makeRecord('game-1');
      await repo.save(record);
      await repo.save(record);

      expect(repo.loadAll(), hasLength(1));
    });

    test('remplace l\'entrée existante pour le même gameId', () async {
      await repo.save(_makeRecord('game-1'));
      final updated = _makeRecord('game-1', playerId: 'player-black');
      await repo.save(updated);

      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.playerId, 'player-black');
    });

    test('respecte la limite de 100 enregistrements', () async {
      for (int i = 0; i < 105; i++) {
        await repo.save(_makeRecord('game-$i'));
      }
      expect(repo.loadAll(), hasLength(100));
    });

    test('garde les 100 plus récents quand la limite est dépassée', () async {
      for (int i = 0; i < 105; i++) {
        await repo.save(_makeRecord('game-$i'));
      }
      // game-104 est le plus récent, game-5 est le plus ancien conservé
      final ids = repo.loadAll().map((r) => r.gameId).toList();
      expect(ids.first, 'game-104');
      expect(ids.last, 'game-5');
    });
  });

  group('delete', () {
    test('supprime l\'enregistrement correspondant au gameId', () async {
      await repo.save(_makeRecord('game-1'));
      await repo.save(_makeRecord('game-2'));

      await repo.delete('game-1');

      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.gameId, 'game-2');
    });

    test('ne lève pas d\'erreur si le gameId est introuvable', () async {
      await repo.save(_makeRecord('game-1'));
      await expectLater(repo.delete('inexistant'), completes);
    });
  });

  group('clearAll', () {
    test('supprime tous les enregistrements', () async {
      await repo.save(_makeRecord('game-1'));
      await repo.save(_makeRecord('game-2'));

      await repo.clearAll();

      expect(repo.loadAll(), isEmpty);
    });
  });
}
