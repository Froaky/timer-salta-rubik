import '../../domain/entities/session.dart';

class SessionModel extends Session {
  const SessionModel({
    required super.id,
    required super.name,
    required super.cubeType,
    required super.createdAt,
  });

  factory SessionModel.fromEntity(Session session) {
    return SessionModel(
      id: session.id,
      name: session.name,
      cubeType: session.cubeType,
      createdAt: session.createdAt,
    );
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      cubeType: map['cube_type'] as String? ?? '3x3',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cube_type': cubeType,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}