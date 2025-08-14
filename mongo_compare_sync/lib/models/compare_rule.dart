import 'package:json_annotation/json_annotation.dart';

part 'compare_rule.g.dart';

@JsonEnum()
enum RuleType {
  ignore, // 忽略字段
  transform, // 转换字段值后比较
  custom, // 自定义比较逻辑
}

@JsonSerializable()
class CompareRule {
  final String id;
  final String name;
  final String description;
  final List<FieldRule> fieldRules;

  CompareRule({
    required this.id,
    required this.name,
    required this.description,
    this.fieldRules = const [],
  });

  factory CompareRule.fromJson(Map<String, dynamic> json) =>
      _$CompareRuleFromJson(json);

  Map<String, dynamic> toJson() => _$CompareRuleToJson(this);

  CompareRule copyWith({
    String? id,
    String? name,
    String? description,
    List<FieldRule>? fieldRules,
  }) {
    return CompareRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      fieldRules: fieldRules ?? this.fieldRules,
    );
  }
}

@JsonSerializable()
class FieldRule {
  final String fieldPath;
  final RuleType ruleType;
  final String? pattern;
  final String? transformFunction;
  final bool isRegex;

  FieldRule({
    required this.fieldPath,
    required this.ruleType,
    this.pattern,
    this.transformFunction,
    this.isRegex = false,
  });

  factory FieldRule.fromJson(Map<String, dynamic> json) =>
      _$FieldRuleFromJson(json);

  Map<String, dynamic> toJson() => _$FieldRuleToJson(this);

  FieldRule copyWith({
    String? fieldPath,
    RuleType? ruleType,
    String? pattern,
    String? transformFunction,
    bool? isRegex,
  }) {
    return FieldRule(
      fieldPath: fieldPath ?? this.fieldPath,
      ruleType: ruleType ?? this.ruleType,
      pattern: pattern ?? this.pattern,
      transformFunction: transformFunction ?? this.transformFunction,
      isRegex: isRegex ?? this.isRegex,
    );
  }
}
