import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gchess_mobile/core/injection.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/connect_to_matchmaking.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/join_matchmaking_queue.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/leave_matchmaking_queue.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/bloc/matchmaking_state.dart';

// autoDispose par défaut — vit le temps de l'écran matchmaking
final matchmakingNotifierProvider =
    NotifierProvider.autoDispose<MatchmakingNotifier, MatchmakingState>(
  MatchmakingNotifier.new,
);

class MatchmakingNotifier extends Notifier<MatchmakingState> {
  StreamSubscription? _sub;

  @override
  MatchmakingState build() {
    final leaveQueue = getIt<LeaveMatchmakingQueue>();
    final repo = getIt<MatchmakingRepository>();
    ref.onDispose(() {
      _sub?.cancel();
      leaveQueue().then((_) {}); // fire-and-forget
      repo.disconnect(); // fire-and-forget
    });
    return const MatchmakingIdle();
  }

  Future<void> connect() async {
    state = const MatchmakingConnecting();
    final result = await getIt<ConnectToMatchmaking>()();
    result.fold(
      (f) => state = MatchmakingError(f.message),
      (_) {
        _sub?.cancel();
        _sub = getIt<MatchmakingRepository>().eventStream.listen((event) {
          // Assignations directes — pas d'événements internes
          if (event is QueuePositionEvent) {
            state = InQueue(position: event.position.position);
          } else if (event is MatchFoundEvent) {
            state = MatchFound(event.matchResult);
          } else if (event is MatchmakingErrorEvent) {
            state = MatchmakingError(event.message);
          }
        });
        state = const MatchmakingIdle();
      },
    );
  }

  Future<void> joinQueue(MatchRequest request) async {
    final result = await getIt<JoinMatchmakingQueue>()(request);
    result.fold(
      (f) => state = MatchmakingError(f.message),
      (_) => state = const InQueue(position: 1),
    );
  }

  Future<void> leaveQueue() async {
    final result = await getIt<LeaveMatchmakingQueue>()();
    result.fold(
      (f) => state = MatchmakingError(f.message),
      (_) => state = const MatchmakingIdle(),
    );
  }
}
