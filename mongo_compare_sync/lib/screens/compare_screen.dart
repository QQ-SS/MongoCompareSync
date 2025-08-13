import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../models/collection.dart';
import '../models/document.dart';
import '../providers/connection_provider.dart';
import '../widgets/database_browser.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  MongoConnection? _sourceConnection;
  MongoConnection? _targetConnection;
  String? _sourceDatabase;
  String? _targetDatabase;
  String? _sourceCollection;
  String? _targetCollection;
  bool _isComparing = false;
  String? _error;
  List<DocumentDiff>? _comparisonResults;

  @override
  void initState() {
    super.initState();
    // 获取已保存的连接
    _loadConnections();
  }

  void _loadConnections() {
    final connections = ref.read(connectionsProvider);
    if (connections.isNotEmpty) {
      setState(() {
        _sourceConnection = connections.first;
      });

      if (connections.length > 1) {
        setState(() {
          _targetConnection = connections[1];
        });
      }
    }
  }

  void _handleSourceConnectionChanged(MongoConnection? connection) {
    setState(() {
      _sourceConnection = connection;
      _sourceDatabase = null;
      _sourceCollection = null;
    });
  }

  void _handleTargetConnectionChanged(MongoConnection? connection) {
    setState(() {
      _targetConnection = connection;
      _targetDatabase = null;
      _targetCollection = null;
    });
  }

  void _handleSourceCollectionSelected(String database, String collection) {
    setState(() {
      _sourceDatabase = database;
      _sourceCollection = collection;
    });
  }

  void _handleTargetCollectionSelected(String database, String collection) {
    setState(() {
      _targetDatabase = database;
      _targetCollection = collection;
    });
  }

  Future<void> _compareCollections() async {
    if (_sourceConnection == null ||
        _targetConnection == null ||
        _sourceDatabase == null ||
        _targetDatabase == null ||
        _sourceCollection == null ||
        _targetCollection == null) {
      setState(() {
        _error = '请选择源和目标集合';
      });
      return;
    }

    setState(() {
      _isComparing = true;
      _error = null;
      _comparisonResults = null;
    });

    try {
      final mongoService = ref.read(mongoServiceProvider);
      final results = await mongoService.compareCollections(
        _sourceConnection!.id,
        _sourceDatabase!,
        _sourceCollection!,
        _targetConnection!.id,
        _targetDatabase!,
        _targetCollection!,
      );

      setState(() {
        _comparisonResults = results;
        _isComparing = false;
      });
    } catch (e) {
      setState(() {
        _error = '比较失败: ${e.toString()}';
        _isComparing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connections = ref.watch(connectionsProvider);
    final connectedConnections = connections
        .where((conn) => conn.isConnected)
        .toList();

    if (connectedConnections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              '没有活跃的数据库连接',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '请先在连接管理页面连接至少一个数据库',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // 切换到连接管理页面
                // 这里我们假设HomeScreen使用BottomNavigationBar，索引0是连接管理页面
                // 实际实现可能需要根据导航结构调整
                // 这里使用简单的方式，通过全局状态管理来切换页面
                // 在实际应用中，可能需要使用更复杂的导航管理
                // 例如使用GoRouter或AutoRoute等路由管理库
                // 或者使用Provider来管理当前选中的页面索引
                // 这里我们简单地使用Navigator来导航回上一页
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.link),
              label: const Text('前往连接管理'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // 连接选择区域
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildConnectionSelector(
                    '源数据库',
                    _sourceConnection,
                    connectedConnections,
                    _handleSourceConnectionChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildConnectionSelector(
                    '目标数据库',
                    _targetConnection,
                    connectedConnections,
                    _handleTargetConnectionChanged,
                  ),
                ),
              ],
            ),
          ),

          // 数据库浏览器区域
          Expanded(
            child: Row(
              children: [
                // 源数据库浏览器
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '源数据库: ${_sourceConnection?.name ?? "未选择"}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: _sourceConnection == null
                              ? const Center(child: Text('请选择源数据库连接'))
                              : DatabaseBrowser(
                                  connection: _sourceConnection!,
                                  onCollectionSelected:
                                      _handleSourceCollectionSelected,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 目标数据库浏览器
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '目标数据库: ${_targetConnection?.name ?? "未选择"}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: _targetConnection == null
                              ? const Center(child: Text('请选择目标数据库连接'))
                              : DatabaseBrowser(
                                  connection: _targetConnection!,
                                  onCollectionSelected:
                                      _handleTargetCollectionSelected,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 比较操作区域
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isComparing
                      ? null
                      : (_sourceCollection != null && _targetCollection != null)
                      ? _compareCollections
                      : null,
                  icon: _isComparing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.compare_arrows),
                  label: const Text('比较集合'),
                ),
              ],
            ),
          ),

          // 比较结果区域（暂时只显示简单的结果信息）
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else if (_comparisonResults != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '比较完成: 发现 ${_comparisonResults!.length} 个差异',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionSelector(
    String label,
    MongoConnection? selectedConnection,
    List<MongoConnection> connections,
    Function(MongoConnection?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedConnection?.id,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          items: connections.map((conn) {
            return DropdownMenuItem<String>(
              value: conn.id,
              child: Text(conn.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final connection = connections.firstWhere(
                (conn) => conn.id == value,
              );
              onChanged(connection);
            }
          },
        ),
      ],
    );
  }
}
