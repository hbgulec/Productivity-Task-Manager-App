import 'package:hive/hive.dart';

enum TaskStatus { notStarted, inProgress, paused, completed }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final TaskStatus status;
  final int rewardMinutes;
  final int rewardPoints;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.status,
    required this.rewardMinutes,
    required this.rewardPoints,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    TaskStatus? status,
    int? rewardMinutes,
    int? rewardPoints,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      rewardMinutes: rewardMinutes ?? this.rewardMinutes,
      rewardPoints: rewardPoints ?? this.rewardPoints,
    );
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    return Task(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      status: TaskStatus.values[reader.readInt()],
      rewardMinutes: reader.readInt(),
      rewardPoints: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description ?? '');
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.status.index);
    writer.writeInt(obj.rewardMinutes);
    writer.writeInt(obj.rewardPoints);
  }
}
