import 'package:equatable/equatable.dart';

class Scramble extends Equatable {
  final String notation;
  final String cubeType;
  final List<String> moves;
  final DateTime generatedAt;

  const Scramble({
    required this.notation,
    required this.cubeType,
    required this.moves,
    required this.generatedAt,
  });

  /// Get scramble as a single string
  String get scrambleString => moves.join(' ');

  /// Get number of moves
  int get moveCount => moves.length;

  @override
  List<Object?> get props => [notation, cubeType, moves, generatedAt];
}