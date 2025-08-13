import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../providers/connection_provider.dart';
import '../widgets/connection_form.dart';
import '../widgets/connection_list.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/loading_indicator.dart';
import '../services/platform_service.dart';

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
    // 刷新连接列表
    _refreshConnections();
  }

  void _refreshConnections() {
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

  // 构建加载状态的连接列表
  Widget _buildConnectionListWithLoading() {
    return Consumer(
      builder: (context, ref, child) {
        final connectionsState = ref.watch(connectionsProvider);

        return connectionsState.when(
          data: (_) => ConnectionList(
            onConnectionSelected: _handleConnectionSelected,
            onEditConnection: _handleEditConnection,
            onDeleteConnection: _handleDeleteConnection,
          ),
          loading: () => Column(
            children: [
              Expanded(
                child: LoadingIndicator(message: '加载连接列表...', size: 32.0),
              ),
            ],
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshConnections,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final platformService = PlatformService.instance;
    final padding = platformService.getPlatformPadding();
    final isLargeScreen = ResponsiveLayoutUtil.isLargeScreen(context);
    final isMediumScreen = ResponsiveLayoutUtil.isMediumScreen(context);

    // 响应式布局
    return ResponsiveLayout(
      // 小屏幕布局 - 垂直排列
      small: Scaffold(
        body: Column(
          children: [
            // 连接表单/详情区域
            Expanded(
              flex: 2,
              child: Card(
                margin: EdgeInsets.all(
                  ResponsiveLayoutUtil.getResponsiveSpacing(context) / 2,
                ),
                elevation: platformService.getPlatformElevation(),
                child: Padding(padding: padding, child: _buildConnectionForm()),
              ),
            ),

            // 连接列表区域
            Expanded(
              flex: 3,
              child: Card(
                margin: EdgeInsets.all(
                  ResponsiveLayoutUtil.getResponsiveSpacing(context) / 2,
                ),
                elevation: platformService.getPlatformElevation(),
                child: Padding(
                  padding: padding,
                  child: _buildConnectionListWithLoading(),
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
      ),

      // 中等屏幕和大屏幕布局 - 水平排列
      medium: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 连接列表区域
            Expanded(
              flex: 2,
              child: Card(
                margin: EdgeInsets.all(
                  ResponsiveLayoutUtil.getResponsiveSpacing(context),
                ),
                elevation: platformService.getPlatformElevation(),
                child: Padding(
                  padding: padding,
                  child: _buildConnectionListWithLoading(),
                ),
              ),
            ),

            // 连接表单/详情区域
            Expanded(
              flex: 3,
              child: Card(
                margin: EdgeInsets.all(
                  ResponsiveLayoutUtil.getResponsiveSpacing(context),
                ),
                elevation: platformService.getPlatformElevation(),
                child: Padding(padding: padding, child: _buildConnectionForm()),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _handleAddConnection,
          tooltip: '添加新连接',
          child: const Icon(Icons.add),
        ),
      ),

      // 大屏幕布局与中等屏幕相同，但可能有不同的间距
      large: null,
    );
  }
}
