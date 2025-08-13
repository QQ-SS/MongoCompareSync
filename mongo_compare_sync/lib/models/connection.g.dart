// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MongoConnectionImplAdapter extends TypeAdapter<_$MongoConnectionImpl> {
  @override
  final int typeId = 0;

  @override
  _$MongoConnectionImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$MongoConnectionImpl(
      id: fields[0] as String,
      name: fields[1] as String,
      host: fields[2] as String,
      port: fields[3] as int,
      username: fields[4] as String?,
      password: fields[5] as String?,
      authDb: fields[6] as String?,
      useSsl: fields[7] as bool?,
      databases: (fields[8] as List).cast<String>(),
      isConnected: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, _$MongoConnectionImpl obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.host)
      ..writeByte(3)
      ..write(obj.port)
      ..writeByte(4)
      ..write(obj.username)
      ..writeByte(5)
      ..write(obj.password)
      ..writeByte(6)
      ..write(obj.authDb)
      ..writeByte(7)
      ..write(obj.useSsl)
      ..writeByte(9)
      ..write(obj.isConnected)
      ..writeByte(8)
      ..write(obj.databases);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MongoConnectionImplAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MongoConnectionImpl _$$MongoConnectionImplFromJson(
        Map<String, dynamic> json) =>
    _$MongoConnectionImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      username: json['username'] as String?,
      password: json['password'] as String?,
      authDb: json['authDb'] as String?,
      useSsl: json['useSsl'] as bool?,
      databases: (json['databases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isConnected: json['isConnected'] as bool? ?? false,
    );

Map<String, dynamic> _$$MongoConnectionImplToJson(
        _$MongoConnectionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'host': instance.host,
      'port': instance.port,
      'username': instance.username,
      'password': instance.password,
      'authDb': instance.authDb,
      'useSsl': instance.useSsl,
      'databases': instance.databases,
      'isConnected': instance.isConnected,
    };
