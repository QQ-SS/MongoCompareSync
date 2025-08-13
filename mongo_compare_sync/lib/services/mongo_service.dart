import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/connection.dart';
import '../models/collection.dart';
import '../models/document.dart';

class MongoService {
  // 存储活跃的数据库连接
  final Map<String, Db> _connections = {};

  // 连接到MongoDB数据库
  Future<bool> connect(MongoConnection connection) async {
    try {
      // 构建连接URI
      String uri = 'mongodb://';

      // 添加认证信息（如果有）
      if (connection.username != null && connection.password != null) {
        uri += '${connection.username}:${connection.password}@';
      }

      // 添加主机和端口
      uri += '${connection.host}:${connection.port}';

      // 添加认证数据库（如果有）
      if (connection.authDb != null) {
        uri += '/${connection.authDb}';
      }

      // 添加SSL选项（如果需要）
      if (connection.useSsl == true) {
        uri += '?ssl=true';
      }

      // 创建数据库连接
      final db = Db(uri);
      await db.open();

      // 存储连接
      _connections[connection.id] = db;

      return true;
    } catch (e) {
      print('MongoDB连接错误: $e');
      return false;
    }
  }

  // 断开与MongoDB数据库的连接
  Future<void> disconnect(String connectionId) async {
    if (_connections.containsKey(connectionId)) {
      await _connections[connectionId]!.close();
      _connections.remove(connectionId);
    }
  }

  // 获取数据库列表
  Future<List<String>> getDatabases(String connectionId) async {
    if (!_connections.containsKey(connectionId)) {
      throw Exception('未找到连接');
    }

    final db = _connections[connectionId]!;

    // 在mongo_dart中，我们可以通过查询admin.$cmd来获取数据库列表
    final adminDb = db.collection('system.namespaces');
    final List<Map<String, dynamic>> result = await adminDb.find().toList();

    // 从命名空间中提取数据库名称
    final Set<String> databases = {};
    for (var doc in result) {
      if (doc.containsKey('name')) {
        final String ns = doc['name'];
        final dbName = ns.split('.').first;
        if (!dbName.startsWith('system.') && !databases.contains(dbName)) {
          databases.add(dbName);
        }
      }
    }

    return databases.toList();
  }

  // 获取集合列表
  Future<List<MongoCollection>> getCollections(
    String connectionId,
    String databaseName,
  ) async {
    if (!_connections.containsKey(connectionId)) {
      throw Exception('未找到连接');
    }

    final db = _connections[connectionId]!;

    // 获取集合名称列表
    final List<String> collectionNames = await db.getCollectionNames().then(
      (list) => list.whereType<String>().toList(),
    );

    final List<MongoCollection> collections = [];
    for (var collName in collectionNames) {
      // 跳过系统集合
      if (collName.startsWith('system.')) continue;

      // 获取集合中的文档数量
      final count = await db.collection(collName).count();

      collections.add(
        MongoCollection(
          name: collName,
          database: databaseName,
          connectionId: connectionId,
          documentCount: count,
        ),
      );
    }

    return collections;
  }

  // 获取文档列表
  Future<List<MongoDocument>> getDocuments(
    String connectionId,
    String databaseName,
    String collectionName, {
    int limit = 100,
    int skip = 0,
    Map<String, dynamic>? query,
  }) async {
    if (!_connections.containsKey(connectionId)) {
      throw Exception('未找到连接');
    }

    final db = _connections[connectionId]!;
    final collection = db.collection(collectionName);

    final List<MongoDocument> documents = [];

    try {
      // 使用find方法获取文档
      final cursor = collection.find(query ?? {});

      // 手动处理分页
      int count = 0;
      int skipped = 0;

      await for (var doc in cursor) {
        // 跳过前skip个文档
        if (skipped < skip) {
          skipped++;
          continue;
        }

        // 添加文档到结果列表
        documents.add(
          MongoDocument(
            id: doc['_id'].toString(),
            data: doc,
            collectionName: collectionName,
            databaseName: databaseName,
            connectionId: connectionId,
          ),
        );

        // 如果达到limit限制，则停止
        count++;
        if (limit > 0 && count >= limit) {
          break;
        }
      }
    } catch (e) {
      print('获取文档错误: $e');
      throw Exception('获取文档失败: $e');
    }

    return documents;
  }

  // 插入文档
  Future<void> insertDocument(
    String connectionId,
    String databaseName,
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    if (!_connections.containsKey(connectionId)) {
      throw Exception('未找到连接');
    }

    final db = _connections[connectionId]!;
    final collection = db.collection(collectionName);

    await collection.insert(data);
  }

  // 更新文档
  Future<void> updateDocument(
    String connectionId,
    String databaseName,
    String collectionName,
    ObjectId id,
    Map<String, dynamic> data,
  ) async {
    if (!_connections.containsKey(connectionId)) {
      throw Exception('未找到连接');
    }

    final db = _connections[connectionId]!;
    final collection = db.collection(collectionName);

    // 移除_id字段，因为它不能被更新
    data.remove('_id');

    await collection.update(where.id(id), data);
  }

  // 删除文档
  Future<void> deleteDocument(
    String connectionId,
    String databaseName,
    String collectionName,
    ObjectId id,
  ) async {
    if (!_connections.containsKey(connectionId)) {
      throw Exception('未找到连接');
    }

    final db = _connections[connectionId]!;
    final collection = db.collection(collectionName);

    await collection.remove(where.id(id));
  }

  // 比较两个集合的文档
  Future<List<DocumentDiff>> compareCollections(
    String sourceConnectionId,
    String sourceDatabaseName,
    String sourceCollectionName,
    String targetConnectionId,
    String targetDatabaseName,
    String targetCollectionName, {
    List<String>? ignoreFields,
  }) async {
    // 获取源集合的所有文档
    final sourceDocuments = await getDocuments(
      sourceConnectionId,
      sourceDatabaseName,
      sourceCollectionName,
      limit: 0, // 不限制数量
    );

    // 获取目标集合的所有文档
    final targetDocuments = await getDocuments(
      targetConnectionId,
      targetDatabaseName,
      targetCollectionName,
      limit: 0, // 不限制数量
    );

    // 创建目标文档的ID映射，以便快速查找
    final targetDocMap = {for (var doc in targetDocuments) doc.id: doc};

    // 存储比较结果
    final List<DocumentDiff> diffs = [];

    // 比较源文档和目标文档
    for (var sourceDoc in sourceDocuments) {
      if (targetDocMap.containsKey(sourceDoc.id)) {
        // 文档在两个集合中都存在，检查是否有差异
        final targetDoc = targetDocMap[sourceDoc.id]!;
        final fieldDiffs = _compareDocuments(
          sourceDoc.data,
          targetDoc.data,
          ignoreFields,
        );

        if (fieldDiffs.isNotEmpty) {
          // 文档有差异
          diffs.add(
            DocumentDiff(
              sourceDocument: sourceDoc,
              targetDocument: targetDoc,
              diffType: DocumentDiffType.modified,
              fieldDiffs: fieldDiffs,
            ),
          );
        }

        // 从映射中移除已处理的目标文档
        targetDocMap.remove(sourceDoc.id);
      } else {
        // 文档只在源集合中存在
        diffs.add(
          DocumentDiff(
            sourceDocument: sourceDoc,
            diffType: DocumentDiffType.added,
          ),
        );
      }
    }

    // 处理只在目标集合中存在的文档
    for (var targetDoc in targetDocMap.values) {
      diffs.add(
        DocumentDiff(
          sourceDocument: targetDoc, // 这里使用目标文档作为源文档，因为我们需要一个引用
          targetDocument: targetDoc,
          diffType: DocumentDiffType.removed,
        ),
      );
    }

    return diffs;
  }

  // 比较两个文档并返回字段差异
  Map<String, dynamic> _compareDocuments(
    Map<String, dynamic> sourceDoc,
    Map<String, dynamic> targetDoc,
    List<String>? ignoreFields,
  ) {
    final Map<String, dynamic> diffs = {};

    // 比较源文档中的字段
    for (var key in sourceDoc.keys) {
      // 跳过被忽略的字段
      if (ignoreFields != null && ignoreFields.contains(key)) {
        continue;
      }

      // 跳过_id字段
      if (key == '_id') {
        continue;
      }

      if (!targetDoc.containsKey(key)) {
        // 字段只在源文档中存在
        diffs[key] = {
          'source': sourceDoc[key],
          'target': null,
          'status': 'removed',
        };
      } else if (sourceDoc[key] != targetDoc[key]) {
        // 字段值不同
        diffs[key] = {
          'source': sourceDoc[key],
          'target': targetDoc[key],
          'status': 'modified',
        };
      }
    }

    // 检查只在目标文档中存在的字段
    for (var key in targetDoc.keys) {
      // 跳过被忽略的字段
      if (ignoreFields != null && ignoreFields.contains(key)) {
        continue;
      }

      // 跳过_id字段
      if (key == '_id') {
        continue;
      }

      if (!sourceDoc.containsKey(key)) {
        // 字段只在目标文档中存在
        diffs[key] = {
          'source': null,
          'target': targetDoc[key],
          'status': 'added',
        };
      }
    }

    return diffs;
  }

  // 同步文档差异
  Future<void> syncDocumentDiff(DocumentDiff diff, bool sourceToTarget) async {
    if (diff.diffType == DocumentDiffType.unchanged) {
      // 没有差异，不需要同步
      return;
    }

    if (sourceToTarget) {
      // 从源到目标的同步
      switch (diff.diffType) {
        case DocumentDiffType.added:
          // 在目标中创建文档
          await insertDocument(
            diff.sourceDocument.connectionId,
            diff.sourceDocument.databaseName,
            diff.sourceDocument.collectionName,
            diff.sourceDocument.data,
          );
          break;
        case DocumentDiffType.removed:
          // 从目标中删除文档
          if (diff.targetDocument != null) {
            await deleteDocument(
              diff.targetDocument!.connectionId,
              diff.targetDocument!.databaseName,
              diff.targetDocument!.collectionName,
              ObjectId.parse(diff.targetDocument!.id),
            );
          }
          break;
        case DocumentDiffType.modified:
          // 更新目标中的文档
          if (diff.targetDocument != null) {
            await updateDocument(
              diff.targetDocument!.connectionId,
              diff.targetDocument!.databaseName,
              diff.targetDocument!.collectionName,
              ObjectId.parse(diff.targetDocument!.id),
              diff.sourceDocument.data,
            );
          }
          break;
        case DocumentDiffType.unchanged:
          // 不需要操作
          break;
      }
    } else {
      // 从目标到源的同步
      switch (diff.diffType) {
        case DocumentDiffType.added:
          // 在源中删除文档
          await deleteDocument(
            diff.sourceDocument.connectionId,
            diff.sourceDocument.databaseName,
            diff.sourceDocument.collectionName,
            ObjectId.parse(diff.sourceDocument.id),
          );
          break;
        case DocumentDiffType.removed:
          // 在源中创建文档
          if (diff.targetDocument != null) {
            await insertDocument(
              diff.sourceDocument.connectionId,
              diff.sourceDocument.databaseName,
              diff.sourceDocument.collectionName,
              diff.targetDocument!.data,
            );
          }
          break;
        case DocumentDiffType.modified:
          // 更新源中的文档
          if (diff.targetDocument != null) {
            await updateDocument(
              diff.sourceDocument.connectionId,
              diff.sourceDocument.databaseName,
              diff.sourceDocument.collectionName,
              ObjectId.parse(diff.sourceDocument.id),
              diff.targetDocument!.data,
            );
          }
          break;
        case DocumentDiffType.unchanged:
          // 不需要操作
          break;
      }
    }
  }
}
