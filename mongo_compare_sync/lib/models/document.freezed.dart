// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MongoDocument _$MongoDocumentFromJson(Map<String, dynamic> json) {
  return _MongoDocument.fromJson(json);
}

/// @nodoc
mixin _$MongoDocument {
  String get id => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  String get collectionName => throw _privateConstructorUsedError;
  String get databaseName => throw _privateConstructorUsedError;
  String get connectionId => throw _privateConstructorUsedError;

  /// Serializes this MongoDocument to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MongoDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MongoDocumentCopyWith<MongoDocument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MongoDocumentCopyWith<$Res> {
  factory $MongoDocumentCopyWith(
          MongoDocument value, $Res Function(MongoDocument) then) =
      _$MongoDocumentCopyWithImpl<$Res, MongoDocument>;
  @useResult
  $Res call(
      {String id,
      Map<String, dynamic> data,
      String collectionName,
      String databaseName,
      String connectionId});
}

/// @nodoc
class _$MongoDocumentCopyWithImpl<$Res, $Val extends MongoDocument>
    implements $MongoDocumentCopyWith<$Res> {
  _$MongoDocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MongoDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? data = null,
    Object? collectionName = null,
    Object? databaseName = null,
    Object? connectionId = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      collectionName: null == collectionName
          ? _value.collectionName
          : collectionName // ignore: cast_nullable_to_non_nullable
              as String,
      databaseName: null == databaseName
          ? _value.databaseName
          : databaseName // ignore: cast_nullable_to_non_nullable
              as String,
      connectionId: null == connectionId
          ? _value.connectionId
          : connectionId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MongoDocumentImplCopyWith<$Res>
    implements $MongoDocumentCopyWith<$Res> {
  factory _$$MongoDocumentImplCopyWith(
          _$MongoDocumentImpl value, $Res Function(_$MongoDocumentImpl) then) =
      __$$MongoDocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      Map<String, dynamic> data,
      String collectionName,
      String databaseName,
      String connectionId});
}

/// @nodoc
class __$$MongoDocumentImplCopyWithImpl<$Res>
    extends _$MongoDocumentCopyWithImpl<$Res, _$MongoDocumentImpl>
    implements _$$MongoDocumentImplCopyWith<$Res> {
  __$$MongoDocumentImplCopyWithImpl(
      _$MongoDocumentImpl _value, $Res Function(_$MongoDocumentImpl) _then)
      : super(_value, _then);

  /// Create a copy of MongoDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? data = null,
    Object? collectionName = null,
    Object? databaseName = null,
    Object? connectionId = null,
  }) {
    return _then(_$MongoDocumentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      collectionName: null == collectionName
          ? _value.collectionName
          : collectionName // ignore: cast_nullable_to_non_nullable
              as String,
      databaseName: null == databaseName
          ? _value.databaseName
          : databaseName // ignore: cast_nullable_to_non_nullable
              as String,
      connectionId: null == connectionId
          ? _value.connectionId
          : connectionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MongoDocumentImpl
    with DiagnosticableTreeMixin
    implements _MongoDocument {
  const _$MongoDocumentImpl(
      {required this.id,
      required final Map<String, dynamic> data,
      required this.collectionName,
      required this.databaseName,
      required this.connectionId})
      : _data = data;

  factory _$MongoDocumentImpl.fromJson(Map<String, dynamic> json) =>
      _$$MongoDocumentImplFromJson(json);

  @override
  final String id;
  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  final String collectionName;
  @override
  final String databaseName;
  @override
  final String connectionId;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MongoDocument(id: $id, data: $data, collectionName: $collectionName, databaseName: $databaseName, connectionId: $connectionId)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'MongoDocument'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('data', data))
      ..add(DiagnosticsProperty('collectionName', collectionName))
      ..add(DiagnosticsProperty('databaseName', databaseName))
      ..add(DiagnosticsProperty('connectionId', connectionId));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MongoDocumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.collectionName, collectionName) ||
                other.collectionName == collectionName) &&
            (identical(other.databaseName, databaseName) ||
                other.databaseName == databaseName) &&
            (identical(other.connectionId, connectionId) ||
                other.connectionId == connectionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_data),
      collectionName,
      databaseName,
      connectionId);

  /// Create a copy of MongoDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MongoDocumentImplCopyWith<_$MongoDocumentImpl> get copyWith =>
      __$$MongoDocumentImplCopyWithImpl<_$MongoDocumentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MongoDocumentImplToJson(
      this,
    );
  }
}

abstract class _MongoDocument implements MongoDocument {
  const factory _MongoDocument(
      {required final String id,
      required final Map<String, dynamic> data,
      required final String collectionName,
      required final String databaseName,
      required final String connectionId}) = _$MongoDocumentImpl;

  factory _MongoDocument.fromJson(Map<String, dynamic> json) =
      _$MongoDocumentImpl.fromJson;

  @override
  String get id;
  @override
  Map<String, dynamic> get data;
  @override
  String get collectionName;
  @override
  String get databaseName;
  @override
  String get connectionId;

  /// Create a copy of MongoDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MongoDocumentImplCopyWith<_$MongoDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DocumentDiff _$DocumentDiffFromJson(Map<String, dynamic> json) {
  return _DocumentDiff.fromJson(json);
}

/// @nodoc
mixin _$DocumentDiff {
  MongoDocument get sourceDocument => throw _privateConstructorUsedError;
  MongoDocument? get targetDocument => throw _privateConstructorUsedError;
  DocumentDiffType get diffType => throw _privateConstructorUsedError;
  Map<String, dynamic>? get fieldDiffs => throw _privateConstructorUsedError;

  /// Serializes this DocumentDiff to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DocumentDiff
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DocumentDiffCopyWith<DocumentDiff> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentDiffCopyWith<$Res> {
  factory $DocumentDiffCopyWith(
          DocumentDiff value, $Res Function(DocumentDiff) then) =
      _$DocumentDiffCopyWithImpl<$Res, DocumentDiff>;
  @useResult
  $Res call(
      {MongoDocument sourceDocument,
      MongoDocument? targetDocument,
      DocumentDiffType diffType,
      Map<String, dynamic>? fieldDiffs});

  $MongoDocumentCopyWith<$Res> get sourceDocument;
  $MongoDocumentCopyWith<$Res>? get targetDocument;
}

/// @nodoc
class _$DocumentDiffCopyWithImpl<$Res, $Val extends DocumentDiff>
    implements $DocumentDiffCopyWith<$Res> {
  _$DocumentDiffCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DocumentDiff
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceDocument = null,
    Object? targetDocument = freezed,
    Object? diffType = null,
    Object? fieldDiffs = freezed,
  }) {
    return _then(_value.copyWith(
      sourceDocument: null == sourceDocument
          ? _value.sourceDocument
          : sourceDocument // ignore: cast_nullable_to_non_nullable
              as MongoDocument,
      targetDocument: freezed == targetDocument
          ? _value.targetDocument
          : targetDocument // ignore: cast_nullable_to_non_nullable
              as MongoDocument?,
      diffType: null == diffType
          ? _value.diffType
          : diffType // ignore: cast_nullable_to_non_nullable
              as DocumentDiffType,
      fieldDiffs: freezed == fieldDiffs
          ? _value.fieldDiffs
          : fieldDiffs // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }

  /// Create a copy of DocumentDiff
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MongoDocumentCopyWith<$Res> get sourceDocument {
    return $MongoDocumentCopyWith<$Res>(_value.sourceDocument, (value) {
      return _then(_value.copyWith(sourceDocument: value) as $Val);
    });
  }

  /// Create a copy of DocumentDiff
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MongoDocumentCopyWith<$Res>? get targetDocument {
    if (_value.targetDocument == null) {
      return null;
    }

    return $MongoDocumentCopyWith<$Res>(_value.targetDocument!, (value) {
      return _then(_value.copyWith(targetDocument: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DocumentDiffImplCopyWith<$Res>
    implements $DocumentDiffCopyWith<$Res> {
  factory _$$DocumentDiffImplCopyWith(
          _$DocumentDiffImpl value, $Res Function(_$DocumentDiffImpl) then) =
      __$$DocumentDiffImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {MongoDocument sourceDocument,
      MongoDocument? targetDocument,
      DocumentDiffType diffType,
      Map<String, dynamic>? fieldDiffs});

  @override
  $MongoDocumentCopyWith<$Res> get sourceDocument;
  @override
  $MongoDocumentCopyWith<$Res>? get targetDocument;
}

/// @nodoc
class __$$DocumentDiffImplCopyWithImpl<$Res>
    extends _$DocumentDiffCopyWithImpl<$Res, _$DocumentDiffImpl>
    implements _$$DocumentDiffImplCopyWith<$Res> {
  __$$DocumentDiffImplCopyWithImpl(
      _$DocumentDiffImpl _value, $Res Function(_$DocumentDiffImpl) _then)
      : super(_value, _then);

  /// Create a copy of DocumentDiff
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceDocument = null,
    Object? targetDocument = freezed,
    Object? diffType = null,
    Object? fieldDiffs = freezed,
  }) {
    return _then(_$DocumentDiffImpl(
      sourceDocument: null == sourceDocument
          ? _value.sourceDocument
          : sourceDocument // ignore: cast_nullable_to_non_nullable
              as MongoDocument,
      targetDocument: freezed == targetDocument
          ? _value.targetDocument
          : targetDocument // ignore: cast_nullable_to_non_nullable
              as MongoDocument?,
      diffType: null == diffType
          ? _value.diffType
          : diffType // ignore: cast_nullable_to_non_nullable
              as DocumentDiffType,
      fieldDiffs: freezed == fieldDiffs
          ? _value._fieldDiffs
          : fieldDiffs // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DocumentDiffImpl with DiagnosticableTreeMixin implements _DocumentDiff {
  const _$DocumentDiffImpl(
      {required this.sourceDocument,
      this.targetDocument,
      required this.diffType,
      final Map<String, dynamic>? fieldDiffs})
      : _fieldDiffs = fieldDiffs;

  factory _$DocumentDiffImpl.fromJson(Map<String, dynamic> json) =>
      _$$DocumentDiffImplFromJson(json);

  @override
  final MongoDocument sourceDocument;
  @override
  final MongoDocument? targetDocument;
  @override
  final DocumentDiffType diffType;
  final Map<String, dynamic>? _fieldDiffs;
  @override
  Map<String, dynamic>? get fieldDiffs {
    final value = _fieldDiffs;
    if (value == null) return null;
    if (_fieldDiffs is EqualUnmodifiableMapView) return _fieldDiffs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DocumentDiff(sourceDocument: $sourceDocument, targetDocument: $targetDocument, diffType: $diffType, fieldDiffs: $fieldDiffs)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DocumentDiff'))
      ..add(DiagnosticsProperty('sourceDocument', sourceDocument))
      ..add(DiagnosticsProperty('targetDocument', targetDocument))
      ..add(DiagnosticsProperty('diffType', diffType))
      ..add(DiagnosticsProperty('fieldDiffs', fieldDiffs));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocumentDiffImpl &&
            (identical(other.sourceDocument, sourceDocument) ||
                other.sourceDocument == sourceDocument) &&
            (identical(other.targetDocument, targetDocument) ||
                other.targetDocument == targetDocument) &&
            (identical(other.diffType, diffType) ||
                other.diffType == diffType) &&
            const DeepCollectionEquality()
                .equals(other._fieldDiffs, _fieldDiffs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, sourceDocument, targetDocument,
      diffType, const DeepCollectionEquality().hash(_fieldDiffs));

  /// Create a copy of DocumentDiff
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DocumentDiffImplCopyWith<_$DocumentDiffImpl> get copyWith =>
      __$$DocumentDiffImplCopyWithImpl<_$DocumentDiffImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DocumentDiffImplToJson(
      this,
    );
  }
}

abstract class _DocumentDiff implements DocumentDiff {
  const factory _DocumentDiff(
      {required final MongoDocument sourceDocument,
      final MongoDocument? targetDocument,
      required final DocumentDiffType diffType,
      final Map<String, dynamic>? fieldDiffs}) = _$DocumentDiffImpl;

  factory _DocumentDiff.fromJson(Map<String, dynamic> json) =
      _$DocumentDiffImpl.fromJson;

  @override
  MongoDocument get sourceDocument;
  @override
  MongoDocument? get targetDocument;
  @override
  DocumentDiffType get diffType;
  @override
  Map<String, dynamic>? get fieldDiffs;

  /// Create a copy of DocumentDiff
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocumentDiffImplCopyWith<_$DocumentDiffImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
