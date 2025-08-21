import 'package:json_annotation/json_annotation.dart';

part 'collection_compare_result.g.dart';

@JsonSerializable()
class CollectionCompareResult {
  final int sameDocumentsCount; // 相同文档数量
  final int differentDocumentsCount; // 不同文档数量
  final List<String> sourceOnlyIds; // 只在源集合中存在的文档ID
  final List<String> targetOnlyIds; // 只在目标集合中存在的文档ID
  final Map<String, DocumentCompareResult> documentResults; // 文档比较结果，键为文档ID

  CollectionCompareResult({
    required this.sameDocumentsCount,
    required this.differentDocumentsCount,
    required this.sourceOnlyIds,
    required this.targetOnlyIds,
    required this.documentResults,
  });

  // 获取总文档数
  int get totalDocumentsCount =>
      sameDocumentsCount +
      differentDocumentsCount +
      sourceOnlyIds.length +
      targetOnlyIds.length;

  // 获取匹配率
  double get matchRate =>
      totalDocumentsCount > 0 ? sameDocumentsCount / totalDocumentsCount : 0.0;

  // 获取摘要信息
  String get summary {
    final sb = StringBuffer();
    sb.write('总文档数: $totalDocumentsCount, ');
    sb.write('相同: $sameDocumentsCount, ');
    sb.write('不同: $differentDocumentsCount, ');
    sb.write('仅源集合: ${sourceOnlyIds.length}, ');
    sb.write('仅目标集合: ${targetOnlyIds.length}');
    return sb.toString();
  }

  factory CollectionCompareResult.fromJson(Map<String, dynamic> json) =>
      _$CollectionCompareResultFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionCompareResultToJson(this);
}

@JsonSerializable()
class DocumentCompareResult {
  final bool isIdentical; // 文档是否完全相同
  final Map<String, FieldCompareResult> fieldResults; // 字段比较结果，键为字段路径

  DocumentCompareResult({
    required this.isIdentical,
    required this.fieldResults,
  });

  // 获取不同字段数量
  int get differentFieldsCount =>
      fieldResults.values.where((field) => !field.isIdentical).length;

  factory DocumentCompareResult.fromJson(Map<String, dynamic> json) =>
      _$DocumentCompareResultFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentCompareResultToJson(this);
}

@JsonSerializable()
class FieldCompareResult {
  final bool isIdentical; // 字段是否相同
  final dynamic sourceValue; // 源文档中的值
  final dynamic targetValue; // 目标文档中的值

  FieldCompareResult({
    required this.isIdentical,
    this.sourceValue,
    this.targetValue,
  });

  factory FieldCompareResult.fromJson(Map<String, dynamic> json) =>
      _$FieldCompareResultFromJson(json);

  Map<String, dynamic> toJson() => _$FieldCompareResultToJson(this);
}

// 比较配置类
class CompareConfig {
  final String idField; // 用于匹配文档的字段，默认为 "_id"
  final List<String> ignoreFields; // 忽略比较的字段列表
  final bool caseSensitive; // 是否区分大小写

  CompareConfig({
    this.idField = '_id',
    this.ignoreFields = const [],
    this.caseSensitive = true,
  });
}
