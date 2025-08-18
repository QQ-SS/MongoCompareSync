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
  id: json['id'] as String,
  sourceDocument: json['sourceDocument'] == null
      ? null
      : json['sourceDocument'] as Map<String, dynamic>,
  targetDocument: json['targetDocument'] == null
      ? null
      : json['targetDocument'] as Map<String, dynamic>,
  fieldDiffs: json['fieldDiffs'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$DocumentDiffToJson(DocumentDiff instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourceDocument': instance.sourceDocument,
      'targetDocument': instance.targetDocument,
      'fieldDiffs': instance.fieldDiffs,
    };
