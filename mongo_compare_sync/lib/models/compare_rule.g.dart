// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compare_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompareRuleImplAdapter extends TypeAdapter<_$CompareRuleImpl> {
  @override
  final int typeId = 1;

  @override
  _$CompareRuleImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$CompareRuleImpl(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      fieldRules: (fields[3] as List).cast<FieldRule>(),
    );
  }

  @override
  void write(BinaryWriter writer, _$CompareRuleImpl obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.fieldRules);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompareRuleImplAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FieldRuleImplAdapter extends TypeAdapter<_$FieldRuleImpl> {
  @override
  final int typeId = 2;

  @override
  _$FieldRuleImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$FieldRuleImpl(
      fieldPath: fields[0] as String,
      ruleType: fields[1] as RuleType,
      pattern: fields[2] as String?,
      transformFunction: fields[3] as String?,
      isRegex: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, _$FieldRuleImpl obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.fieldPath)
      ..writeByte(1)
      ..write(obj.ruleType)
      ..writeByte(2)
      ..write(obj.pattern)
      ..writeByte(3)
      ..write(obj.transformFunction)
      ..writeByte(4)
      ..write(obj.isRegex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldRuleImplAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompareRuleImpl _$$CompareRuleImplFromJson(Map<String, dynamic> json) =>
    _$CompareRuleImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      fieldRules: (json['fieldRules'] as List<dynamic>?)
              ?.map((e) => FieldRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CompareRuleImplToJson(_$CompareRuleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'fieldRules': instance.fieldRules,
    };

_$FieldRuleImpl _$$FieldRuleImplFromJson(Map<String, dynamic> json) =>
    _$FieldRuleImpl(
      fieldPath: json['fieldPath'] as String,
      ruleType: $enumDecode(_$RuleTypeEnumMap, json['ruleType']),
      pattern: json['pattern'] as String?,
      transformFunction: json['transformFunction'] as String?,
      isRegex: json['isRegex'] as bool? ?? false,
    );

Map<String, dynamic> _$$FieldRuleImplToJson(_$FieldRuleImpl instance) =>
    <String, dynamic>{
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
