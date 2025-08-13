// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compare_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CompareRule _$CompareRuleFromJson(Map<String, dynamic> json) {
  return _CompareRule.fromJson(json);
}

/// @nodoc
mixin _$CompareRule {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  String get description => throw _privateConstructorUsedError;
  @HiveField(3)
  List<FieldRule> get fieldRules => throw _privateConstructorUsedError;

  /// Serializes this CompareRule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompareRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompareRuleCopyWith<CompareRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompareRuleCopyWith<$Res> {
  factory $CompareRuleCopyWith(
          CompareRule value, $Res Function(CompareRule) then) =
      _$CompareRuleCopyWithImpl<$Res, CompareRule>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) String description,
      @HiveField(3) List<FieldRule> fieldRules});
}

/// @nodoc
class _$CompareRuleCopyWithImpl<$Res, $Val extends CompareRule>
    implements $CompareRuleCopyWith<$Res> {
  _$CompareRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompareRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? fieldRules = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      fieldRules: null == fieldRules
          ? _value.fieldRules
          : fieldRules // ignore: cast_nullable_to_non_nullable
              as List<FieldRule>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompareRuleImplCopyWith<$Res>
    implements $CompareRuleCopyWith<$Res> {
  factory _$$CompareRuleImplCopyWith(
          _$CompareRuleImpl value, $Res Function(_$CompareRuleImpl) then) =
      __$$CompareRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) String description,
      @HiveField(3) List<FieldRule> fieldRules});
}

/// @nodoc
class __$$CompareRuleImplCopyWithImpl<$Res>
    extends _$CompareRuleCopyWithImpl<$Res, _$CompareRuleImpl>
    implements _$$CompareRuleImplCopyWith<$Res> {
  __$$CompareRuleImplCopyWithImpl(
      _$CompareRuleImpl _value, $Res Function(_$CompareRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of CompareRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? fieldRules = null,
  }) {
    return _then(_$CompareRuleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      fieldRules: null == fieldRules
          ? _value._fieldRules
          : fieldRules // ignore: cast_nullable_to_non_nullable
              as List<FieldRule>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
@HiveType(typeId: 1)
class _$CompareRuleImpl with DiagnosticableTreeMixin implements _CompareRule {
  const _$CompareRuleImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.name,
      @HiveField(2) required this.description,
      @HiveField(3) final List<FieldRule> fieldRules = const []})
      : _fieldRules = fieldRules;

  factory _$CompareRuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompareRuleImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final String description;
  final List<FieldRule> _fieldRules;
  @override
  @JsonKey()
  @HiveField(3)
  List<FieldRule> get fieldRules {
    if (_fieldRules is EqualUnmodifiableListView) return _fieldRules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fieldRules);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CompareRule(id: $id, name: $name, description: $description, fieldRules: $fieldRules)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CompareRule'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('fieldRules', fieldRules));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompareRuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._fieldRules, _fieldRules));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      const DeepCollectionEquality().hash(_fieldRules));

  /// Create a copy of CompareRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompareRuleImplCopyWith<_$CompareRuleImpl> get copyWith =>
      __$$CompareRuleImplCopyWithImpl<_$CompareRuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompareRuleImplToJson(
      this,
    );
  }
}

abstract class _CompareRule implements CompareRule {
  const factory _CompareRule(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String name,
      @HiveField(2) required final String description,
      @HiveField(3) final List<FieldRule> fieldRules}) = _$CompareRuleImpl;

  factory _CompareRule.fromJson(Map<String, dynamic> json) =
      _$CompareRuleImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get name;
  @override
  @HiveField(2)
  String get description;
  @override
  @HiveField(3)
  List<FieldRule> get fieldRules;

  /// Create a copy of CompareRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompareRuleImplCopyWith<_$CompareRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FieldRule _$FieldRuleFromJson(Map<String, dynamic> json) {
  return _FieldRule.fromJson(json);
}

/// @nodoc
mixin _$FieldRule {
  @HiveField(0)
  String get fieldPath => throw _privateConstructorUsedError;
  @HiveField(1)
  RuleType get ruleType => throw _privateConstructorUsedError;
  @HiveField(2)
  String? get pattern => throw _privateConstructorUsedError;
  @HiveField(3)
  String? get transformFunction => throw _privateConstructorUsedError;
  @HiveField(4)
  bool get isRegex => throw _privateConstructorUsedError;

  /// Serializes this FieldRule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FieldRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FieldRuleCopyWith<FieldRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FieldRuleCopyWith<$Res> {
  factory $FieldRuleCopyWith(FieldRule value, $Res Function(FieldRule) then) =
      _$FieldRuleCopyWithImpl<$Res, FieldRule>;
  @useResult
  $Res call(
      {@HiveField(0) String fieldPath,
      @HiveField(1) RuleType ruleType,
      @HiveField(2) String? pattern,
      @HiveField(3) String? transformFunction,
      @HiveField(4) bool isRegex});
}

/// @nodoc
class _$FieldRuleCopyWithImpl<$Res, $Val extends FieldRule>
    implements $FieldRuleCopyWith<$Res> {
  _$FieldRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FieldRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fieldPath = null,
    Object? ruleType = null,
    Object? pattern = freezed,
    Object? transformFunction = freezed,
    Object? isRegex = null,
  }) {
    return _then(_value.copyWith(
      fieldPath: null == fieldPath
          ? _value.fieldPath
          : fieldPath // ignore: cast_nullable_to_non_nullable
              as String,
      ruleType: null == ruleType
          ? _value.ruleType
          : ruleType // ignore: cast_nullable_to_non_nullable
              as RuleType,
      pattern: freezed == pattern
          ? _value.pattern
          : pattern // ignore: cast_nullable_to_non_nullable
              as String?,
      transformFunction: freezed == transformFunction
          ? _value.transformFunction
          : transformFunction // ignore: cast_nullable_to_non_nullable
              as String?,
      isRegex: null == isRegex
          ? _value.isRegex
          : isRegex // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FieldRuleImplCopyWith<$Res>
    implements $FieldRuleCopyWith<$Res> {
  factory _$$FieldRuleImplCopyWith(
          _$FieldRuleImpl value, $Res Function(_$FieldRuleImpl) then) =
      __$$FieldRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String fieldPath,
      @HiveField(1) RuleType ruleType,
      @HiveField(2) String? pattern,
      @HiveField(3) String? transformFunction,
      @HiveField(4) bool isRegex});
}

/// @nodoc
class __$$FieldRuleImplCopyWithImpl<$Res>
    extends _$FieldRuleCopyWithImpl<$Res, _$FieldRuleImpl>
    implements _$$FieldRuleImplCopyWith<$Res> {
  __$$FieldRuleImplCopyWithImpl(
      _$FieldRuleImpl _value, $Res Function(_$FieldRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of FieldRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fieldPath = null,
    Object? ruleType = null,
    Object? pattern = freezed,
    Object? transformFunction = freezed,
    Object? isRegex = null,
  }) {
    return _then(_$FieldRuleImpl(
      fieldPath: null == fieldPath
          ? _value.fieldPath
          : fieldPath // ignore: cast_nullable_to_non_nullable
              as String,
      ruleType: null == ruleType
          ? _value.ruleType
          : ruleType // ignore: cast_nullable_to_non_nullable
              as RuleType,
      pattern: freezed == pattern
          ? _value.pattern
          : pattern // ignore: cast_nullable_to_non_nullable
              as String?,
      transformFunction: freezed == transformFunction
          ? _value.transformFunction
          : transformFunction // ignore: cast_nullable_to_non_nullable
              as String?,
      isRegex: null == isRegex
          ? _value.isRegex
          : isRegex // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
@HiveType(typeId: 2)
class _$FieldRuleImpl with DiagnosticableTreeMixin implements _FieldRule {
  const _$FieldRuleImpl(
      {@HiveField(0) required this.fieldPath,
      @HiveField(1) required this.ruleType,
      @HiveField(2) this.pattern,
      @HiveField(3) this.transformFunction,
      @HiveField(4) this.isRegex = false});

  factory _$FieldRuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$FieldRuleImplFromJson(json);

  @override
  @HiveField(0)
  final String fieldPath;
  @override
  @HiveField(1)
  final RuleType ruleType;
  @override
  @HiveField(2)
  final String? pattern;
  @override
  @HiveField(3)
  final String? transformFunction;
  @override
  @JsonKey()
  @HiveField(4)
  final bool isRegex;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FieldRule(fieldPath: $fieldPath, ruleType: $ruleType, pattern: $pattern, transformFunction: $transformFunction, isRegex: $isRegex)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'FieldRule'))
      ..add(DiagnosticsProperty('fieldPath', fieldPath))
      ..add(DiagnosticsProperty('ruleType', ruleType))
      ..add(DiagnosticsProperty('pattern', pattern))
      ..add(DiagnosticsProperty('transformFunction', transformFunction))
      ..add(DiagnosticsProperty('isRegex', isRegex));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FieldRuleImpl &&
            (identical(other.fieldPath, fieldPath) ||
                other.fieldPath == fieldPath) &&
            (identical(other.ruleType, ruleType) ||
                other.ruleType == ruleType) &&
            (identical(other.pattern, pattern) || other.pattern == pattern) &&
            (identical(other.transformFunction, transformFunction) ||
                other.transformFunction == transformFunction) &&
            (identical(other.isRegex, isRegex) || other.isRegex == isRegex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, fieldPath, ruleType, pattern, transformFunction, isRegex);

  /// Create a copy of FieldRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FieldRuleImplCopyWith<_$FieldRuleImpl> get copyWith =>
      __$$FieldRuleImplCopyWithImpl<_$FieldRuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FieldRuleImplToJson(
      this,
    );
  }
}

abstract class _FieldRule implements FieldRule {
  const factory _FieldRule(
      {@HiveField(0) required final String fieldPath,
      @HiveField(1) required final RuleType ruleType,
      @HiveField(2) final String? pattern,
      @HiveField(3) final String? transformFunction,
      @HiveField(4) final bool isRegex}) = _$FieldRuleImpl;

  factory _FieldRule.fromJson(Map<String, dynamic> json) =
      _$FieldRuleImpl.fromJson;

  @override
  @HiveField(0)
  String get fieldPath;
  @override
  @HiveField(1)
  RuleType get ruleType;
  @override
  @HiveField(2)
  String? get pattern;
  @override
  @HiveField(3)
  String? get transformFunction;
  @override
  @HiveField(4)
  bool get isRegex;

  /// Create a copy of FieldRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FieldRuleImplCopyWith<_$FieldRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
