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

  /// 详细比较两个集合中的所有文档
  ///
  /// [sourceConnectionId] 源连接ID
  /// [sourceDatabaseName] 源数据库名称
  /// [sourceCollectionName] 源集合名称
  /// [targetConnectionId] 目标连接ID
  /// [targetDatabaseName] 目标数据库名称
  /// [targetCollectionName] 目标集合名称
  /// [config] 比较配置
  Future<CollectionCompareResult> compareCollectionsDetailed(
    String sourceConnectionId,
    String sourceDatabaseName,
    String sourceCollectionName,
    String targetConnectionId,
    String targetDatabaseName,
    String targetCollectionName, {
    CompareConfig? config,
  }) async {
    try {
      LogService.instance.info(
        '开始详细比较集合: $sourceCollectionName 和 $targetCollectionName',
      );

      // 使用默认配置或提供的配置
      final compareConfig = config ?? CompareConfig();
      final idField = compareConfig.idField;
      final ignoreFields = compareConfig.ignoreFields;
      final caseSensitive = compareConfig.caseSensitive;

      // 获取源集合和目标集合的所有文档
      final sourceDocuments = await getDocuments(
        sourceConnectionId,
        sourceDatabaseName,
        sourceCollectionName,
        limit: 0, // 获取所有文档
      );

      final targetDocuments = await getDocuments(
        targetConnectionId,
        targetDatabaseName,
        targetCollectionName,
        limit: 0, // 获取所有文档
      );

      LogService.instance.info(
        '获取到源集合文档数: ${sourceDocuments.length}, 目标集合文档数: ${targetDocuments.length}',
      );

      // 创建文档ID映射，用于快速查找
      final Map<String, MongoDocument> sourceDocMap = {};
      final Map<String, MongoDocument> targetDocMap = {};

      // 提取文档ID并创建映射
      for (var doc in sourceDocuments) {
        final id = _extractDocumentId(doc.data, idField);
        if (id != null) {
          sourceDocMap[id] = doc;
        }
      }

      for (var doc in targetDocuments) {
        final id = _extractDocumentId(doc.data, idField);
        if (id != null) {
          targetDocMap[id] = doc;
        }
      }

      // 比较结果统计
      int sameDocumentsCount = 0;
      int differentDocumentsCount = 0;
      final List<String> sourceOnlyIds = [];
      final List<String> targetOnlyIds = [];
      final Map<String, DocumentCompareResult> documentResults = {};

      // 遍历源文档，与目标文档比较
      for (var entry in sourceDocMap.entries) {
        final id = entry.key;
        final sourceDoc = entry.value;

        if (targetDocMap.containsKey(id)) {
          // 文档在两边都存在，比较内容
          final targetDoc = targetDocMap[id]!;
          final result = _compareDocumentDetailed(
            sourceDoc.data,
            targetDoc.data,
            ignoreFields: ignoreFields,
            caseSensitive: caseSensitive,
          );

          documentResults[id] = result;

          if (result.isIdentical) {
            sameDocumentsCount++;
          } else {
            differentDocumentsCount++;
          }

          // 从目标映射中移除已处理的文档
          targetDocMap.remove(id);
        } else {
          // 文档只在源集合中存在
          sourceOnlyIds.add(id);
        }
      }

      // 剩余的目标文档是只在目标集合中存在的
      targetOnlyIds.addAll(targetDocMap.keys);

      // 创建并返回比较结果
      final result = CollectionCompareResult(
        sameDocumentsCount: sameDocumentsCount,
        differentDocumentsCount: differentDocumentsCount,
        sourceOnlyIds: sourceOnlyIds,
        targetOnlyIds: targetOnlyIds,
        documentResults: documentResults,
      );

      LogService.instance.info('集合比较完成: ${result.summary}');
      return result;
    } catch (e, stackTrace) {
      LogService.instance.error('详细比较集合错误: $e', e, stackTrace);
      rethrow;
    }
  }

  /// 从文档中提取ID字段的值
  String? _extractDocumentId(Map<String, dynamic> doc, String idField) {
    if (idField == '_id') {
      return doc['_id'].toString();
    } else if (doc.containsKey(idField)) {
      return doc[idField].toString();
    }
    return null;
  }

  /// 详细比较两个文档
  DocumentCompareResult _compareDocumentDetailed(
    Map<String, dynamic> sourceDoc,
    Map<String, dynamic> targetDoc, {
    List<String>? ignoreFields,
    bool caseSensitive = true,
  }) {
    final Map<String, FieldCompareResult> fieldResults = {};
    bool isIdentical = true;

    // 创建忽略字段的正则表达式列表
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

    // 递归比较两个Map
    void compareMaps(
      Map<String, dynamic> source,
      Map<String, dynamic> target,
      String path,
    ) {
      final allKeys = {...source.keys, ...target.keys};
      for (var key in allKeys) {
        if (key == '_id') continue; // 跳过ID字段

        final currentPath = path.isEmpty ? key : '$path.$key';

        // 检查是否应该忽略此字段
        if (ignoreRegexps.any((regex) => regex.hasMatch(currentPath))) {
          continue;
        }

        final sourceValue = source[key];
        final targetValue = target[key];

        // 处理字段存在性差异
        if (source.containsKey(key) && !target.containsKey(key)) {
          isIdentical = false;
          fieldResults[currentPath] = FieldCompareResult(
            isIdentical: false,
            sourceValue: sourceValue,
            targetValue: null,
          );
        } else if (!source.containsKey(key) && target.containsKey(key)) {
          isIdentical = false;
          fieldResults[currentPath] = FieldCompareResult(
            isIdentical: false,
            sourceValue: null,
            targetValue: targetValue,
          );
        } else {
          // 两边都有此字段，比较值
          if (sourceValue is Map<String, dynamic> &&
              targetValue is Map<String, dynamic>) {
            // 递归比较嵌套的Map
            compareMaps(sourceValue, targetValue, currentPath);
          } else if (sourceValue is List && targetValue is List) {
            // 比较列表
            final listResult = _compareListsDetailed(
              sourceValue,
              targetValue,
              caseSensitive,
            );
            if (!listResult.isIdentical) {
              isIdentical = false;
              fieldResults[currentPath] = listResult;
            }
          } else {
            // 比较简单值
            bool valuesEqual;
            if (!caseSensitive &&
                sourceValue is String &&
                targetValue is String) {
              valuesEqual =
                  sourceValue.toLowerCase() == targetValue.toLowerCase();
            } else {
              valuesEqual = sourceValue == targetValue;
            }

            if (!valuesEqual) {
              isIdentical = false;
              fieldResults[currentPath] = FieldCompareResult(
                isIdentical: false,
                sourceValue: sourceValue,
                targetValue: targetValue,
              );
            }
          }
        }
      }
    }

    // 开始比较
    compareMaps(sourceDoc, targetDoc, '');

    return DocumentCompareResult(
      isIdentical: isIdentical,
      fieldResults: fieldResults,
    );
  }

  /// 详细比较两个列表
  FieldCompareResult _compareListsDetailed(
    List sourceList,
    List targetList,
    bool caseSensitive,
  ) {
    // 简单比较：长度不同则不相等
    if (sourceList.length != targetList.length) {
      return FieldCompareResult(
        isIdentical: false,
        sourceValue: sourceList,
        targetValue: targetList,
      );
    }

    // 逐项比较
    for (int i = 0; i < sourceList.length; i++) {
      final sourceItem = sourceList[i];
      final targetItem = targetList[i];

      if (sourceItem is Map<String, dynamic> &&
          targetItem is Map<String, dynamic>) {
        // 递归比较嵌套的Map
        final result = _compareDocumentDetailed(
          sourceItem,
          targetItem,
          caseSensitive: caseSensitive,
        );
        if (!result.isIdentical) {
          return FieldCompareResult(
            isIdentical: false,
            sourceValue: sourceList,
            targetValue: targetList,
          );
        }
      } else if (sourceItem is List && targetItem is List) {
        // 递归比较嵌套的List
        final result = _compareListsDetailed(
          sourceItem,
          targetItem,
          caseSensitive,
        );
        if (!result.isIdentical) {
          return FieldCompareResult(
            isIdentical: false,
            sourceValue: sourceList,
            targetValue: targetList,
          );
        }
      } else {
        // 比较简单值
        bool valuesEqual;
        if (!caseSensitive && sourceItem is String && targetItem is String) {
          valuesEqual = sourceItem.toLowerCase() == targetItem.toLowerCase();
        } else {
          valuesEqual = sourceItem == targetItem;
        }

        if (!valuesEqual) {
          return FieldCompareResult(
            isIdentical: false,
            sourceValue: sourceList,
            targetValue: targetList,
          );
        }
      }
    }

    // 所有项都相等
    return FieldCompareResult(
      isIdentical: true,
      sourceValue: sourceList,
      targetValue: targetList,
    );
  }
}
