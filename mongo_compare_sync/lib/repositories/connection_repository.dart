import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/connection.dart';
import '../services/mongo_service.dart';

class ConnectionRepository {
  static const String _boxName = 'connections';
  final MongoService _mongoService;
  late Box<MongoConnection> _connectionsBox;

  // 单例模式
  static ConnectionRepository? _instance;

  factory ConnectionRepository({required MongoService mongoService}) {
    _instance ??= ConnectionRepository._internal(mongoService);
    return _instance!;
  }

  ConnectionRepository._internal(this._mongoService);

  // 初始化存储库
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MongoConnectionAdapter());
    _connectionsBox = await Hive.openBox<MongoConnection>(_boxName);
  }

  // 获取所有连接
  List<MongoConnection> getAllConnections() {
    return _connectionsBox.values.toList();
  }

  // 根据ID获取连接
  MongoConnection? getConnection(String id) {
    return _connectionsBox.get(id);
  }

  // 保存连接
  Future<MongoConnection> saveConnection(MongoConnection connection) async {
    final String id = connection.id.isEmpty ? const Uuid().v4() : connection.id;
    final updatedConnection = connection.copyWith(id: id);
    await _connectionsBox.put(id, updatedConnection);
    return updatedConnection;
  }

  // 删除连接
  Future<void> deleteConnection(String id) async {
    // 如果连接是活跃的，先断开连接
    final connection = _connectionsBox.get(id);
    if (connection != null && connection.isConnected) {
      await _mongoService.disconnect(id);
    }
    await _connectionsBox.delete(id);
  }

  // 连接到MongoDB
  Future<MongoConnection> connect(String id) async {
    final connection = _connectionsBox.get(id);
    if (connection == null) {
      throw Exception('连接不存在');
    }

    final success = await _mongoService.connect(connection);
    if (success) {
      // 更新连接状态
      final updatedConnection = connection.copyWith(isConnected: true);
      await _connectionsBox.put(id, updatedConnection);
      return updatedConnection;
    } else {
      throw Exception('连接失败');
    }
  }

  // 断开MongoDB连接
  Future<MongoConnection> disconnect(String id) async {
    final connection = _connectionsBox.get(id);
    if (connection == null) {
      throw Exception('连接不存在');
    }

    await _mongoService.disconnect(id);

    // 更新连接状态
    final updatedConnection = connection.copyWith(isConnected: false);
    await _connectionsBox.put(id, updatedConnection);
    return updatedConnection;
  }

  // 获取数据库列表
  Future<List<String>> getDatabases(String connectionId) async {
    final connection = _connectionsBox.get(connectionId);
    if (connection == null) {
      throw Exception('连接不存在');
    }

    if (!connection.isConnected) {
      throw Exception('连接未建立');
    }

    final databases = await _mongoService.getDatabases(connectionId);

    // 更新连接中的数据库列表
    final updatedConnection = connection.copyWith(databases: databases);
    await _connectionsBox.put(connectionId, updatedConnection);

    return databases;
  }
}

// Hive适配器
class MongoConnectionAdapter extends TypeAdapter<MongoConnection> {
  @override
  final int typeId = 0;

  @override
  MongoConnection read(BinaryReader reader) {
    return MongoConnection(
      id: reader.readString(),
      name: reader.readString(),
      host: reader.readString(),
      port: reader.readInt(),
      username: reader.readString(),
      password: reader.readString(),
      authDb: reader.readString(),
      useSsl: reader.readBool(),
      databases: List<String>.from(reader.readList()),
      isConnected: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, MongoConnection obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.host);
    writer.writeInt(obj.port);
    writer.writeString(obj.username ?? '');
    writer.writeString(obj.password ?? '');
    writer.writeString(obj.authDb ?? '');
    writer.writeBool(obj.useSsl ?? false);
    writer.writeList(obj.databases);
    writer.writeBool(obj.isConnected);
  }
}
