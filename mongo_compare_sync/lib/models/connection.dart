import 'package:json_annotation/json_annotation.dart';

part 'connection.g.dart';

@JsonSerializable()
class MongoConnection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String? username;
  final String? password;
  final String? authSource;
  final bool? useSsl;
  final List<String> databases;
  final bool isConnected;

  MongoConnection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.username,
    this.password,
    this.authSource,
    this.useSsl,
    this.databases = const [],
    this.isConnected = false,
  });

  factory MongoConnection.fromJson(Map<String, dynamic> json) =>
      _$MongoConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$MongoConnectionToJson(this);

  MongoConnection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? authSource,
    bool? useSsl,
    List<String>? databases,
    bool? isConnected,
  }) {
    return MongoConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      authSource: authSource ?? this.authSource,
      useSsl: useSsl ?? this.useSsl,
      databases: databases ?? this.databases,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
