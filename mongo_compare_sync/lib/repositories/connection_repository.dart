import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/collection.dart';
import '../models/connection.dart';
import '../services/mongo_service.dart';

class ConnectionRepository {
  static const String _fileName = 'connections.json';
  final MongoService _mongoService;
  List<MongoConnection> _currentConnections = []; // 内存中的连接列表

  // 单例模式
  static ConnectionRepository? _instance;

  factory ConnectionRepository({required MongoService mongoService}) {
    _instance ??= ConnectionRepository._internal(mongoService);
    return _instance!;
  }

  ConnectionRepository._internal(this._mongoService);

  // 获取连接文件路径
  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  // 从文件读取连接
  Future<List<MongoConnection>?> _readConnectionsFromFile() async {
    try {
      final file = File(await _getFilePath());
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        return jsonList.map((json) => MongoConnection.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error reading connections from file: $e');
    }
    return null;
  }

  // 将连接写入文件
  Future<void> _writeConnectionsToFile(
    List<MongoConnection> connections,
  ) async {
    try {
      final file = File(await _getFilePath());
      final json = jsonEncode(
        connections.map((conn) => conn.toJson()).toList(),
      );
      await file.writeAsString(json);
    } catch (e) {
      print('Error writing connections to file: $e');
    }
  }

  // 初始化存储库
  Future<void> init() async {
    _currentConnections = (await _readConnectionsFromFile()) ?? [];
  }

  // 获取所有连接
  List<MongoConnection> getAllConnections() {
    return List.from(_currentConnections); // 返回副本以防止外部修改
  }

  // 根据ID获取连接
  MongoConnection? getConnection(String id) {
    return _currentConnections.firstWhereOrNull((conn) => conn.id == id);
  }

  // 保存连接
  Future<MongoConnection> saveConnection(MongoConnection connection) async {
    final String id = connection.id.isEmpty ? const Uuid().v4() : connection.id;
    final updatedConnection = connection.copyWith(id: id);

    final index = _currentConnections.indexWhere((conn) => conn.id == id);
    if (index != -1) {
      _currentConnections[index] = updatedConnection;
    } else {
      _currentConnections.add(updatedConnection);
    }
    await _writeConnectionsToFile(_currentConnections);
    return updatedConnection;
  }

  // 删除连接
  Future<void> deleteConnection(String id) async {
    final connection = getConnection(id);
    if (connection != null && connection.isConnected) {
      await _mongoService.disconnect(id);
    }
    _currentConnections.removeWhere((conn) => conn.id == id);
    await _writeConnectionsToFile(_currentConnections);
  }

  // 连接到MongoDB
  Future<MongoConnection> connect(String id) async {
    final connection = getConnection(id);
    if (connection == null) {
      throw Exception('连接不存在');
    }

    final success = await _mongoService.connect(connection);
    if (success) {
      // 更新连接状态
      final updatedConnection = connection.copyWith(isConnected: true);
      await saveConnection(updatedConnection); // 使用saveConnection来更新内存和文件
      return updatedConnection;
    } else {
      throw Exception('连接失败');
    }
  }

  // 断开MongoDB连接
  Future<MongoConnection> disconnect(String id) async {
    final connection = getConnection(id);
    if (connection == null) {
      throw Exception('连接不存在');
    }

    await _mongoService.disconnect(id);

    // 更新连接状态
    final updatedConnection = connection.copyWith(isConnected: false);
    await saveConnection(updatedConnection); // 使用saveConnection来更新内存和文件
    return updatedConnection;
  }

  // 获取数据库列表
  Future<List<String>> getDatabases(String connectionId) async {
    final connection = getConnection(connectionId);
    if (connection == null) {
      throw Exception('连接不存在');
    }

    if (!connection.isConnected) {
      throw Exception('连接未建立');
    }

    final databases = await _mongoService.getDatabases(connectionId);

    // 更新连接中的数据库列表
    final updatedConnection = connection.copyWith(databases: databases);
    await saveConnection(updatedConnection); // 使用saveConnection来更新内存和文件

    return databases;
  }

  // 获取集合列表
  Future<List<MongoCollection>> getCollections(
    String connectionId,
    String databaseName,
  ) async {
    final connection = getConnection(connectionId);
    if (connection == null) {
      throw Exception('连接不存在');
    }

    if (!connection.isConnected) {
      throw Exception('连接未建立');
    }

    return await _mongoService.getCollections(connectionId, databaseName);
  }
}

// 扩展List，提供firstWhereOrNull方法 (如果compare_rule_repository.dart中已经有，这里可以省略)
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
