import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../repositories/connection_repository.dart';
import '../services/mongo_service.dart';
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
    StateNotifierProvider<
      ConnectionsNotifier,
      AsyncValue<List<MongoConnection>>
    >((ref) {
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
class ConnectionsNotifier
    extends StateNotifier<AsyncValue<List<MongoConnection>>> {
  final ConnectionRepository _repository;

  ConnectionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadConnections();
  }

  // 加载所有保存的连接
  Future<void> _loadConnections() async {
    try {
      state = const AsyncValue.loading();
      // 使用异步方法获取连接
      final connections = await Future(() => _repository.getAllConnections());
      // 确保在异步操作完成后更新状态
      if (mounted) {
        state = AsyncValue.data(connections);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  // 刷新连接列表
  Future<void> refreshConnections() async {
    _loadConnections();
  }

  // 添加新连接
  Future<void> addConnection(MongoConnection connection) async {
    try {
      final savedConnection = await _repository.saveConnection(connection);
      // 使用 Future.microtask 确保在 widget 构建完成后更新状态
      await Future.microtask(() {
        if (mounted) {
          state.whenData((connections) {
            state = AsyncValue.data([...connections, savedConnection]);
          });
        }
      });
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  // 更新连接
  Future<void> updateConnection(MongoConnection connection) async {
    try {
      final savedConnection = await _repository.saveConnection(connection);
      // 使用 Future.microtask 确保在 widget 构建完成后更新状态
      await Future.microtask(() {
        if (mounted) {
          state.whenData((connections) {
            state = AsyncValue.data([
              for (final conn in connections)
                if (conn.id == savedConnection.id) savedConnection else conn,
            ]);
          });
        }
      });
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  // 删除连接
  Future<void> deleteConnection(String id) async {
    try {
      await _repository.deleteConnection(id);
      state.whenData((connections) {
        state = AsyncValue.data(
          connections.where((conn) => conn.id != id).toList(),
        );
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
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
