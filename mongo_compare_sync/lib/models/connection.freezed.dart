// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MongoConnection _$MongoConnectionFromJson(Map<String, dynamic> json) {
  return _MongoConnection.fromJson(json);
}

/// @nodoc
mixin _$MongoConnection {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  String get host => throw _privateConstructorUsedError;
  @HiveField(3)
  int get port => throw _privateConstructorUsedError;
  @HiveField(4)
  String? get username => throw _privateConstructorUsedError;
  @HiveField(5)
  String? get password => throw _privateConstructorUsedError;
  @HiveField(6)
  String? get authDb => throw _privateConstructorUsedError;
  @HiveField(7)
  bool? get useSsl => throw _privateConstructorUsedError;
  @HiveField(8)
  List<String> get databases => throw _privateConstructorUsedError;
  @HiveField(9)
  bool get isConnected => throw _privateConstructorUsedError;

  /// Serializes this MongoConnection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MongoConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MongoConnectionCopyWith<MongoConnection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MongoConnectionCopyWith<$Res> {
  factory $MongoConnectionCopyWith(
          MongoConnection value, $Res Function(MongoConnection) then) =
      _$MongoConnectionCopyWithImpl<$Res, MongoConnection>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) String host,
      @HiveField(3) int port,
      @HiveField(4) String? username,
      @HiveField(5) String? password,
      @HiveField(6) String? authDb,
      @HiveField(7) bool? useSsl,
      @HiveField(8) List<String> databases,
      @HiveField(9) bool isConnected});
}

/// @nodoc
class _$MongoConnectionCopyWithImpl<$Res, $Val extends MongoConnection>
    implements $MongoConnectionCopyWith<$Res> {
  _$MongoConnectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MongoConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? host = null,
    Object? port = null,
    Object? username = freezed,
    Object? password = freezed,
    Object? authDb = freezed,
    Object? useSsl = freezed,
    Object? databases = null,
    Object? isConnected = null,
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
      host: null == host
          ? _value.host
          : host // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      authDb: freezed == authDb
          ? _value.authDb
          : authDb // ignore: cast_nullable_to_non_nullable
              as String?,
      useSsl: freezed == useSsl
          ? _value.useSsl
          : useSsl // ignore: cast_nullable_to_non_nullable
              as bool?,
      databases: null == databases
          ? _value.databases
          : databases // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isConnected: null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MongoConnectionImplCopyWith<$Res>
    implements $MongoConnectionCopyWith<$Res> {
  factory _$$MongoConnectionImplCopyWith(_$MongoConnectionImpl value,
          $Res Function(_$MongoConnectionImpl) then) =
      __$$MongoConnectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) String host,
      @HiveField(3) int port,
      @HiveField(4) String? username,
      @HiveField(5) String? password,
      @HiveField(6) String? authDb,
      @HiveField(7) bool? useSsl,
      @HiveField(8) List<String> databases,
      @HiveField(9) bool isConnected});
}

/// @nodoc
class __$$MongoConnectionImplCopyWithImpl<$Res>
    extends _$MongoConnectionCopyWithImpl<$Res, _$MongoConnectionImpl>
    implements _$$MongoConnectionImplCopyWith<$Res> {
  __$$MongoConnectionImplCopyWithImpl(
      _$MongoConnectionImpl _value, $Res Function(_$MongoConnectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of MongoConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? host = null,
    Object? port = null,
    Object? username = freezed,
    Object? password = freezed,
    Object? authDb = freezed,
    Object? useSsl = freezed,
    Object? databases = null,
    Object? isConnected = null,
  }) {
    return _then(_$MongoConnectionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      host: null == host
          ? _value.host
          : host // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      authDb: freezed == authDb
          ? _value.authDb
          : authDb // ignore: cast_nullable_to_non_nullable
              as String?,
      useSsl: freezed == useSsl
          ? _value.useSsl
          : useSsl // ignore: cast_nullable_to_non_nullable
              as bool?,
      databases: null == databases
          ? _value._databases
          : databases // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isConnected: null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
@HiveType(typeId: 0)
class _$MongoConnectionImpl
    with DiagnosticableTreeMixin
    implements _MongoConnection {
  const _$MongoConnectionImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.name,
      @HiveField(2) required this.host,
      @HiveField(3) required this.port,
      @HiveField(4) this.username,
      @HiveField(5) this.password,
      @HiveField(6) this.authDb,
      @HiveField(7) this.useSsl,
      @HiveField(8) final List<String> databases = const [],
      @HiveField(9) this.isConnected = false})
      : _databases = databases;

  factory _$MongoConnectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MongoConnectionImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final String host;
  @override
  @HiveField(3)
  final int port;
  @override
  @HiveField(4)
  final String? username;
  @override
  @HiveField(5)
  final String? password;
  @override
  @HiveField(6)
  final String? authDb;
  @override
  @HiveField(7)
  final bool? useSsl;
  final List<String> _databases;
  @override
  @JsonKey()
  @HiveField(8)
  List<String> get databases {
    if (_databases is EqualUnmodifiableListView) return _databases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_databases);
  }

  @override
  @JsonKey()
  @HiveField(9)
  final bool isConnected;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MongoConnection(id: $id, name: $name, host: $host, port: $port, username: $username, password: $password, authDb: $authDb, useSsl: $useSsl, databases: $databases, isConnected: $isConnected)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'MongoConnection'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('host', host))
      ..add(DiagnosticsProperty('port', port))
      ..add(DiagnosticsProperty('username', username))
      ..add(DiagnosticsProperty('password', password))
      ..add(DiagnosticsProperty('authDb', authDb))
      ..add(DiagnosticsProperty('useSsl', useSsl))
      ..add(DiagnosticsProperty('databases', databases))
      ..add(DiagnosticsProperty('isConnected', isConnected));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MongoConnectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.authDb, authDb) || other.authDb == authDb) &&
            (identical(other.useSsl, useSsl) || other.useSsl == useSsl) &&
            const DeepCollectionEquality()
                .equals(other._databases, _databases) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      host,
      port,
      username,
      password,
      authDb,
      useSsl,
      const DeepCollectionEquality().hash(_databases),
      isConnected);

  /// Create a copy of MongoConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MongoConnectionImplCopyWith<_$MongoConnectionImpl> get copyWith =>
      __$$MongoConnectionImplCopyWithImpl<_$MongoConnectionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MongoConnectionImplToJson(
      this,
    );
  }
}

abstract class _MongoConnection implements MongoConnection {
  const factory _MongoConnection(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String name,
      @HiveField(2) required final String host,
      @HiveField(3) required final int port,
      @HiveField(4) final String? username,
      @HiveField(5) final String? password,
      @HiveField(6) final String? authDb,
      @HiveField(7) final bool? useSsl,
      @HiveField(8) final List<String> databases,
      @HiveField(9) final bool isConnected}) = _$MongoConnectionImpl;

  factory _MongoConnection.fromJson(Map<String, dynamic> json) =
      _$MongoConnectionImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get name;
  @override
  @HiveField(2)
  String get host;
  @override
  @HiveField(3)
  int get port;
  @override
  @HiveField(4)
  String? get username;
  @override
  @HiveField(5)
  String? get password;
  @override
  @HiveField(6)
  String? get authDb;
  @override
  @HiveField(7)
  bool? get useSsl;
  @override
  @HiveField(8)
  List<String> get databases;
  @override
  @HiveField(9)
  bool get isConnected;

  /// Create a copy of MongoConnection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MongoConnectionImplCopyWith<_$MongoConnectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
