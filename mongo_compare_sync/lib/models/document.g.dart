// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MongoDocumentImpl _$$MongoDocumentImplFromJson(Map<String, dynamic> json) =>
    _$MongoDocumentImpl(
      id: json['id'] as String,
      data: json['data'] as Map<String, dynamic>,
      collectionName: json['collectionName'] as String,
      databaseName: json['databaseName'] as String,
      connectionId: json['connectionId'] as String,
    );

Map<String, dynamic> _$$MongoDocumentImplToJson(_$MongoDocumentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'data': instance.data,
      'collectionName': instance.collectionName,
      'databaseName': instance.databaseName,
      'connectionId': instance.connectionId,
    };

_$DocumentDiffImpl _$$DocumentDiffImplFromJson(Map<String, dynamic> json) =>
    _$DocumentDiffImpl(
      sourceDocument: MongoDocument.fromJson(
          json['sourceDocument'] as Map<String, dynamic>),
      targetDocument: json['targetDocument'] == null
          ? null
          : MongoDocument.fromJson(
              json['targetDocument'] as Map<String, dynamic>),
      diffType: $enumDecode(_$DocumentDiffTypeEnumMap, json['diffType']),
      fieldDiffs: json['fieldDiffs'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$DocumentDiffImplToJson(_$DocumentDiffImpl instance) =>
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
