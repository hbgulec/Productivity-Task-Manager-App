import 'package:hive/hive.dart';

class Session {
  final String id;
  final String taskId;
  final String taskName;
  final DateTime startAt;
  final DateTime endAt;
  final int durationSeconds;
  final int earnedPoints;
  final String dayKey;

  Session({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.startAt,
    required this.endAt,
    required this.durationSeconds,
    required this.earnedPoints,
    required this.dayKey,
  });
}

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 1;

  @override
  Session read(BinaryReader reader) {
    final id = reader.readString();
    final taskId = reader.readString();
    final startAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final endAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final durationSeconds = reader.readInt();
    final earnedPoints = reader.readInt();
    final dayKey = reader.readString();

    // Backward compatibility: try to read taskName, default if not present
    String taskName;
    try {
      taskName = reader.readString();
    } catch (_) {
      taskName = 'Deleted Task';
    }

    return Session(
      id: id,
      taskId: taskId,
      taskName: taskName,
      startAt: startAt,
      endAt: endAt,
      durationSeconds: durationSeconds,
      earnedPoints: earnedPoints,
      dayKey: dayKey,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.taskId);
    writer.writeInt(obj.startAt.millisecondsSinceEpoch);
    writer.writeInt(obj.endAt.millisecondsSinceEpoch);
    writer.writeInt(obj.durationSeconds);
    writer.writeInt(obj.earnedPoints);
    writer.writeString(obj.dayKey);
    writer.writeString(obj.taskName);
  }
}
