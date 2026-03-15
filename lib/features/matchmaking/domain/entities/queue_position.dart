import 'package:equatable/equatable.dart';

class QueuePosition extends Equatable {
  final int position;

  const QueuePosition({required this.position});

  @override
  List<Object?> get props => [position];
}
