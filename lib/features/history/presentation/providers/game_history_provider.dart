import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gchess_mobile/core/injection.dart';
import 'package:gchess_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:gchess_mobile/features/history/data/datasources/history_remote_data_source.dart';
import 'package:gchess_mobile/features/history/data/repositories/history_remote_repository.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';

final historyRemoteRepositoryProvider = Provider<HistoryRemoteRepository>((ref) {
  return HistoryRemoteRepository(
    HistoryRemoteDataSource(getIt()),
  );
});

final gameHistoryNotifierProvider =
    AsyncNotifierProvider<GameHistoryNotifier, List<GameRecord>>(
  GameHistoryNotifier.new,
);

class GameHistoryNotifier extends AsyncNotifier<List<GameRecord>> {
  @override
  Future<List<GameRecord>> build() async {
    final user = await ref.watch(authNotifierProvider.future);
    if (user == null) return [];
    return ref.read(historyRemoteRepositoryProvider).fetchGames(user);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Refresh without showing loading indicator (keeps current data visible).
  Future<void> silentRefresh() async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;
    try {
      final records =
          await ref.read(historyRemoteRepositoryProvider).fetchGames(user);
      state = AsyncData(records);
    } catch (_) {
      // Keep existing data on error
    }
  }
}
