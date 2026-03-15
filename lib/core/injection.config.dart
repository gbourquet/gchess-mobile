// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../features/auth/data/datasources/auth_local_data_source.dart' as _i109;
import '../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i719;
import '../features/auth/data/repositories/auth_repository_impl.dart' as _i570;
import '../features/auth/domain/repositories/auth_repository.dart' as _i869;
import '../features/auth/domain/usecases/get_current_user.dart' as _i318;
import '../features/auth/domain/usecases/login_user.dart' as _i74;
import '../features/auth/domain/usecases/logout_user.dart' as _i563;
import '../features/auth/domain/usecases/register_user.dart' as _i789;
import '../features/game/data/datasources/game_websocket_data_source.dart'
    as _i1043;
import '../features/game/data/repositories/game_repository_impl.dart' as _i658;
import '../features/game/domain/repositories/game_repository.dart' as _i897;
import '../features/game/domain/usecases/claim_timeout.dart' as _i94;
import '../features/game/domain/usecases/connect_to_game.dart' as _i418;
import '../features/game/domain/usecases/disconnect_from_game.dart' as _i875;
import '../features/game/domain/usecases/send_move.dart' as _i65;
import '../features/matchmaking/data/datasources/matchmaking_websocket_data_source.dart'
    as _i630;
import '../features/matchmaking/data/repositories/matchmaking_repository_impl.dart'
    as _i402;
import '../features/matchmaking/domain/repositories/matchmaking_repository.dart'
    as _i297;
import '../features/matchmaking/domain/usecases/connect_to_matchmaking.dart'
    as _i634;
import '../features/matchmaking/domain/usecases/join_matchmaking_queue.dart'
    as _i979;
import '../features/matchmaking/domain/usecases/leave_matchmaking_queue.dart'
    as _i866;
import 'network/api_client.dart' as _i96;
import 'network/network_info.dart' as _i579;
import 'storage/preferences_storage.dart' as _i46;
import 'storage/secure_storage.dart' as _i473;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i473.SecureStorage>(
      () => _i473.SecureStorage(gh<_i558.FlutterSecureStorage>()),
    );
    gh.singleton<_i579.NetworkInfo>(
      () => _i579.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.singleton<_i46.PreferencesStorage>(
      () => _i46.PreferencesStorage(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i96.ApiClient>(
      () => _i96.ApiClient(
        gh<_i473.SecureStorage>(),
        gh<String>(instanceName: 'baseUrl'),
      ),
    );
    gh.factory<_i109.AuthLocalDataSource>(
      () => _i109.AuthLocalDataSourceImpl(
        gh<_i473.SecureStorage>(),
        gh<_i46.PreferencesStorage>(),
      ),
    );
    gh.singleton<_i1043.GameWebSocketDataSource>(
      () => _i1043.GameWebSocketDataSourceImpl(gh<_i473.SecureStorage>()),
    );
    gh.singleton<_i630.MatchmakingWebSocketDataSource>(
      () => _i630.MatchmakingWebSocketDataSourceImpl(gh<_i473.SecureStorage>()),
    );
    gh.factory<_i719.AuthRemoteDataSource>(
      () => _i719.AuthRemoteDataSourceImpl(gh<_i96.ApiClient>()),
    );
    gh.singleton<_i297.MatchmakingRepository>(
      () => _i402.MatchmakingRepositoryImpl(
        dataSource: gh<_i630.MatchmakingWebSocketDataSource>(),
      ),
    );
    gh.singleton<_i897.GameRepository>(
      () => _i658.GameRepositoryImpl(
        dataSource: gh<_i1043.GameWebSocketDataSource>(),
      ),
    );
    gh.factory<_i634.ConnectToMatchmaking>(
      () => _i634.ConnectToMatchmaking(gh<_i297.MatchmakingRepository>()),
    );
    gh.factory<_i979.JoinMatchmakingQueue>(
      () => _i979.JoinMatchmakingQueue(gh<_i297.MatchmakingRepository>()),
    );
    gh.factory<_i866.LeaveMatchmakingQueue>(
      () => _i866.LeaveMatchmakingQueue(gh<_i297.MatchmakingRepository>()),
    );
    gh.factory<_i869.AuthRepository>(
      () => _i570.AuthRepositoryImpl(
        remoteDataSource: gh<_i719.AuthRemoteDataSource>(),
        localDataSource: gh<_i109.AuthLocalDataSource>(),
        networkInfo: gh<_i579.NetworkInfo>(),
      ),
    );
    gh.factory<_i94.ClaimTimeout>(
      () => _i94.ClaimTimeout(gh<_i897.GameRepository>()),
    );
    gh.factory<_i418.ConnectToGame>(
      () => _i418.ConnectToGame(gh<_i897.GameRepository>()),
    );
    gh.factory<_i875.DisconnectFromGame>(
      () => _i875.DisconnectFromGame(gh<_i897.GameRepository>()),
    );
    gh.factory<_i65.SendMove>(() => _i65.SendMove(gh<_i897.GameRepository>()));
    gh.factory<_i318.GetCurrentUser>(
      () => _i318.GetCurrentUser(gh<_i869.AuthRepository>()),
    );
    gh.factory<_i74.LoginUser>(
      () => _i74.LoginUser(gh<_i869.AuthRepository>()),
    );
    gh.factory<_i563.LogoutUser>(
      () => _i563.LogoutUser(gh<_i869.AuthRepository>()),
    );
    gh.factory<_i789.RegisterUser>(
      () => _i789.RegisterUser(gh<_i869.AuthRepository>()),
    );
    return this;
  }
}
