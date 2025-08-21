import 'package:json_annotation/json_annotation.dart';

part 'document.g.dart';

@JsonSerializable()
class MongoDocument {
  final String id;
  final Map<String, dynamic> data;
  final String collectionName;
  final String databaseName;
  final String connectionId;

  MongoDocument({
    required this.id,
    required this.data,
    required this.collectionName,
    required this.databaseName,
    required this.connectionId,
  });

  factory MongoDocument.fromJson(Map<String, dynamic> json) =>
      _$MongoDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$MongoDocumentToJson(this);

  MongoDocument copyWith({
    String? id,
    Map<String, dynamic>? data,
    String? collectionName,
    String? databaseName,
    String? connectionId,
  }) {
    return MongoDocument(
      id: id ?? this.id,
      data: data ?? this.data,
      collectionName: collectionName ?? this.collectionName,
      databaseName: databaseName ?? this.databaseName,
      connectionId: connectionId ?? this.connectionId,
    );
  }
}

@JsonEnum()
enum DocumentDiffType { added, removed, modified, unchanged }

@JsonSerializable()
class DocumentDiff {
  final String id;
  final Map<String, dynamic>? sourceDocument;
  final Map<String, dynamic>? targetDocument;
  final List<String>? fieldDiffs;

  DocumentDiff({
    required this.id,
    this.sourceDocument,
    this.targetDocument,
    this.fieldDiffs,
  });

  factory DocumentDiff.fromJson(Map<String, dynamic> json) =>
      _$DocumentDiffFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentDiffToJson(this);

  DocumentDiff copyWith({
    String? id,
    Map<String, dynamic>? sourceDocument,
    Map<String, dynamic>? targetDocument,
    List<String>? fieldDiffs,
  }) {
    return DocumentDiff(
      id: id ?? this.id,
      sourceDocument: sourceDocument ?? this.sourceDocument,
      targetDocument: targetDocument ?? this.targetDocument,
      fieldDiffs: fieldDiffs ?? this.fieldDiffs,
    );
  }
}

// 字段差异模型 - 使用普通类而不是freezed
class FieldDiff {
  final String fieldPath;
  final dynamic sourceValue;
  final dynamic targetValue;
  final String? status; // 'added', 'removed', 'modified'

  FieldDiff({
    required this.fieldPath,
    this.sourceValue,
    this.targetValue,
    required this.status,
  });

  // 从Map创建FieldDiff实例
  factory FieldDiff.fromMap(String path, Map<String, dynamic> map) {
    return FieldDiff(
      fieldPath: path,
      sourceValue: map['source'],
      targetValue: map['target'],
      status: map['status'] as String?,
    );
  }

  // 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'fieldPath': fieldPath,
      'sourceValue': sourceValue,
      'targetValue': targetValue,
      'status': status,
    };
  }
}
