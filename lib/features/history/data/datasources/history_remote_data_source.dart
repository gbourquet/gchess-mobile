import 'package:gchess_mobile/core/network/api_client.dart';
import 'package:gchess_mobile/features/history/data/models/game_summary_dto.dart';
import 'package:gchess_mobile/features/history/data/models/move_summary_dto.dart';

class HistoryRemoteDataSource {
  final ApiClient _apiClient;

  HistoryRemoteDataSource(this._apiClient);

  Future<List<GameSummaryDTO>> fetchGames() async {
    final response = await _apiClient.get('/api/history/games');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => GameSummaryDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MoveSummaryDTO>> fetchMoves(String gameId) async {
    final response =
        await _apiClient.get('/api/history/games/$gameId/moves');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MoveSummaryDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
