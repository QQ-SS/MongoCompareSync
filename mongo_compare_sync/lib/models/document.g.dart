// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MongoDocument _$MongoDocumentFromJson(Map<String, dynamic> json) =>
    MongoDocument(
      id: json['id'] as String,
      data: json['data'] as Map<String, dynamic>,
      collectionName: json['collectionName'] as String,
      databaseName: json['databaseName'] as String,
      connectionId: json['connectionId'] as String,
    );

Map<String, dynamic> _$MongoDocumentToJson(MongoDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'data': instance.data,
      'collectionName': instance.collectionName,
      'databaseName': instance.databaseName,
      'connectionId': instance.connectionId,
    };

DocumentDiff _$DocumentDiffFromJson(Map<String, dynamic> json) => DocumentDiff(
      sourceDocument: MongoDocument.fromJson(
          json['sourceDocument'] as Map<String, dynamic>),
      targetDocument: json['targetDocument'] == null
          ? null
          : MongoDocument.fromJson(
              json['targetDocument'] as Map<String, dynamic>),
      diffType: $enumDecode(_$DocumentDiffTypeEnumMap, json['diffType']),
      fieldDiffs: json['fieldDiffs'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DocumentDiffToJson(DocumentDiff instance) =>
    <String, dynamic>{
      'sourceDocument': instance.sourceDocument,
      'targetDocument': instance.targetDocument,
      'diffType': _$DocumentDiffTypeEnumMap[instance.diffType]!,
      'fieldDiffs': instance.fieldDiffs,
    };

const _$DocumentDiffTypeEnumMap = {
  DocumentDiffType.added: 'added',
  DocumentDiffType.removed: 'removed',
  DocumentDiffType.modified: 'modified',
  DocumentDiffType.unchanged: 'unchanged',
};
