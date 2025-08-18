import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/connection.dart';
import '../models/collection.dart';
import '../models/document.dart';
import '../models/sync_result.dart';
import '../models/compare_rule.dart';
import '../models/collection_compare_result.dart';
import 'log_service.dart';

class MongoService {
  // Store active connections with their original configuration
  final Map<String, ({MongoConnection connection, Db db})> _connections = {};

  String _buildUri(MongoConnection connection, [String? databaseName]) {
    String uri = 'mongodb://';
    if (connection.username != null && connection.password != null) {
      uri += '${connection.username}:${connection.password}@';
    }
    uri += '${connection.host}:${connection.port}';

    final dbName = databaseName;
    if (dbName != null && dbName.isNotEmpty) {
      uri += '/$dbName';
    }

    if (connection.useSsl == true) {
      uri += '?ssl=true';
    }
    if (connection.authSource != null && connection.authSource!.isNotEmpty) {
      uri += (uri.contains('?') == true) ? '&' : '?';
      uri += 'authSource=${connection.authSource}';
    }
    return uri;
  }

  Future<Db> _getDbForDatabase(String connectionId, String databaseName) async {
    if (!_connections.containsKey(connectionId)) {
      throw Exception('未找到连接: $connectionId');
    }
    final connectionConfig = _connections[connectionId]!.connection;
    final uri = _buildUri(connectionConfig, databaseName);
    final db = Db(uri);
    await db.open();
    return db;
  }

  Future<bool> connect(MongoConnection connection) async {
    try {
      LogService.instance.info('正在连接到MongoDB: ${connection.name}');
      // 明确连接到 admin 数据库，以便能够列出所有数据库
      final uri = _buildUri(connection, 'admin');
      final db = Db(uri);
      await db.open();
      _connections[connection.id] = (connection: connection, db: db);
      LogService.instance.info('已成功连接到MongoDB: ${connection.name}');
      return true;
    } catch (e, stackTrace) {
      LogService.instance.error('MongoDB连接错误: $e', e, stackTrace);
      return false;
    }
  }

  Future<void> disconnect(String connectionId) async {
    try {
      LogService.instance.info('正在断开MongoDB连接: $connectionId');
      if (_connections.containsKey(connectionId)) {
        await _connections[connectionId]!.db.close();
        _connections.remove(connectionId);
        LogService.instance.info('已断开MongoDB连接: $connectionId');
      }
    } catch (e, stackTrace) {
      LogService.instance.error('断开MongoDB连接错误: $e', e, stackTrace);
    }
  }

  Future<List<String>> getDatabases(String connectionId) async {
    if (!_connections.containsKey(connectionId)) {
      throw Exception('未找到连接: $connectionId');
    }
    final db = _connections[connectionId]!.db;
    try {
      LogService.instance.info('正在获取数据库列表，连接ID: $connectionId');
      final databasesInfo = await db.listDatabases();
      LogService.instance.info('原始数据库信息: $databasesInfo');
      LogService.instance.info('数据库信息类型: ${databasesInfo.runtimeType}');

      List<String> allDatabases = [];

      // 根据日志，databasesInfo 是一个字符串列表: [SqlSugarDb, admin, config, local, testDB]
      // 直接转换为字符串列表
      if (databasesInfo is List) {
        LogService.instance.info('处理List类型数据，长度: ${databasesInfo.length}');

        // 将所有项目转换为字符串
        allDatabases = databasesInfo.map((item) => item.toString()).toList();
        LogService.instance.info('转换后的数据库列表: $allDatabases');
      } else {
        LogService.instance.info('非List类型数据，直接转换为字符串');
        allDatabases = [databasesInfo.toString()];
      }

      LogService.instance.info('所有数据库: $allDatabases');

      // 过滤用户数据库
      final userDatabases = allDatabases
          .where((name) => !['admin', 'local', 'config'].contains(name))
          .toList();

      LogService.instance.info('用户数据库: $userDatabases');

      // 返回用户数据库，如果没有则返回所有数据库
      final result = userDatabases.isNotEmpty ? userDatabases : allDatabases;
      LogService.instance.info('最终返回的数据库列表: $result');

      return result;
    } catch (e, stackTrace) {
      LogService.instance.error('获取数据库列表错误: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<List<MongoCollection>> getCollections(
    String connectionId,
    String databaseName,
  ) async {
    Db? targetDb;
    try {
      targetDb = await _getDbForDatabase(connectionId, databaseName);
      final collectionNames = (await targetDb.getCollectionNames())
          .whereType<String>()
          .toList();
      final List<MongoCollection> collections = [];
      for (var collName in collectionNames) {
        if (collName.startsWith('system.')) continue;
        try {
          final count = await targetDb.collection(collName).count();
          collections.add(
            MongoCollection(
              name: collName,
              database: databaseName,
              connectionId: connectionId,
              documentCount: count,
            ),
          );
        } catch (e) {
          collections.add(
            MongoCollection(
              name: collName,
              database: databaseName,
              connectionId: connectionId,
              documentCount: -1,
            ),
          );
        }
      }
      return collections;
    } finally {
      await targetDb?.close();
    }
  }

  Future<List<MongoDocument>> getDocuments(
    String connectionId,
    String databaseName,
    String collectionName, {
    int limit = 100,
    int skip = 0,
    Map<String, dynamic>? query,
  }) async {
    Db? targetDb;
    try {
      targetDb = await _getDbForDatabase(connectionId, databaseName);
      final collection = targetDb.collection(collectionName);
      final documents = <MongoDocument>[];

      var cursor = collection.find(query).skip(skip);
      if (limit > 0) {
        cursor = cursor.take(limit);
      }

      await for (final doc in cursor) {
        documents.add(
          MongoDocument(
            id: doc['_id'].toString(),
            data: doc,
            collectionName: collectionName,
            databaseName: databaseName,
            connectionId: connectionId,
          ),
        );
      }
      return documents;
    } finally {
      await targetDb?.close();
    }
  }

  Future<void> insertDocument(
    String connectionId,
    String databaseName,
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    Db? targetDb;
    try {
      targetDb = await _getDbForDatabase(connectionId, databaseName);
      await targetDb.collection(collectionName).insert(data);
    } finally {
      await targetDb?.close();
    }
  }

  Future<void> updateDocument(
    String connectionId,
    String databaseName,
    String collectionName,
    ObjectId id,
    Map<String, dynamic> data,
  ) async {
    Db? targetDb;
    try {
      targetDb = await _getDbForDatabase(connectionId, databaseName);
      data.remove('_id');
      await targetDb.collection(collectionName).update(where.id(id), data);
    } finally {
      await targetDb?.close();
    }
  }

  // 更新某一个字段的值
  Future<void> updateField(
    String connectionId,
    String databaseName,
    String collectionName,
    ObjectId id,
    SetField setField,
  ) async {
    Db? targetDb;
    try {
      targetDb = await _getDbForDatabase(connectionId, databaseName);
      await targetDb.collection(collectionName).update(where.id(id), setField);
      // LogService.instance.info(setField);
    } finally {
      await targetDb?.close();
    }
  }

  // $unset 一个字段
  Future<void> removeField(
    String connectionId,
    String databaseName,
    String collectionName,
    ObjectId id,
    String field,
  ) async {
    Db? targetDb;
    try {
      targetDb = await _getDbForDatabase(connectionId, databaseName);
      await targetDb.collection(collectionName).update(
        where.id(id),
        <String, dynamic>{
          '\$unset': <String, dynamic>{field: 1},
        },
      );
      // LogService.instance.info(removeField(field));
    } finally {
      await targetDb?.close();
    }
  }

  Future<void> deleteDocument(
    String connectionId,
    String databaseName,
    String collectionName,
    ObjectId id,
  ) async {
    Db? targetDb;
    try {
      targetDb = await _getDbForDatabase(connectionId, databaseName);
      await targetDb.collection(collectionName).remove(where.id(id));
    } finally {
      await targetDb?.close();
    }
  }
}

/// 表示要设置的字段和值的类
class SetField {
  final String field;
  final dynamic value;

  SetField(this.field, this.value);

  Map<String, dynamic> toMap() {
    return {field: value};
  }
}
