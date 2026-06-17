import 'package:hive/hive.dart';

class Reward {
  final String id;
  final String title;
  final int costPoints;
  final DateTime createdAt;

  Reward({
    required this.id,
    required this.title,
    required this.costPoints,
    required this.createdAt,
  });

  Reward copyWith({
    String? id,
    String? title,
    int? costPoints,
    DateTime? createdAt,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      costPoints: costPoints ?? this.costPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class RewardAdapter extends TypeAdapter<Reward> {
  @override
  final int typeId = 2;

  @override
  Reward read(BinaryReader reader) {
    return Reward(
      id: reader.readString(),
      title: reader.readString(),
      costPoints: reader.readInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Reward obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeInt(obj.costPoints);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
