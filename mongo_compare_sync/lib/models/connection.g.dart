// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MongoConnection _$MongoConnectionFromJson(Map<String, dynamic> json) =>
    MongoConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      username: json['username'] as String?,
      password: json['password'] as String?,
      authSource: json['authSource'] as String?,
      useSsl: json['useSsl'] as bool?,
      databases:
          (json['databases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isConnected: json['isConnected'] as bool? ?? false,
    );

Map<String, dynamic> _$MongoConnectionToJson(MongoConnection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'host': instance.host,
      'port': instance.port,
      'username': instance.username,
      'password': instance.password,
      'authSource': instance.authSource,
      'useSsl': instance.useSsl,
      'databases': instance.databases,
      'isConnected': instance.isConnected,
    };
