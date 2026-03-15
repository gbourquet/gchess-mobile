import 'package:equatable/equatable.dart';

class ChessMove extends Equatable {
  final String from;
  final String to;
  final String? promotion;

  const ChessMove({
    required this.from,
    required this.to,
    this.promotion,
  });

  @override
  List<Object?> get props => [from, to, promotion];
}
