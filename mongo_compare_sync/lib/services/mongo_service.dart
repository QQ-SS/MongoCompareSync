import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/connection.dart';
import '../models/collection.dart';
import '../models/document.dart';
import '../models/sync_result.dart';
import '../models/compare_rule.dart';
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
      final List<dynamic> databasesInfo = await db.listDatabases();
      final databases = databasesInfo
          .map((dbInfo) {
            if (dbInfo is Map) {
              return dbInfo['name'] as String?;
            }
            return null;
          })
          .whereType<String>()
          .where((name) => !['admin', 'local', 'config'].contains(name))
          .toList();
      return databases;
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

  Future<List<DocumentDiff>> compareCollections(
    String sourceConnectionId,
    String sourceDatabaseName,
    String sourceCollectionName,
    String targetConnectionId,
    String targetDatabaseName,
    String targetCollectionName, {
    List<String>? ignoreFields,
    List<FieldRule>? fieldRules,
  }) async {
    try {
      final sourceDocuments = await getDocuments(
        sourceConnectionId,
        sourceDatabaseName,
        sourceCollectionName,
        limit: 0,
      );
      final targetDocuments = await getDocuments(
        targetConnectionId,
        targetDatabaseName,
        targetCollectionName,
        limit: 0,
      );

      final targetDocMap = {for (var doc in targetDocuments) doc.id: doc};
      final List<DocumentDiff> diffs = [];

      for (var sourceDoc in sourceDocuments) {
        if (targetDocMap.containsKey(sourceDoc.id)) {
          final targetDoc = targetDocMap[sourceDoc.id]!;
          final fieldDiffs = _compareDocuments(
            sourceDoc.data,
            targetDoc.data,
            ignoreFields,
            fieldRules: fieldRules,
          );
          if (fieldDiffs.isNotEmpty) {
            diffs.add(
              DocumentDiff(
                sourceDocument: sourceDoc,
                targetDocument: targetDoc,
                diffType: DocumentDiffType.modified,
                fieldDiffs: fieldDiffs,
              ),
            );
          }
          targetDocMap.remove(sourceDoc.id);
        } else {
          // Document exists in source, not in target (Added)
          // Create a placeholder target to carry context for sync
          final placeholderTarget = MongoDocument(
            id: sourceDoc.id,
            data: const {},
            collectionName: targetCollectionName,
            databaseName: targetDatabaseName,
            connectionId: targetConnectionId,
          );
          diffs.add(
            DocumentDiff(
              sourceDocument: sourceDoc,
              targetDocument: placeholderTarget,
              diffType: DocumentDiffType.added,
            ),
          );
        }
      }

      for (var targetDoc in targetDocMap.values) {
        // Document exists in target, not in source (Removed)
        // Create a placeholder source to carry context for sync
        final placeholderSource = MongoDocument(
          id: targetDoc.id,
          data: const {},
          collectionName: sourceCollectionName,
          databaseName: sourceDatabaseName,
          connectionId: sourceConnectionId,
        );
        diffs.add(
          DocumentDiff(
            sourceDocument: placeholderSource,
            targetDocument: targetDoc,
            diffType: DocumentDiffType.removed,
          ),
        );
      }
      return diffs;
    } catch (e, stackTrace) {
      LogService.instance.error('比较集合错误: $e', e, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _compareDocuments(
    Map<String, dynamic> sourceDoc,
    Map<String, dynamic> targetDoc,
    List<String>? ignoreFields, {
    List<FieldRule>? fieldRules,
  }) {
    final Map<String, dynamic> diffs = {};
    final List<RegExp> ignoreRegexps = [];

    if (ignoreFields != null) {
      for (var field in ignoreFields) {
        final pattern = field
            .replaceAll('.', '\\.')
            .replaceAll('*', '.*')
            .replaceAll('?', '.');
        ignoreRegexps.add(RegExp('^$pattern\$'));
      }
    }
    if (fieldRules != null) {
      for (var rule in fieldRules) {
        if (rule.ruleType == RuleType.ignore) {
          final pattern = rule.fieldPath
              .replaceAll('.', '\\.')
              .replaceAll('*', '.*')
              .replaceAll('?', '.');
          ignoreRegexps.add(
            RegExp(rule.isRegex ? rule.fieldPath : '^$pattern\$'),
          );
        }
      }
    }

    void compareMaps(
      Map<String, dynamic> source,
      Map<String, dynamic> target,
      String path,
      Map<String, dynamic> result,
    ) {
      final allKeys = {...source.keys, ...target.keys};
      for (var key in allKeys) {
        if (key == '_id') continue;
        final currentPath = path.isEmpty ? key : '$path.$key';
        if (ignoreRegexps.any((regex) => regex.hasMatch(currentPath))) continue;

        final sourceValue = source[key];
        final targetValue = target[key];

        if (source.containsKey(key) && !target.containsKey(key)) {
          result[currentPath] = {'source': sourceValue, 'target': null};
        } else if (!source.containsKey(key) && target.containsKey(key)) {
          result[currentPath] = {'source': null, 'target': targetValue};
        } else {
          if (sourceValue is Map<String, dynamic> &&
              targetValue is Map<String, dynamic>) {
            compareMaps(sourceValue, targetValue, currentPath, result);
          } else if (sourceValue is List && targetValue is List) {
            if (!_areListsEqual(sourceValue, targetValue)) {
              result[currentPath] = {
                'source': sourceValue,
                'target': targetValue,
              };
            }
          } else if (sourceValue != targetValue) {
            result[currentPath] = {
              'source': sourceValue,
              'target': targetValue,
            };
          }
        }
      }
    }

    compareMaps(sourceDoc, targetDoc, '', diffs);
    return diffs;
  }

  bool _areListsEqual(List sourceList, List targetList) {
    if (sourceList.length != targetList.length) return false;
    for (int i = 0; i < sourceList.length; i++) {
      final sourceItem = sourceList[i];
      final targetItem = targetList[i];
      if (sourceItem is Map<String, dynamic> &&
          targetItem is Map<String, dynamic>) {
        if (_compareDocuments(sourceItem, targetItem, null).isNotEmpty) {
          return false;
        }
      } else if (sourceItem != targetItem) {
        return false;
      }
    }
    return true;
  }

  Future<void> syncDocumentDiff(DocumentDiff diff, bool sourceToTarget) async {
    if (diff.diffType == DocumentDiffType.unchanged) return;

    if (sourceToTarget) {
      // Sync from Source -> Target
      final target = diff.targetDocument!;
      switch (diff.diffType) {
        case DocumentDiffType.added:
          await insertDocument(
            target.connectionId,
            target.databaseName,
            target.collectionName,
            diff.sourceDocument.data,
          );
          break;
        case DocumentDiffType.removed:
          await deleteDocument(
            target.connectionId,
            target.databaseName,
            target.collectionName,
            ObjectId.parse(target.id),
          );
          break;
        case DocumentDiffType.modified:
          await updateDocument(
            target.connectionId,
            target.databaseName,
            target.collectionName,
            ObjectId.parse(target.id),
            diff.sourceDocument.data,
          );
          break;
        case DocumentDiffType.unchanged:
          break;
      }
    } else {
      // Sync from Target -> Source
      final source = diff.sourceDocument;
      switch (diff.diffType) {
        case DocumentDiffType.added: // Added in source means delete from source
          await deleteDocument(
            source.connectionId,
            source.databaseName,
            source.collectionName,
            ObjectId.parse(source.id),
          );
          break;
        case DocumentDiffType
            .removed: // Removed from source means add to source
          await insertDocument(
            source.connectionId,
            source.databaseName,
            source.collectionName,
            diff.targetDocument!.data,
          );
          break;
        case DocumentDiffType.modified:
          await updateDocument(
            source.connectionId,
            source.databaseName,
            source.collectionName,
            ObjectId.parse(source.id),
            diff.targetDocument!.data,
          );
          break;
        case DocumentDiffType.unchanged:
          break;
      }
    }
  }

  Future<SyncResult> syncDocumentDiffs(
    List<DocumentDiff> diffs,
    bool sourceToTarget, {
    List<String>? diffTypes,
  }) async {
    int successCount = 0;
    int failureCount = 0;
    List<String> errors = [];

    List<DocumentDiff> filteredDiffs = diffs;
    if (diffTypes != null && diffTypes.isNotEmpty) {
      filteredDiffs = diffs
          .where((diff) => diffTypes.contains(diff.status))
          .toList();
    }

    for (var diff in filteredDiffs) {
      try {
        await syncDocumentDiff(diff, sourceToTarget);
        successCount++;
      } catch (e, stackTrace) {
        failureCount++;
        final errorMsg = '同步文档 ${diff.sourceDocument.id} 失败: ${e.toString()}';
        errors.add(errorMsg);
        LogService.instance.error(errorMsg, e, stackTrace);
      }
    }

    return SyncResult(
      totalCount: filteredDiffs.length,
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
    );
  }
}
