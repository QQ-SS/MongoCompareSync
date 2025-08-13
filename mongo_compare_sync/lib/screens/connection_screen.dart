import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../providers/connection_provider.dart';
import '../widgets/connection_form.dart';
import '../widgets/connection_list.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  MongoConnection? _selectedConnection;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // 初始化Hive和ConnectionRepository
    _initRepository();
  }

  Future<void> _initRepository() async {
    final repository = ref.read(connectionRepositoryProvider);
    await repository.init();
    // 刷新连接列表
    ref.read(connectionsProvider.notifier).refreshConnections();
  }

  void _handleConnectionSelected(MongoConnection connection) {
    setState(() {
      _selectedConnection = connection;
      _isEditing = false;
    });
    // 更新全局选中的连接
    ref.read(selectedConnectionProvider.notifier).state = connection;
  }

  void _handleEditConnection(MongoConnection connection) {
    setState(() {
      _selectedConnection = connection;
      _isEditing = true;
    });
  }

  void _handleDeleteConnection(String id) {
    ref.read(connectionsProvider.notifier).deleteConnection(id);
    if (_selectedConnection?.id == id) {
      setState(() {
        _selectedConnection = null;
        _isEditing = false;
      });
      ref.read(selectedConnectionProvider.notifier).state = null;
    }
  }

  void _handleAddConnection() {
    setState(() {
      _selectedConnection = null;
      _isEditing = true;
    });
  }

  Widget _buildConnectionForm() {
    if (_isEditing) {
      return ConnectionForm(initialConnection: _selectedConnection);
    } else if (_selectedConnection != null) {
      // 显示连接详情
      return _buildConnectionDetails();
    } else {
      return const Center(
        child: Text(
          '选择一个连接或点击"+"按钮添加新连接',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildConnectionDetails() {
    final connection = _selectedConnection!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(connection.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('主机', '${connection.host}:${connection.port}'),
                if (connection.username != null &&
                    connection.username!.isNotEmpty)
                  _buildDetailRow('用户名', connection.username!),
                if (connection.authDb != null && connection.authDb!.isNotEmpty)
                  _buildDetailRow('认证数据库', connection.authDb!),
                _buildDetailRow('SSL', connection.useSsl == true ? '启用' : '禁用'),
                _buildDetailRow('状态', connection.isConnected ? '已连接' : '未连接'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('编辑'),
            ),
            ElevatedButton.icon(
              onPressed: connection.isConnected
                  ? () async {
                      try {
                        await ref
                            .read(connectionRepositoryProvider)
                            .disconnect(connection.id);
                        // 刷新连接列表
                        ref
                            .read(connectionsProvider.notifier)
                            .refreshConnections();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('断开连接失败: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  : () async {
                      try {
                        await ref
                            .read(connectionRepositoryProvider)
                            .connect(connection.id);
                        // 刷新连接列表
                        ref
                            .read(connectionsProvider.notifier)
                            .refreshConnections();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('连接失败: ${e.toString()}')),
                          );
                        }
                      }
                    },
              icon: Icon(connection.isConnected ? Icons.link_off : Icons.link),
              label: Text(connection.isConnected ? '断开' : '连接'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 连接表单/详情区域
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildConnectionForm(),
              ),
            ),
          ),

          // 连接列表区域
          Expanded(
            flex: 3,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConnectionList(
                  onConnectionSelected: _handleConnectionSelected,
                  onEditConnection: _handleEditConnection,
                  onDeleteConnection: _handleDeleteConnection,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddConnection,
        tooltip: '添加新连接',
        child: const Icon(Icons.add),
      ),
    );
  }
}
