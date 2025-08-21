// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MongoCollection _$MongoCollectionFromJson(Map<String, dynamic> json) =>
    MongoCollection(
      name: json['name'] as String,
      database: json['database'] as String,
      connectionId: json['connectionId'] as String,
      documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
      indexes:
          (json['indexes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MongoCollectionToJson(MongoCollection instance) =>
    <String, dynamic>{
      'name': instance.name,
      'database': instance.database,
      'connectionId': instance.connectionId,
      'documentCount': instance.documentCount,
      'indexes': instance.indexes,
    };
