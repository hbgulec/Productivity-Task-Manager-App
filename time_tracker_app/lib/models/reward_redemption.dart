import 'package:hive/hive.dart';

class RewardRedemption {
  final String id;
  final String rewardId;
  final String rewardName;
  final DateTime redeemedAt;
  final int costPoints;

  RewardRedemption({
    required this.id,
    required this.rewardId,
    required this.rewardName,
    required this.redeemedAt,
    required this.costPoints,
  });
}

class RewardRedemptionAdapter extends TypeAdapter<RewardRedemption> {
  @override
  final int typeId = 3;

  @override
  RewardRedemption read(BinaryReader reader) {
    final id = reader.readString();
    final rewardId = reader.readString();
    final redeemedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final costPoints = reader.readInt();

    // Backward compatibility: try to read rewardName, default if not present
    String rewardName;
    try {
      rewardName = reader.readString();
    } catch (_) {
      rewardName = 'Deleted Reward';
    }

    return RewardRedemption(
      id: id,
      rewardId: rewardId,
      rewardName: rewardName,
      redeemedAt: redeemedAt,
      costPoints: costPoints,
    );
  }

  @override
  void write(BinaryWriter writer, RewardRedemption obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.rewardId);
    writer.writeInt(obj.redeemedAt.millisecondsSinceEpoch);
    writer.writeInt(obj.costPoints);
    writer.writeString(obj.rewardName);
  }
}
