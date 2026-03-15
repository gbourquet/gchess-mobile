import 'package:equatable/equatable.dart';

class MatchRequest extends Equatable {
  final int? totalTimeMinutes;
  final int? incrementSeconds;

  const MatchRequest({
    this.totalTimeMinutes = 0,
    this.incrementSeconds = 0,
  });

  @override
  List<Object?> get props => [totalTimeMinutes, incrementSeconds];
}
