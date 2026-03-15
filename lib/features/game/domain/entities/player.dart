import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String playerId;
  final String userId;
  final String username;
  final String color; // 'WHITE' or 'BLACK'

  const Player({
    required this.playerId,
    required this.userId,
    required this.username,
    required this.color,
  });

  @override
  List<Object?> get props => [playerId, userId, username, color];
}
