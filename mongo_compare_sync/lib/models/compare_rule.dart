import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'compare_rule.freezed.dart';
part 'compare_rule.g.dart';

enum RuleType {
  ignore, // 忽略字段
  transform, // 转换字段值后比较
  custom, // 自定义比较逻辑
}

@freezed
class CompareRule with _$CompareRule {
  @HiveType(typeId: 1)
  const factory CompareRule({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required String description,
    @HiveField(3) @Default([]) List<FieldRule> fieldRules,
  }) = _CompareRule;

  factory CompareRule.fromJson(Map<String, dynamic> json) =>
      _$CompareRuleFromJson(json);
}

@freezed
class FieldRule with _$FieldRule {
  @HiveType(typeId: 2)
  const factory FieldRule({
    @HiveField(0) required String fieldPath,
    @HiveField(1) required RuleType ruleType,
    @HiveField(2) String? pattern,
    @HiveField(3) String? transformFunction,
    @HiveField(4) @Default(false) bool isRegex,
  }) = _FieldRule;

  factory FieldRule.fromJson(Map<String, dynamic> json) =>
      _$FieldRuleFromJson(json);
}
