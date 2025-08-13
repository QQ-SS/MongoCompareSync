// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MongoCollection _$MongoCollectionFromJson(Map<String, dynamic> json) {
  return _MongoCollection.fromJson(json);
}

/// @nodoc
mixin _$MongoCollection {
  String get name => throw _privateConstructorUsedError;
  String get database => throw _privateConstructorUsedError;
  String get connectionId => throw _privateConstructorUsedError;
  int get documentCount => throw _privateConstructorUsedError;
  List<String> get indexes => throw _privateConstructorUsedError;

  /// Serializes this MongoCollection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MongoCollection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MongoCollectionCopyWith<MongoCollection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MongoCollectionCopyWith<$Res> {
  factory $MongoCollectionCopyWith(
          MongoCollection value, $Res Function(MongoCollection) then) =
      _$MongoCollectionCopyWithImpl<$Res, MongoCollection>;
  @useResult
  $Res call(
      {String name,
      String database,
      String connectionId,
      int documentCount,
      List<String> indexes});
}

/// @nodoc
class _$MongoCollectionCopyWithImpl<$Res, $Val extends MongoCollection>
    implements $MongoCollectionCopyWith<$Res> {
  _$MongoCollectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MongoCollection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? database = null,
    Object? connectionId = null,
    Object? documentCount = null,
    Object? indexes = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      database: null == database
          ? _value.database
          : database // ignore: cast_nullable_to_non_nullable
              as String,
      connectionId: null == connectionId
          ? _value.connectionId
          : connectionId // ignore: cast_nullable_to_non_nullable
              as String,
      documentCount: null == documentCount
          ? _value.documentCount
          : documentCount // ignore: cast_nullable_to_non_nullable
              as int,
      indexes: null == indexes
          ? _value.indexes
          : indexes // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MongoCollectionImplCopyWith<$Res>
    implements $MongoCollectionCopyWith<$Res> {
  factory _$$MongoCollectionImplCopyWith(_$MongoCollectionImpl value,
          $Res Function(_$MongoCollectionImpl) then) =
      __$$MongoCollectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String database,
      String connectionId,
      int documentCount,
      List<String> indexes});
}

/// @nodoc
class __$$MongoCollectionImplCopyWithImpl<$Res>
    extends _$MongoCollectionCopyWithImpl<$Res, _$MongoCollectionImpl>
    implements _$$MongoCollectionImplCopyWith<$Res> {
  __$$MongoCollectionImplCopyWithImpl(
      _$MongoCollectionImpl _value, $Res Function(_$MongoCollectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of MongoCollection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? database = null,
    Object? connectionId = null,
    Object? documentCount = null,
    Object? indexes = null,
  }) {
    return _then(_$MongoCollectionImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      database: null == database
          ? _value.database
          : database // ignore: cast_nullable_to_non_nullable
              as String,
      connectionId: null == connectionId
          ? _value.connectionId
          : connectionId // ignore: cast_nullable_to_non_nullable
              as String,
      documentCount: null == documentCount
          ? _value.documentCount
          : documentCount // ignore: cast_nullable_to_non_nullable
              as int,
      indexes: null == indexes
          ? _value._indexes
          : indexes // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MongoCollectionImpl
    with DiagnosticableTreeMixin
    implements _MongoCollection {
  const _$MongoCollectionImpl(
      {required this.name,
      required this.database,
      required this.connectionId,
      this.documentCount = 0,
      final List<String> indexes = const []})
      : _indexes = indexes;

  factory _$MongoCollectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MongoCollectionImplFromJson(json);

  @override
  final String name;
  @override
  final String database;
  @override
  final String connectionId;
  @override
  @JsonKey()
  final int documentCount;
  final List<String> _indexes;
  @override
  @JsonKey()
  List<String> get indexes {
    if (_indexes is EqualUnmodifiableListView) return _indexes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_indexes);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MongoCollection(name: $name, database: $database, connectionId: $connectionId, documentCount: $documentCount, indexes: $indexes)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'MongoCollection'))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('database', database))
      ..add(DiagnosticsProperty('connectionId', connectionId))
      ..add(DiagnosticsProperty('documentCount', documentCount))
      ..add(DiagnosticsProperty('indexes', indexes));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MongoCollectionImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.database, database) ||
                other.database == database) &&
            (identical(other.connectionId, connectionId) ||
                other.connectionId == connectionId) &&
            (identical(other.documentCount, documentCount) ||
                other.documentCount == documentCount) &&
            const DeepCollectionEquality().equals(other._indexes, _indexes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, database, connectionId,
      documentCount, const DeepCollectionEquality().hash(_indexes));

  /// Create a copy of MongoCollection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MongoCollectionImplCopyWith<_$MongoCollectionImpl> get copyWith =>
      __$$MongoCollectionImplCopyWithImpl<_$MongoCollectionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MongoCollectionImplToJson(
      this,
    );
  }
}

abstract class _MongoCollection implements MongoCollection {
  const factory _MongoCollection(
      {required final String name,
      required final String database,
      required final String connectionId,
      final int documentCount,
      final List<String> indexes}) = _$MongoCollectionImpl;

  factory _MongoCollection.fromJson(Map<String, dynamic> json) =
      _$MongoCollectionImpl.fromJson;

  @override
  String get name;
  @override
  String get database;
  @override
  String get connectionId;
  @override
  int get documentCount;
  @override
  List<String> get indexes;

  /// Create a copy of MongoCollection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MongoCollectionImplCopyWith<_$MongoCollectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
