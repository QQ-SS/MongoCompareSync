import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

@freezed
class MongoConnection with _$MongoConnection {
  @HiveType(typeId: 0)
  const factory MongoConnection({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required String host,
    @HiveField(3) required int port,
    @HiveField(4) String? username,
    @HiveField(5) String? password,
    @HiveField(6) String? authDb,
    @HiveField(7) bool? useSsl,
    @HiveField(8) @Default([]) List<String> databases,
    @HiveField(9) @Default(false) bool isConnected,
  }) = _MongoConnection;

  factory MongoConnection.fromJson(Map<String, dynamic> json) =>
      _$MongoConnectionFromJson(json);
}
