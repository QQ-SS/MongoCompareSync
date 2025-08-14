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
  final MongoDocument sourceDocument;
  final MongoDocument? targetDocument;
  final DocumentDiffType diffType;
  final Map<String, dynamic>? fieldDiffs;

  DocumentDiff({
    required this.sourceDocument,
    this.targetDocument,
    required this.diffType,
    this.fieldDiffs,
  });

  factory DocumentDiff.fromJson(Map<String, dynamic> json) =>
      _$DocumentDiffFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentDiffToJson(this);

  DocumentDiff copyWith({
    MongoDocument? sourceDocument,
    MongoDocument? targetDocument,
    DocumentDiffType? diffType,
    Map<String, dynamic>? fieldDiffs,
  }) {
    return DocumentDiff(
      sourceDocument: sourceDocument ?? this.sourceDocument,
      targetDocument: targetDocument ?? this.targetDocument,
      diffType: diffType ?? this.diffType,
      fieldDiffs: fieldDiffs ?? this.fieldDiffs,
    );
  }
}

// 字段差异模型 - 使用普通类而不是freezed
class FieldDiff {
  final String fieldPath;
  final dynamic sourceValue;
  final dynamic targetValue;
  final String status; // 'added', 'removed', 'modified'

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
      status: map['status'] as String,
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

extension DocumentDiffExtension on DocumentDiff {
  String get id => sourceDocument.id;

  String get status {
    switch (diffType) {
      case DocumentDiffType.added:
        return 'added';
      case DocumentDiffType.removed:
        return 'removed';
      case DocumentDiffType.modified:
        return 'modified';
      case DocumentDiffType.unchanged:
        return 'unchanged';
      default:
        return 'unknown';
    }
  }

  // 获取字段差异列表
  List<FieldDiff> get fieldDiffList {
    final List<FieldDiff> result = [];

    if (fieldDiffs != null) {
      fieldDiffs!.forEach((path, diff) {
        if (diff is Map<String, dynamic>) {
          result.add(FieldDiff.fromMap(path, diff));
        }
      });
    }

    return result;
  }
}
