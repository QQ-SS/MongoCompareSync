import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/connection.dart';
import '../models/collection.dart';
import '../models/document.dart';
import '../models/sync_result.dart';
import '../models/compare_rule.dart';
import 'log_service.dart';
import 'error_service.dart';

class MongoService {
  // 存储活跃的数据库连接
  final Map<String, Db> _connections = {};

  // 连接到MongoDB数据库
  Future<bool> connect(MongoConnection connection) async {
    try {
      LogService.instance.info('正在连接到MongoDB: ${connection.name}');

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

      LogService.instance.info('已成功连接到MongoDB: ${connection.name}');
      return true;
    } catch (e, stackTrace) {
      LogService.instance.error('MongoDB连接错误: $e', e, stackTrace);
      // 由于我们没有BuildContext，所以只记录错误，不显示UI提示
      return false;
    }
  }

  // 断开与MongoDB数据库的连接
  Future<void> disconnect(String connectionId) async {
    try {
      LogService.instance.info('正在断开MongoDB连接: $connectionId');
      if (_connections.containsKey(connectionId)) {
        await _connections[connectionId]!.close();
        _connections.remove(connectionId);
        LogService.instance.info('已断开MongoDB连接: $connectionId');
      } else {
        LogService.instance.warning('尝试断开不存在的连接: $connectionId');
      }
    } catch (e, stackTrace) {
      LogService.instance.error('断开MongoDB连接错误: $e', e, stackTrace);
    }
  }

  // 获取数据库列表
  Future<List<String>> getDatabases(String connectionId) async {
    try {
      LogService.instance.info('正在获取数据库列表: $connectionId');

      if (!_connections.containsKey(connectionId)) {
        LogService.instance.error('未找到连接: $connectionId');
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

      LogService.instance.info(
        '成功获取数据库列表: $connectionId, 数量: ${databases.length}',
      );
      return databases.toList();
    } catch (e, stackTrace) {
      LogService.instance.error('获取数据库列表错误: $e', e, stackTrace);
      rethrow; // 重新抛出异常，让调用者处理
    }
  }

  // 获取集合列表
  Future<List<MongoCollection>> getCollections(
    String connectionId,
    String databaseName,
  ) async {
    try {
      LogService.instance.info('正在获取集合列表: $connectionId, 数据库: $databaseName');

      if (!_connections.containsKey(connectionId)) {
        LogService.instance.error('未找到连接: $connectionId');
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

        try {
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
        } catch (e) {
          // 如果获取文档数量失败，记录错误但继续处理其他集合
          LogService.instance.warning('获取集合文档数量失败: $collName, 错误: $e');
          collections.add(
            MongoCollection(
              name: collName,
              database: databaseName,
              connectionId: connectionId,
              documentCount: -1, // 使用-1表示未知数量
            ),
          );
        }
      }

      LogService.instance.info(
        '成功获取集合列表: $connectionId, 数据库: $databaseName, 数量: ${collections.length}',
      );
      return collections;
    } catch (e, stackTrace) {
      LogService.instance.error('获取集合列表错误: $e', e, stackTrace);
      rethrow; // 重新抛出异常，让调用者处理
    }
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
    try {
      LogService.instance.info(
        '正在获取文档列表: $connectionId, 数据库: $databaseName, 集合: $collectionName, '
        'limit: $limit, skip: $skip, query: ${query ?? "{}"}',
      );

      if (!_connections.containsKey(connectionId)) {
        LogService.instance.error('未找到连接: $connectionId');
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

        LogService.instance.info(
          '成功获取文档列表: $connectionId, 数据库: $databaseName, 集合: $collectionName, '
          '数量: ${documents.length}',
        );
        return documents;
      } catch (e, stackTrace) {
        LogService.instance.error('获取文档错误: $e', e, stackTrace);
        throw Exception('获取文档失败: $e');
      }
    } catch (e, stackTrace) {
      LogService.instance.error('获取文档列表错误: $e', e, stackTrace);
      rethrow; // 重新抛出异常，让调用者处理
    }
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
    List<FieldRule>? fieldRules,
  }) async {
    try {
      LogService.instance.info(
        '开始比较集合: 源(${sourceConnectionId}.${sourceDatabaseName}.${sourceCollectionName}) '
        '与目标(${targetConnectionId}.${targetDatabaseName}.${targetCollectionName})',
      );

      // 获取源集合的所有文档
      LogService.instance.info('正在获取源集合文档...');
      final sourceDocuments = await getDocuments(
        sourceConnectionId,
        sourceDatabaseName,
        sourceCollectionName,
        limit: 0, // 不限制数量
      );
      LogService.instance.info('源集合文档数量: ${sourceDocuments.length}');

      // 获取目标集合的所有文档
      LogService.instance.info('正在获取目标集合文档...');
      final targetDocuments = await getDocuments(
        targetConnectionId,
        targetDatabaseName,
        targetCollectionName,
        limit: 0, // 不限制数量
      );
      LogService.instance.info('目标集合文档数量: ${targetDocuments.length}');

      // 创建目标文档的ID映射，以便快速查找
      final targetDocMap = {for (var doc in targetDocuments) doc.id: doc};

      // 存储比较结果
      final List<DocumentDiff> diffs = [];
      int modifiedCount = 0;
      int addedCount = 0;
      int removedCount = 0;

      // 比较源文档和目标文档
      LogService.instance.info('正在比较文档...');
      for (var sourceDoc in sourceDocuments) {
        if (targetDocMap.containsKey(sourceDoc.id)) {
          // 文档在两个集合中都存在，检查是否有差异
          final targetDoc = targetDocMap[sourceDoc.id]!;
          final fieldDiffs = _compareDocuments(
            sourceDoc.data,
            targetDoc.data,
            ignoreFields,
            fieldRules: fieldRules,
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
            modifiedCount++;
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
          addedCount++;
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
        removedCount++;
      }

      LogService.instance.info(
        '比较完成: 总差异数: ${diffs.length}, 修改: $modifiedCount, 新增: $addedCount, 删除: $removedCount',
      );
      return diffs;
    } catch (e, stackTrace) {
      LogService.instance.error('比较集合错误: $e', e, stackTrace);
      rethrow; // 重新抛出异常，让调用者处理
    }
  }

  // 比较两个文档并返回字段差异
  Map<String, dynamic> _compareDocuments(
    Map<String, dynamic> sourceDoc,
    Map<String, dynamic> targetDoc,
    List<String>? ignoreFields, {
    List<FieldRule>? fieldRules,
  }) {
    final Map<String, dynamic> diffs = {};

    // 将忽略字段列表转换为正则表达式列表，以支持通配符匹配
    final List<RegExp> ignoreRegexps = [];

    // 处理简单的忽略字段列表
    if (ignoreFields != null) {
      for (var field in ignoreFields) {
        // 将通配符转换为正则表达式
        final pattern = field
            .replaceAll('.', '\\.') // 转义点号
            .replaceAll('*', '.*') // 将*转换为正则表达式的.*
            .replaceAll('?', '.'); // 将?转换为正则表达式的.
        ignoreRegexps.add(RegExp('^$pattern\$'));
      }
    }

    // 处理字段规则
    if (fieldRules != null) {
      for (var rule in fieldRules) {
        if (rule.ruleType == RuleType.ignore) {
          final pattern = rule.fieldPath
              .replaceAll('.', '\\.') // 转义点号
              .replaceAll('*', '.*') // 将*转换为正则表达式的.*
              .replaceAll('?', '.'); // 将?转换为正则表达式的.

          // 如果规则本身就是正则表达式，则直接使用
          if (rule.isRegex) {
            try {
              ignoreRegexps.add(RegExp(rule.fieldPath));
            } catch (e) {
              print('无效的正则表达式: ${rule.fieldPath}, 错误: $e');
              // 回退到普通字符串匹配
              ignoreRegexps.add(RegExp('^$pattern\$'));
            }
          } else {
            ignoreRegexps.add(RegExp('^$pattern\$'));
          }
        }
      }
    }

    // 递归比较函数，支持嵌套对象
    void _compareNestedDocuments(
      Map<String, dynamic> source,
      Map<String, dynamic> target,
      String path,
      Map<String, dynamic> result,
    ) {
      // 比较源文档中的字段
      for (var key in source.keys) {
        final currentPath = path.isEmpty ? key : '$path.$key';

        // 跳过_id字段
        if (key == '_id') {
          continue;
        }

        // 检查是否应该忽略此字段
        bool shouldIgnore = false;
        for (var regex in ignoreRegexps) {
          if (regex.hasMatch(currentPath)) {
            shouldIgnore = true;
            break;
          }
        }
        if (shouldIgnore) {
          continue;
        }

        if (!target.containsKey(key)) {
          // 字段只在源文档中存在
          result[currentPath] = {
            'source': source[key],
            'target': null,
            'status': 'removed',
            'path': currentPath,
          };
        } else {
          final sourceValue = source[key];
          final targetValue = target[key];

          if (sourceValue is Map<String, dynamic> &&
              targetValue is Map<String, dynamic>) {
            // 递归比较嵌套对象
            _compareNestedDocuments(
              sourceValue,
              targetValue,
              currentPath,
              result,
            );
          } else if (sourceValue is List && targetValue is List) {
            // 比较数组
            if (!_areListsEqual(sourceValue, targetValue)) {
              result[currentPath] = {
                'source': sourceValue,
                'target': targetValue,
                'status': 'modified',
                'path': currentPath,
              };
            }
          } else if (sourceValue != targetValue) {
            // 字段值不同
            result[currentPath] = {
              'source': sourceValue,
              'target': targetValue,
              'status': 'modified',
              'path': currentPath,
            };
          }
        }
      }

      // 检查只在目标文档中存在的字段
      for (var key in target.keys) {
        final currentPath = path.isEmpty ? key : '$path.$key';

        // 跳过_id字段
        if (key == '_id') {
          continue;
        }

        // 检查是否应该忽略此字段
        bool shouldIgnore = false;
        for (var regex in ignoreRegexps) {
          if (regex.hasMatch(currentPath)) {
            shouldIgnore = true;
            break;
          }
        }
        if (shouldIgnore) {
          continue;
        }

        if (!source.containsKey(key)) {
          // 字段只在目标文档中存在
          result[currentPath] = {
            'source': null,
            'target': target[key],
            'status': 'added',
            'path': currentPath,
          };
        }
      }
    }

    // 开始递归比较
    _compareNestedDocuments(sourceDoc, targetDoc, '', diffs);

    return diffs;
  }

  // 比较两个列表是否相等
  bool _areListsEqual(List sourceList, List targetList) {
    if (sourceList.length != targetList.length) {
      return false;
    }

    // 如果列表中的元素是简单类型，可以直接排序后比较
    if (sourceList.isEmpty ||
        (sourceList.first is num ||
            sourceList.first is String ||
            sourceList.first is bool)) {
      try {
        final sortedSource = List.from(sourceList)..sort();
        final sortedTarget = List.from(targetList)..sort();

        for (int i = 0; i < sortedSource.length; i++) {
          if (sortedSource[i] != sortedTarget[i]) {
            return false;
          }
        }
        return true;
      } catch (e) {
        // 如果排序失败，回退到逐个比较
        return false;
      }
    }

    // 对于复杂类型（如Map），需要逐个比较
    // 这里简化处理，认为顺序相同的情况下才相等
    for (int i = 0; i < sourceList.length; i++) {
      final sourceItem = sourceList[i];
      final targetItem = targetList[i];

      if (sourceItem is Map<String, dynamic> &&
          targetItem is Map<String, dynamic>) {
        // 递归比较Map
        final diffs = _compareDocuments(sourceItem, targetItem, null);
        if (diffs.isNotEmpty) {
          return false;
        }
      } else if (sourceItem != targetItem) {
        return false;
      }
    }

    return true;
  }

  // 同步文档差异
  Future<void> syncDocumentDiff(DocumentDiff diff, bool sourceToTarget) async {
    try {
      LogService.instance.info(
        '同步文档差异: ID: ${diff.sourceDocument.id}, 类型: ${diff.diffType}, '
        '方向: ${sourceToTarget ? "源到目标" : "目标到源"}',
      );

      if (diff.diffType == DocumentDiffType.unchanged) {
        // 没有差异，不需要同步
        LogService.instance.info('文档无变化，跳过同步');
        return;
      }

      if (sourceToTarget) {
        // 从源到目标的同步
        switch (diff.diffType) {
          case DocumentDiffType.added:
            // 在目标中创建文档
            LogService.instance.info('在目标中创建文档');
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
              LogService.instance.info('从目标中删除文档');
              await deleteDocument(
                diff.targetDocument!.connectionId,
                diff.targetDocument!.databaseName,
                diff.targetDocument!.collectionName,
                ObjectId.parse(diff.targetDocument!.id),
              );
            } else {
              LogService.instance.warning('目标文档为空，无法删除');
            }
            break;
          case DocumentDiffType.modified:
            // 更新目标中的文档
            if (diff.targetDocument != null) {
              LogService.instance.info('更新目标中的文档');
              await updateDocument(
                diff.targetDocument!.connectionId,
                diff.targetDocument!.databaseName,
                diff.targetDocument!.collectionName,
                ObjectId.parse(diff.targetDocument!.id),
                diff.sourceDocument.data,
              );
            } else {
              LogService.instance.warning('目标文档为空，无法更新');
            }
            break;
          case DocumentDiffType.unchanged:
            // 不需要操作
            LogService.instance.info('文档无变化，不需要操作');
            break;
        }
      } else {
        // 从目标到源的同步
        switch (diff.diffType) {
          case DocumentDiffType.added:
            // 在源中删除文档
            LogService.instance.info('在源中删除文档');
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
              LogService.instance.info('在源中创建文档');
              await insertDocument(
                diff.sourceDocument.connectionId,
                diff.sourceDocument.databaseName,
                diff.sourceDocument.collectionName,
                diff.targetDocument!.data,
              );
            } else {
              LogService.instance.warning('目标文档为空，无法创建');
            }
            break;
          case DocumentDiffType.modified:
            // 更新源中的文档
            if (diff.targetDocument != null) {
              LogService.instance.info('更新源中的文档');
              await updateDocument(
                diff.sourceDocument.connectionId,
                diff.sourceDocument.databaseName,
                diff.sourceDocument.collectionName,
                ObjectId.parse(diff.sourceDocument.id),
                diff.targetDocument!.data,
              );
            } else {
              LogService.instance.warning('目标文档为空，无法更新');
            }
            break;
          case DocumentDiffType.unchanged:
            // 不需要操作
            LogService.instance.info('文档无变化，不需要操作');
            break;
        }
      }

      LogService.instance.info('文档同步完成: ${diff.sourceDocument.id}');
    } catch (e, stackTrace) {
      LogService.instance.error('同步文档差异错误: $e', e, stackTrace);
      rethrow; // 重新抛出异常，让调用者处理
    }
  }

  // 批量同步文档差异
  Future<SyncResult> syncDocumentDiffs(
    List<DocumentDiff> diffs,
    bool sourceToTarget, {
    List<String>? diffTypes,
  }) async {
    try {
      LogService.instance.info(
        '开始批量同步文档差异: 总数: ${diffs.length}, 方向: ${sourceToTarget ? "源到目标" : "目标到源"}',
      );

      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];

      // 过滤要同步的差异类型
      List<DocumentDiff> filteredDiffs = diffs;
      if (diffTypes != null && diffTypes.isNotEmpty) {
        filteredDiffs = diffs
            .where((diff) => diffTypes.contains(diff.status))
            .toList();
        LogService.instance.info('过滤后的差异数量: ${filteredDiffs.length}');
      }

      // 批量同步
      for (var diff in filteredDiffs) {
        try {
          LogService.instance.info(
            '正在同步文档: ${diff.sourceDocument.id}, 类型: ${diff.diffType}',
          );
          await syncDocumentDiff(diff, sourceToTarget);
          successCount++;
          LogService.instance.info('文档同步成功: ${diff.sourceDocument.id}');
        } catch (e, stackTrace) {
          failureCount++;
          final errorMsg = '同步文档 ${diff.sourceDocument.id} 失败: ${e.toString()}';
          errors.add(errorMsg);
          LogService.instance.error(errorMsg, e, stackTrace);
        }
      }

      final result = SyncResult(
        totalCount: filteredDiffs.length,
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
      );

      LogService.instance.info(
        '批量同步完成: 总数: ${result.totalCount}, 成功: ${result.successCount}, '
        '失败: ${result.failureCount}',
      );

      return result;
    } catch (e, stackTrace) {
      LogService.instance.error('批量同步文档差异错误: $e', e, stackTrace);
      rethrow; // 重新抛出异常，让调用者处理
    }
  }

  // 同步字段差异
  Future<void> syncFieldDiff(
    FieldDiff fieldDiff,
    DocumentDiff docDiff,
    bool sourceToTarget,
  ) async {
    if (docDiff.diffType != DocumentDiffType.modified ||
        docDiff.targetDocument == null) {
      throw Exception('只能同步已修改的文档的字段差异');
    }

    // 获取目标文档
    final targetDoc = docDiff.targetDocument!;

    // 创建更新操作
    final Map<String, dynamic> updateData = {};

    if (sourceToTarget) {
      // 从源到目标的同步
      switch (fieldDiff.status) {
        case 'added':
          // 在目标中添加字段
          _setNestedField(
            updateData,
            fieldDiff.fieldPath,
            fieldDiff.sourceValue,
          );
          break;
        case 'removed':
          // 从目标中删除字段
          _setNestedField(updateData, fieldDiff.fieldPath, null);
          break;
        case 'modified':
          // 更新目标中的字段
          _setNestedField(
            updateData,
            fieldDiff.fieldPath,
            fieldDiff.sourceValue,
          );
          break;
      }

      // 执行更新
      await updateDocument(
        targetDoc.connectionId,
        targetDoc.databaseName,
        targetDoc.collectionName,
        ObjectId.parse(targetDoc.id),
        updateData,
      );
    } else {
      // 从目标到源的同步
      switch (fieldDiff.status) {
        case 'added':
          // 在源中删除字段
          _setNestedField(updateData, fieldDiff.fieldPath, null);
          break;
        case 'removed':
          // 在源中添加字段
          _setNestedField(
            updateData,
            fieldDiff.fieldPath,
            fieldDiff.targetValue,
          );
          break;
        case 'modified':
          // 更新源中的字段
          _setNestedField(
            updateData,
            fieldDiff.fieldPath,
            fieldDiff.targetValue,
          );
          break;
      }

      // 执行更新
      await updateDocument(
        docDiff.sourceDocument.connectionId,
        docDiff.sourceDocument.databaseName,
        docDiff.sourceDocument.collectionName,
        ObjectId.parse(docDiff.sourceDocument.id),
        updateData,
      );
    }
  }

  // 设置嵌套字段的值
  void _setNestedField(Map<String, dynamic> data, String path, dynamic value) {
    final parts = path.split('.');

    if (parts.length == 1) {
      // 简单字段
      data[parts[0]] = value;
      return;
    }

    // 嵌套字段
    Map<String, dynamic> current = data;
    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (!current.containsKey(part)) {
        current[part] = <String, dynamic>{};
      }
      current = current[part] as Map<String, dynamic>;
    }

    // 设置最终字段的值
    current[parts.last] = value;
  }
}
