import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gchess_mobile/core/injection.dart';
import 'package:gchess_mobile/core/storage/preferences_storage.dart';
import 'package:gchess_mobile/features/history/data/repositories/game_history_repository.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';

final gameHistoryRepositoryProvider = Provider<GameHistoryRepository>((ref) {
  return GameHistoryRepository(getIt<PreferencesStorage>());
});

final gameHistoryNotifierProvider =
    NotifierProvider<GameHistoryNotifier, List<GameRecord>>(
  GameHistoryNotifier.new,
);

class GameHistoryNotifier extends Notifier<List<GameRecord>> {
  @override
  List<GameRecord> build() {
    return ref.read(gameHistoryRepositoryProvider).loadAll();
  }

  Future<void> addRecord(GameRecord record) async {
    await ref.read(gameHistoryRepositoryProvider).save(record);
    state = ref.read(gameHistoryRepositoryProvider).loadAll();
  }

  Future<void> deleteRecord(String gameId) async {
    await ref.read(gameHistoryRepositoryProvider).delete(gameId);
    state = state.where((r) => r.gameId != gameId).toList();
  }

  Future<void> clearAll() async {
    await ref.read(gameHistoryRepositoryProvider).clearAll();
    state = [];
  }

  void reload() {
    state = ref.read(gameHistoryRepositoryProvider).loadAll();
  }
}
