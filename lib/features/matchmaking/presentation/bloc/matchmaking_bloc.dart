import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/connect_to_matchmaking.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/join_matchmaking_queue.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/leave_matchmaking_queue.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/bloc/matchmaking_event.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/bloc/matchmaking_state.dart';

@injectable
class MatchmakingBloc extends Bloc<MatchmakingEvent, MatchmakingState> {
  final ConnectToMatchmaking connectToMatchmaking;
  final JoinMatchmakingQueue joinMatchmakingQueue;
  final LeaveMatchmakingQueue leaveMatchmakingQueue;
  final MatchmakingRepository repository;

  StreamSubscription? _eventSubscription;

  MatchmakingBloc({
    required this.connectToMatchmaking,
    required this.joinMatchmakingQueue,
    required this.leaveMatchmakingQueue,
    required this.repository,
  }) : super(const MatchmakingIdle()) {
    on<ConnectToMatchmakingEvent>(_onConnect);
    on<JoinQueueEvent>(_onJoinQueue);
    on<LeaveQueueEvent>(_onLeaveQueue);
    on<DisconnectFromMatchmakingEvent>(_onDisconnect);
    on<_QueuePositionUpdated>(_onQueuePositionUpdated);
    on<_MatchFoundInternal>(_onMatchFoundInternal);
    on<_MatchmakingErrorInternal>(_onMatchmakingErrorInternal);
  }

  Future<void> _onConnect(
    ConnectToMatchmakingEvent event,
    Emitter<MatchmakingState> emit,
  ) async {
    emit(const MatchmakingConnecting());

    final result = await connectToMatchmaking();

    result.fold(
      (failure) => emit(MatchmakingError(failure.message)),
      (_) {
        // Listen to matchmaking events
        _eventSubscription?.cancel();
        _eventSubscription = repository.eventStream.listen((event) {
          if (event is QueuePositionEvent) {
            add(_QueuePositionUpdated(event.position.position));
          } else if (event is MatchFoundEvent) {
            add(_MatchFoundInternal(event.matchResult));
          } else if (event is MatchmakingErrorEvent) {
            add(_MatchmakingErrorInternal(event.message));
          }
        });

        emit(const MatchmakingIdle());
      },
    );
  }

  Future<void> _onJoinQueue(
    JoinQueueEvent event,
    Emitter<MatchmakingState> emit,
  ) async {
    final result = await joinMatchmakingQueue(event.request);

    result.fold(
      (failure) => emit(MatchmakingError(failure.message)),
      (_) {
        emit(const InQueue(position: 1));
      },
    );
  }

  Future<void> _onLeaveQueue(
    LeaveQueueEvent event,
    Emitter<MatchmakingState> emit,
  ) async {
    final result = await leaveMatchmakingQueue();

    result.fold(
      (failure) => emit(MatchmakingError(failure.message)),
      (_) => emit(const MatchmakingIdle()),
    );
  }

  Future<void> _onDisconnect(
    DisconnectFromMatchmakingEvent event,
    Emitter<MatchmakingState> emit,
  ) async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;

    await repository.disconnect();
    emit(const MatchmakingIdle());
  }

  Future<void> _onQueuePositionUpdated(
    _QueuePositionUpdated event,
    Emitter<MatchmakingState> emit,
  ) async {
    emit(InQueue(position: event.position));
  }

  Future<void> _onMatchFoundInternal(
    _MatchFoundInternal event,
    Emitter<MatchmakingState> emit,
  ) async {
    emit(MatchFound(event.matchResult));
  }

  Future<void> _onMatchmakingErrorInternal(
    _MatchmakingErrorInternal event,
    Emitter<MatchmakingState> emit,
  ) async {
    emit(MatchmakingError(event.message));
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }
}

// Internal events for stream updates
class _QueuePositionUpdated extends MatchmakingEvent {
  final int position;
  const _QueuePositionUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

class _MatchFoundInternal extends MatchmakingEvent {
  final dynamic matchResult;
  const _MatchFoundInternal(this.matchResult);

  @override
  List<Object?> get props => [matchResult];
}

class _MatchmakingErrorInternal extends MatchmakingEvent {
  final String message;
  const _MatchmakingErrorInternal(this.message);

  @override
  List<Object?> get props => [message];
}
