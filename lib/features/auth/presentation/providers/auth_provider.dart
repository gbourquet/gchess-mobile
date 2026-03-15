import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gchess_mobile/core/injection.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/get_current_user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/register_user.dart';

// keepAlive — vit pour toute la durée de l'app
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Remplace AuthCheckRequested
    final result = await getIt<GetCurrentUser>()();
    return result.fold((_) => null, (u) => u);
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    final result = await getIt<LoginUser>()(
      username: username,
      password: password,
    );
    state = result.fold(
      (f) => AsyncError(f.message, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> register(
    String username,
    String email,
    String password,
  ) async {
    state = const AsyncLoading();
    final result = await getIt<RegisterUser>()(
      username: username,
      email: email,
      password: password,
    );
    state = result.fold(
      (f) => AsyncError(f.message, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    final result = await getIt<LogoutUser>()();
    state = result.fold(
      (f) => AsyncError(f.message, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
