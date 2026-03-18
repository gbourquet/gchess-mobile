import 'dart:convert';
import 'package:gchess_mobile/features/history/data/repositories/history_storage_port.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';

class GameHistoryRepository {
  static const _key = 'game_history';
  static const _maxRecords = 100;

  final HistoryStoragePort _storage;

  GameHistoryRepository(this._storage);

  List<GameRecord> loadAll() {
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => GameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(GameRecord record) async {
    final records = loadAll();
    records.removeWhere((r) => r.gameId == record.gameId);
    records.insert(0, record);
    if (records.length > _maxRecords) {
      records.removeRange(_maxRecords, records.length);
    }
    await _storage.setString(
        _key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  Future<void> delete(String gameId) async {
    final records = loadAll();
    records.removeWhere((r) => r.gameId == gameId);
    await _storage.setString(
        _key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  Future<void> clearAll() async {
    await _storage.remove(_key);
  }
}
