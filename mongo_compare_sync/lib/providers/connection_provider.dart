import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../repositories/connection_repository.dart';
import '../services/mongo_service.dart';

// MongoDB服务提供者
final mongoServiceProvider = Provider<MongoService>((ref) {
  return MongoService();
});

// 连接存储库提供者
final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  final mongoService = ref.watch(mongoServiceProvider);
  return ConnectionRepository(mongoService: mongoService);
});

// 连接列表提供者
final connectionsProvider =
    StateNotifierProvider<ConnectionsNotifier, List<MongoConnection>>((ref) {
      final repository = ref.watch(connectionRepositoryProvider);
      return ConnectionsNotifier(repository);
    });

// 当前选中的连接提供者
final selectedConnectionProvider = StateProvider<MongoConnection?>(
  (ref) => null,
);

// 连接状态提供者
final connectionStateProvider = StateProvider<ConnectionState>(
  (ref) => ConnectionState.disconnected,
);

// 连接状态枚举
enum ConnectionState { connecting, connected, disconnected, error }

// 连接列表状态管理
class ConnectionsNotifier extends StateNotifier<List<MongoConnection>> {
  final ConnectionRepository _repository;

  ConnectionsNotifier(this._repository) : super([]) {
    _loadConnections();
  }

  // 加载所有保存的连接
  Future<void> _loadConnections() async {
    final connections = _repository.getAllConnections();
    state = connections;
  }

  // 刷新连接列表
  Future<void> refreshConnections() async {
    _loadConnections();
  }

  // 添加新连接
  Future<void> addConnection(MongoConnection connection) async {
    await _repository.saveConnection(connection);
    state = [...state, connection];
  }

  // 更新连接
  Future<void> updateConnection(MongoConnection connection) async {
    await _repository.saveConnection(connection);
    state = [
      for (final conn in state)
        if (conn.id == connection.id) connection else conn,
    ];
  }

  // 删除连接
  Future<void> deleteConnection(String id) async {
    await _repository.deleteConnection(id);
    state = state.where((conn) => conn.id != id).toList();
  }

  // 测试连接
  Future<bool> testConnection(MongoConnection connection) async {
    try {
      // 保存连接以便测试
      final savedConnection = await _repository.saveConnection(connection);
      // 尝试连接
      await _repository.connect(savedConnection.id);
      // 连接成功后断开
      await _repository.disconnect(savedConnection.id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
