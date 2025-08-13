import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'document.freezed.dart';
part 'document.g.dart';

@freezed
class MongoDocument with _$MongoDocument {
  const factory MongoDocument({
    required String id,
    required Map<String, dynamic> data,
    required String collectionName,
    required String databaseName,
    required String connectionId,
  }) = _MongoDocument;

  factory MongoDocument.fromJson(Map<String, dynamic> json) =>
      _$MongoDocumentFromJson(json);
}

enum DocumentDiffType { added, removed, modified, unchanged }

@freezed
class DocumentDiff with _$DocumentDiff {
  const factory DocumentDiff({
    required MongoDocument sourceDocument,
    MongoDocument? targetDocument,
    required DocumentDiffType diffType,
    Map<String, dynamic>? fieldDiffs,
  }) = _DocumentDiff;

  factory DocumentDiff.fromJson(Map<String, dynamic> json) =>
      _$DocumentDiffFromJson(json);
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
