class BindingConfig {
  final String sourceCollection;
  final String targetCollection;
  final String sourceDatabaseName;
  final String targetDatabaseName;

  BindingConfig({
    required this.sourceCollection,
    required this.targetCollection,
    required this.sourceDatabaseName,
    required this.targetDatabaseName,
  });

  // 从JSON反序列化
  factory BindingConfig.fromJson(Map<String, dynamic> json) {
    return BindingConfig(
      sourceCollection: json['sourceCollection'] as String,
      targetCollection: json['targetCollection'] as String,
      sourceDatabaseName: json['sourceDatabaseName'] as String,
      targetDatabaseName: json['targetDatabaseName'] as String,
    );
  }

  // 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'sourceCollection': sourceCollection,
      'targetCollection': targetCollection,
      'sourceDatabaseName': sourceDatabaseName,
      'targetDatabaseName': targetDatabaseName,
    };
  }
}

class ComparisonTask {
  final String name;
  final List<BindingConfig> bindings;
  final String? sourceConnectionId;
  final String? targetConnectionId;
  final String? idField;
  final List<String> ignoredFields;

  ComparisonTask({
    required this.name,
    required this.bindings,
    this.sourceConnectionId,
    this.targetConnectionId,
    this.idField = '_id',
    this.ignoredFields = const [],
  });

  // 从单个绑定创建任务
  factory ComparisonTask.fromSingleBinding({
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
      bindings: [
        BindingConfig(
          sourceCollection: sourceCollection,
          targetCollection: targetCollection,
          sourceDatabaseName: sourceDatabaseName,
          targetDatabaseName: targetDatabaseName,
        ),
      ],
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
      bindings: (json['bindings'] as List<dynamic>)
          .map((e) => BindingConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'bindings': bindings.map((e) => e.toJson()).toList(),
      'sourceConnectionId': sourceConnectionId,
      'targetConnectionId': targetConnectionId,
      'idField': idField,
      'ignoredFields': ignoredFields,
    };
  }

  // 获取第一个绑定的源集合（用于向后兼容）
  String get sourceCollection =>
      bindings.isNotEmpty ? bindings.first.sourceCollection : '';

  // 获取第一个绑定的目标集合（用于向后兼容）
  String get targetCollection =>
      bindings.isNotEmpty ? bindings.first.targetCollection : '';

  // 获取第一个绑定的源数据库（用于向后兼容）
  String get sourceDatabaseName =>
      bindings.isNotEmpty ? bindings.first.sourceDatabaseName : '';

  // 获取第一个绑定的目标数据库（用于向后兼容）
  String get targetDatabaseName =>
      bindings.isNotEmpty ? bindings.first.targetDatabaseName : '';
}
