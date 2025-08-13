import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../models/collection.dart';
import '../models/document.dart';
import '../models/compare_rule.dart';
import '../providers/connection_provider.dart';
import '../providers/rule_provider.dart';
import '../widgets/database_browser.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/loading_indicator.dart';
import '../services/platform_service.dart';
import 'comparison_result_screen.dart';
import 'rule_list_screen.dart';

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
  CompareRule? _selectedRule;

  @override
  void initState() {
    super.initState();
    // 获取已保存的连接
    _loadConnections();
  }

  void _loadConnections() {
    final connectionsState = ref.read(connectionsProvider);
    connectionsState.whenData((connections) {
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
    });
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
        fieldRules: _selectedRule?.fieldRules,
      );

      setState(() {
        _comparisonResults = results;
        _isComparing = false;
      });

      // 导航到比较结果界面
      if (results.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ComparisonResultScreen(
              results: results,
              sourceCollection: '$_sourceDatabase.$_sourceCollection',
              targetCollection: '$_targetDatabase.$_targetCollection',
            ),
          ),
        );
      } else {
        // 如果没有差异，显示提示
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有发现差异')));
      }
    } catch (e) {
      setState(() {
        _error = '比较失败: ${e.toString()}';
        _isComparing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionsState = ref.watch(connectionsProvider);
    final platformService = PlatformService.instance;
    final isSmallScreen = ResponsiveLayoutUtil.isSmallScreen(context);
    final spacing = ResponsiveLayoutUtil.getResponsiveSpacing(context);

    return connectionsState.when(
      data: (connections) {
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
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('前往连接管理'),
                ),
              ],
            ),
          );
        }

        // 响应式布局
        return ResponsiveLayout(
          // 小屏幕布局 - 垂直排列
          small: _buildSmallScreenLayout(
            connectedConnections,
            platformService,
            spacing,
          ),

          // 中等屏幕和大屏幕布局 - 水平排列
          medium: _buildLargeScreenLayout(
            connectedConnections,
            platformService,
            spacing,
          ),

          // 大屏幕布局与中等屏幕相同，但可能有不同的间距
          large: null,
        );
      },
      loading: () => const Center(
        child: LoadingIndicator(message: '加载连接信息...', size: 40.0),
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
              onPressed: () {
                ref.read(connectionsProvider.notifier).refreshConnections();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  // 小屏幕布局
  Widget _buildSmallScreenLayout(
    List<MongoConnection> connectedConnections,
    PlatformService platformService,
    double spacing,
  ) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 连接选择区域
              _buildConnectionSelector(
                '源数据库',
                _sourceConnection,
                connectedConnections,
                _handleSourceConnectionChanged,
              ),
              SizedBox(height: spacing),

              // 源数据库浏览器
              Card(
                elevation: platformService.getPlatformElevation(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(spacing),
                      child: Text(
                        '源数据库: ${_sourceConnection?.name ?? "未选择"}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 200,
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
              SizedBox(height: spacing),

              // 目标连接选择
              _buildConnectionSelector(
                '目标数据库',
                _targetConnection,
                connectedConnections,
                _handleTargetConnectionChanged,
              ),
              SizedBox(height: spacing),

              // 目标数据库浏览器
              Card(
                elevation: platformService.getPlatformElevation(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(spacing),
                      child: Text(
                        '目标数据库: ${_targetConnection?.name ?? "未选择"}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 200,
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
              SizedBox(height: spacing),

              // 比较规则选择区域
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('比较规则:', style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(height: spacing / 2),
                  _buildRuleSelector(),
                  SizedBox(height: spacing / 2),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RuleListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.rule),
                      label: const Text('管理规则'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),

              // 比较操作区域
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isComparing
                      ? null
                      : (_sourceCollection != null && _targetCollection != null)
                      ? _compareCollections
                      : null,
                  icon: _isComparing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.compare_arrows),
                  label: const Text('比较集合'),
                ),
              ),

              // 错误信息
              if (_error != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 大屏幕布局
  Widget _buildLargeScreenLayout(
    List<MongoConnection> connectedConnections,
    PlatformService platformService,
    double spacing,
  ) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          children: [
            // 连接选择区域
            Row(
              children: [
                Expanded(
                  child: _buildConnectionSelector(
                    '源数据库',
                    _sourceConnection,
                    connectedConnections,
                    _handleSourceConnectionChanged,
                  ),
                ),
                SizedBox(width: spacing),
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
            SizedBox(height: spacing),

            // 数据库浏览器区域
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 源数据库浏览器
                  Expanded(
                    child: Card(
                      elevation: platformService.getPlatformElevation(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(spacing),
                            child: Text(
                              '源数据库: ${_sourceConnection?.name ?? "未选择"}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Divider(height: 1),
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
                  SizedBox(width: spacing),

                  // 目标数据库浏览器
                  Expanded(
                    child: Card(
                      elevation: platformService.getPlatformElevation(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(spacing),
                            child: Text(
                              '目标数据库: ${_targetConnection?.name ?? "未选择"}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Divider(height: 1),
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
            SizedBox(height: spacing),

            // 比较规则选择区域
            Card(
              elevation: platformService.getPlatformElevation(),
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: Row(
                  children: [
                    Text(
                      '比较规则:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(width: spacing),
                    Expanded(child: _buildRuleSelector()),
                    SizedBox(width: spacing),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RuleListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.rule),
                      label: const Text('管理规则'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing),

            // 比较操作区域
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isComparing
                      ? null
                      : (_sourceCollection != null && _targetCollection != null)
                      ? _compareCollections
                      : null,
                  icon: _isComparing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.compare_arrows),
                  label: const Text('比较集合'),
                ),
              ],
            ),

            // 错误信息
            if (_error != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: spacing / 2),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
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

  Widget _buildRuleSelector() {
    final rules = ref.watch(rulesProvider);

    return DropdownButtonFormField<String>(
      value: _selectedRule?.id,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        hintText: '选择比较规则（可选）',
      ),
      items: [
        const DropdownMenuItem<String>(value: '', child: Text('不使用规则')),
        ...rules.map((rule) {
          return DropdownMenuItem<String>(
            value: rule.id,
            child: Text(rule.name),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          if (value == null || value.isEmpty) {
            _selectedRule = null;
          } else {
            _selectedRule = rules.firstWhere((rule) => rule.id == value);
          }
        });
      },
    );
  }
}
