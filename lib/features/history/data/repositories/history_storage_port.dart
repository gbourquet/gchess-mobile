/// Interface de stockage clé-valeur utilisée par GameHistoryRepository.
/// Permet d'injecter un double de test sans dépendre de SharedPreferences.
abstract class HistoryStoragePort {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}
