import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../providers/connection_provider.dart';
import '../widgets/loading_indicator.dart';

class ConnectionList extends ConsumerWidget {
  final Function(MongoConnection) onConnectionSelected;
  final Function(MongoConnection) onEditConnection;
  final Function(String) onDeleteConnection;

  const ConnectionList({
    super.key,
    required this.onConnectionSelected,
    required this.onEditConnection,
    required this.onDeleteConnection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsState = ref.watch(connectionsProvider);
    final selectedConnection = ref.watch(selectedConnectionProvider);

    return connectionsState.when(
      data: (connections) {
        if (connections.isEmpty) {
          return const Center(
            child: Text(
              '没有保存的连接\n点击下方的"+"按钮添加新连接',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final connection = connections[index];
            final isSelected = selectedConnection?.id == connection.id;

            return Card(
              elevation: isSelected ? 4 : 1,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: Icon(
                  Icons.storage,
                  color: connection.isConnected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(connection.name),
                subtitle: Text(
                  '${connection.host}:${connection.port}${connection.authDb != null && connection.authDb!.isNotEmpty ? '/${connection.authDb}' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: '编辑连接',
                      onPressed: () => onEditConnection(connection),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: '删除连接',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除连接 "${connection.name}" 吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  onDeleteConnection(connection.id);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                selected: isSelected,
                onTap: () => onConnectionSelected(connection),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: LoadingIndicator(message: '加载连接列表...', size: 32.0),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('加载连接失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
