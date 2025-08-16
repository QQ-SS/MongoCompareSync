// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_compare_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CollectionCompareResult _$CollectionCompareResultFromJson(
  Map<String, dynamic> json,
) => CollectionCompareResult(
  sameDocumentsCount: (json['sameDocumentsCount'] as num).toInt(),
  differentDocumentsCount: (json['differentDocumentsCount'] as num).toInt(),
  sourceOnlyIds: (json['sourceOnlyIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  targetOnlyIds: (json['targetOnlyIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  documentResults: (json['documentResults'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, DocumentCompareResult.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$CollectionCompareResultToJson(
  CollectionCompareResult instance,
) => <String, dynamic>{
  'sameDocumentsCount': instance.sameDocumentsCount,
  'differentDocumentsCount': instance.differentDocumentsCount,
  'sourceOnlyIds': instance.sourceOnlyIds,
  'targetOnlyIds': instance.targetOnlyIds,
  'documentResults': instance.documentResults,
};

DocumentCompareResult _$DocumentCompareResultFromJson(
  Map<String, dynamic> json,
) => DocumentCompareResult(
  isIdentical: json['isIdentical'] as bool,
  fieldResults: (json['fieldResults'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, FieldCompareResult.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$DocumentCompareResultToJson(
  DocumentCompareResult instance,
) => <String, dynamic>{
  'isIdentical': instance.isIdentical,
  'fieldResults': instance.fieldResults,
};

FieldCompareResult _$FieldCompareResultFromJson(Map<String, dynamic> json) =>
    FieldCompareResult(
      isIdentical: json['isIdentical'] as bool,
      sourceValue: json['sourceValue'],
      targetValue: json['targetValue'],
    );

Map<String, dynamic> _$FieldCompareResultToJson(FieldCompareResult instance) =>
    <String, dynamic>{
      'isIdentical': instance.isIdentical,
      'sourceValue': instance.sourceValue,
      'targetValue': instance.targetValue,
    };
