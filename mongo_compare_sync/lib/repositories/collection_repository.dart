import '../models/collection.dart';
import '../models/connection.dart';
import '../services/mongo_service.dart';

class CollectionRepository {
  final MongoService _mongoService;

  // 缓存集合数据
  final Map<String, List<MongoCollection>> _collectionsCache = {};

  // 单例模式
  static CollectionRepository? _instance;

  factory CollectionRepository({required MongoService mongoService}) {
    _instance ??= CollectionRepository._internal(mongoService);
    return _instance!;
  }

  CollectionRepository._internal(this._mongoService);

  // 获取数据库中的集合列表
  Future<List<MongoCollection>> getCollections(
    String connectionId,
    String databaseName, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$connectionId:$databaseName';

    // 如果不强制刷新且缓存中有数据，则返回缓存数据
    if (!forceRefresh && _collectionsCache.containsKey(cacheKey)) {
      return _collectionsCache[cacheKey]!;
    }

    // 从服务获取集合列表
    final collections = await _mongoService.getCollections(
      connectionId,
      databaseName,
    );

    // 更新缓存
    _collectionsCache[cacheKey] = collections;

    return collections;
  }

  // 清除指定连接的缓存
  void clearCache(String connectionId) {
    _collectionsCache.removeWhere((key, _) => key.startsWith('$connectionId:'));
  }

  // 清除所有缓存
  void clearAllCache() {
    _collectionsCache.clear();
  }

  // 获取集合的文档数量
  Future<int> getDocumentCount(
    String connectionId,
    String databaseName,
    String collectionName,
  ) async {
    final cacheKey = '$connectionId:$databaseName';

    // 尝试从缓存中获取集合信息
    if (_collectionsCache.containsKey(cacheKey)) {
      final cachedCollection = _collectionsCache[cacheKey]!.firstWhere(
        (coll) => coll.name == collectionName,
        orElse: () => MongoCollection(
          name: collectionName,
          database: databaseName,
          connectionId: connectionId,
          documentCount: 0,
        ),
      );

      return cachedCollection.documentCount;
    }

    // 如果缓存中没有，则获取集合列表
    await getCollections(connectionId, databaseName);

    // 再次尝试从缓存中获取
    if (_collectionsCache.containsKey(cacheKey)) {
      final cachedCollection = _collectionsCache[cacheKey]!.firstWhere(
        (coll) => coll.name == collectionName,
        orElse: () => MongoCollection(
          name: collectionName,
          database: databaseName,
          connectionId: connectionId,
          documentCount: 0,
        ),
      );

      return cachedCollection.documentCount;
    }

    return 0;
  }
}
