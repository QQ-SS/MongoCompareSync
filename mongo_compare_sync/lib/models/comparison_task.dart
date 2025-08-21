class BindingConfig {
  final String id;
  final String sourceCollection;
  final String targetCollection;
  final String sourceDatabaseName;
  final String targetDatabaseName;
  final String? idField;
  final List<String> ignoredFields;

  BindingConfig({
    required this.id,
    required this.sourceCollection,
    required this.targetCollection,
    required this.sourceDatabaseName,
    required this.targetDatabaseName,
    this.idField = '_id',
    this.ignoredFields = const [],
  });

  // 从JSON反序列化
  factory BindingConfig.fromJson(Map<String, dynamic> json) {
    return BindingConfig(
      id: json['id'] as String,
      sourceCollection: json['sourceCollection'] as String,
      targetCollection: json['targetCollection'] as String,
      sourceDatabaseName: json['sourceDatabaseName'] as String,
      targetDatabaseName: json['targetDatabaseName'] as String,
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
      'id': id,
      'sourceCollection': sourceCollection,
      'targetCollection': targetCollection,
      'sourceDatabaseName': sourceDatabaseName,
      'targetDatabaseName': targetDatabaseName,
      'idField': idField,
      'ignoredFields': ignoredFields,
    };
  }
}

class ComparisonTask {
  final String name;
  final List<BindingConfig> bindings;
  final String? sourceConnectionId;
  final String? targetConnectionId;

  ComparisonTask({
    required this.name,
    required this.bindings,
    this.sourceConnectionId,
    this.targetConnectionId,
  });

  // 从JSON反序列化
  factory ComparisonTask.fromJson(Map<String, dynamic> json) {
    return ComparisonTask(
      name: json['name'] as String,
      bindings: (json['bindings'] as List<dynamic>)
          .map((e) => BindingConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      sourceConnectionId: json['sourceConnectionId'] as String?,
      targetConnectionId: json['targetConnectionId'] as String?,
    );
  }

  // 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bindings': bindings.map((e) => e.toJson()).toList(),
      'sourceConnectionId': sourceConnectionId,
      'targetConnectionId': targetConnectionId,
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
