import 'package:mongo_dart/mongo_dart.dart';
import '../models/document.dart';
import '../models/compare_rule.dart';
import '../services/mongo_service.dart';

class DocumentRepository {
  final MongoService _mongoService;

  // 缓存文档数据
  final Map<String, List<MongoDocument>> _documentsCache = {};

  // 单例模式
  static DocumentRepository? _instance;

  factory DocumentRepository({required MongoService mongoService}) {
    _instance ??= DocumentRepository._internal(mongoService);
    return _instance!;
  }

  DocumentRepository._internal(this._mongoService);

  // 获取集合中的文档列表
  Future<List<MongoDocument>> getDocuments(
    String connectionId,
    String databaseName,
    String collectionName, {
    int limit = 100,
    int skip = 0,
    Map<String, dynamic>? query,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '$connectionId:$databaseName:$collectionName:$skip:$limit:${query ?? '{}'}';

    // 如果不强制刷新且缓存中有数据，则返回缓存数据
    if (!forceRefresh && _documentsCache.containsKey(cacheKey)) {
      return _documentsCache[cacheKey]!;
    }

    // 从服务获取文档列表
    final documents = await _mongoService.getDocuments(
      connectionId,
      databaseName,
      collectionName,
      limit: limit,
      skip: skip,
      query: query,
    );

    // 更新缓存
    _documentsCache[cacheKey] = documents;

    return documents;
  }

  // 插入文档
  Future<void> insertDocument(
    String connectionId,
    String databaseName,
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    await _mongoService.insertDocument(
      connectionId,
      databaseName,
      collectionName,
      data,
    );

    // 清除相关缓存
    clearCollectionCache(connectionId, databaseName, collectionName);
  }

  // 更新文档
  Future<void> updateDocument(
    String connectionId,
    String databaseName,
    String collectionName,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _mongoService.updateDocument(
      connectionId,
      databaseName,
      collectionName,
      ObjectId.parse(documentId),
      data,
    );

    // 清除相关缓存
    clearCollectionCache(connectionId, databaseName, collectionName);
  }

  // 删除文档
  Future<void> deleteDocument(
    String connectionId,
    String databaseName,
    String collectionName,
    String documentId,
  ) async {
    await _mongoService.deleteDocument(
      connectionId,
      databaseName,
      collectionName,
      ObjectId.parse(documentId),
    );

    // 清除相关缓存
    clearCollectionCache(connectionId, databaseName, collectionName);
  }

  // 比较两个集合的文档
  Future<List<DocumentDiff>> compareCollections(
    String sourceConnectionId,
    String sourceDatabaseName,
    String sourceCollectionName,
    String targetConnectionId,
    String targetDatabaseName,
    String targetCollectionName, {
    CompareRule? compareRule,
  }) async {
    // 提取需要忽略的字段
    List<String>? ignoreFields;
    if (compareRule != null) {
      ignoreFields = compareRule.fieldRules
          .where((rule) => rule.ruleType == RuleType.ignore)
          .map((rule) => rule.fieldPath)
          .toList();
    }

    // 使用服务比较集合
    return _mongoService.compareCollections(
      sourceConnectionId,
      sourceDatabaseName,
      sourceCollectionName,
      targetConnectionId,
      targetDatabaseName,
      targetCollectionName,
      ignoreFields: ignoreFields,
    );
  }

  // 同步文档差异
  Future<void> syncDocumentDiff(DocumentDiff diff, bool sourceToTarget) async {
    await _mongoService.syncDocumentDiff(diff, sourceToTarget);

    // 清除相关缓存
    if (sourceToTarget && diff.targetDocument != null) {
      clearCollectionCache(
        diff.targetDocument!.connectionId,
        diff.targetDocument!.databaseName,
        diff.targetDocument!.collectionName,
      );
    } else {
      clearCollectionCache(
        diff.sourceDocument.connectionId,
        diff.sourceDocument.databaseName,
        diff.sourceDocument.collectionName,
      );
    }
  }

  // 清除指定集合的缓存
  void clearCollectionCache(
    String connectionId,
    String databaseName,
    String collectionName,
  ) {
    final prefix = '$connectionId:$databaseName:$collectionName:';
    _documentsCache.removeWhere((key, _) => key.startsWith(prefix));
  }

  // 清除指定连接的缓存
  void clearConnectionCache(String connectionId) {
    _documentsCache.removeWhere((key, _) => key.startsWith('$connectionId:'));
  }

  // 清除所有缓存
  void clearAllCache() {
    _documentsCache.clear();
  }
}
