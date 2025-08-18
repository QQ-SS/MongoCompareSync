/// 比较结果信息类
class ComparisonResultInfo {
  final bool isCompleted; // 比较是否完成
  final int sameCount; // 相同项数量
  final int diffCount; // 差异项数量

  ComparisonResultInfo({
    required this.isCompleted,
    this.sameCount = 0,
    this.diffCount = 0,
  });
}

/// 集合绑定类，用于表示源集合和目标集合之间的绑定关系
class CollectionBinding {
  final String sourceDatabase;
  final String sourceCollection;
  final String targetDatabase;
  final String targetCollection;
  final String id;

  CollectionBinding({
    required this.sourceDatabase,
    required this.sourceCollection,
    required this.targetDatabase,
    required this.targetCollection,
    required this.id,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionBinding &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
