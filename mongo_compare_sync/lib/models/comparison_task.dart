class ComparisonTask {
  final String name;
  final String sourceCollection;
  final String targetCollection;
  final String sourceDatabaseName;
  final String targetDatabaseName;
  final String? sourceConnectionId;
  final String? targetConnectionId;
  final String? idField;
  final List<String> ignoredFields;

  ComparisonTask({
    required this.name,
    required this.sourceCollection,
    required this.targetCollection,
    required this.sourceDatabaseName,
    required this.targetDatabaseName,
    this.sourceConnectionId,
    this.targetConnectionId,
    this.idField = '_id',
    this.ignoredFields = const [],
  });

  // 从DocumentTreeComparisonScreen创建任务
  factory ComparisonTask.fromComparisonScreen({
    required String name,
    required String sourceCollection,
    required String targetCollection,
    required String sourceDatabaseName,
    required String targetDatabaseName,
    String? sourceConnectionId,
    String? targetConnectionId,
    String? idField,
    List<String>? ignoredFields,
  }) {
    return ComparisonTask(
      name: name,
      sourceCollection: sourceCollection,
      targetCollection: targetCollection,
      sourceDatabaseName: sourceDatabaseName,
      targetDatabaseName: targetDatabaseName,
      sourceConnectionId: sourceConnectionId,
      targetConnectionId: targetConnectionId,
      idField: idField ?? '_id',
      ignoredFields: ignoredFields ?? [],
    );
  }

  // 从JSON反序列化
  factory ComparisonTask.fromJson(Map<String, dynamic> json) {
    return ComparisonTask(
      name: json['name'] as String,
      sourceCollection: json['sourceCollection'] as String,
      targetCollection: json['targetCollection'] as String,
      sourceDatabaseName: json['sourceDatabaseName'] as String,
      targetDatabaseName: json['targetDatabaseName'] as String,
      sourceConnectionId: json['sourceConnectionId'] as String?,
      targetConnectionId: json['targetConnectionId'] as String?,
      idField: json['idField'] as String? ?? '_id',
      ignoredFields:
          (json['ignoredFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  // 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sourceCollection': sourceCollection,
      'targetCollection': targetCollection,
      'sourceDatabaseName': sourceDatabaseName,
      'targetDatabaseName': targetDatabaseName,
      'sourceConnectionId': sourceConnectionId,
      'targetConnectionId': targetConnectionId,
      'idField': idField,
      'ignoredFields': ignoredFields,
    };
  }
}
