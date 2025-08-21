// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compare_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompareRule _$CompareRuleFromJson(Map<String, dynamic> json) => CompareRule(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  fieldRules:
      (json['fieldRules'] as List<dynamic>?)
          ?.map((e) => FieldRule.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$CompareRuleToJson(CompareRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'fieldRules': instance.fieldRules,
    };

FieldRule _$FieldRuleFromJson(Map<String, dynamic> json) => FieldRule(
  fieldPath: json['fieldPath'] as String,
  ruleType: $enumDecode(_$RuleTypeEnumMap, json['ruleType']),
  pattern: json['pattern'] as String?,
  transformFunction: json['transformFunction'] as String?,
  isRegex: json['isRegex'] as bool? ?? false,
);

Map<String, dynamic> _$FieldRuleToJson(FieldRule instance) => <String, dynamic>{
  'fieldPath': instance.fieldPath,
  'ruleType': _$RuleTypeEnumMap[instance.ruleType]!,
  'pattern': instance.pattern,
  'transformFunction': instance.transformFunction,
  'isRegex': instance.isRegex,
};

const _$RuleTypeEnumMap = {
  RuleType.ignore: 'ignore',
  RuleType.transform: 'transform',
  RuleType.custom: 'custom',
};
