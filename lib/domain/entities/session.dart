import 'package:equatable/equatable.dart';

class Session extends Equatable {
  final String id;
  final String name;
  final String cubeType;
  final DateTime createdAt;

  const Session({
    required this.id,
    required this.name,
    required this.cubeType,
    required this.createdAt,
  });

  Session copyWith({
    String? id,
    String? name,
    String? cubeType,
    DateTime? createdAt,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      cubeType: cubeType ?? this.cubeType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, cubeType, createdAt];
}