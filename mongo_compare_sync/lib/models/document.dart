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
