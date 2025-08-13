import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/skeleton_loader.dart';
import '../services/platform_service.dart';
import '../services/log_service.dart';
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

    // 注册快捷键
    _registerShortcuts();
  }

  @override
  void dispose() {
    // 清理快捷键
    _unregisterShortcuts();
    super.dispose();
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

  // 注册平台特定的快捷键
  void _registerShortcuts() {
    final platformService = PlatformService.instance;

    // 比较快捷键 (Ctrl+Enter 或 Cmd+Enter)
    final compareShortcut = LogicalKeySet(
      platformService.isMacOS
          ? LogicalKeyboardKey.meta
          : LogicalKeyboardKey.control,
      LogicalKeyboardKey.enter,
    );

    // 添加快捷键处理
    ServicesBinding.instance.keyboard.addHandler((event) {
      if (compareShortcut.accepts(event, HardwareKeyboard.instance)) {
        if (_sourceCollection != null &&
            _targetCollection != null &&
            !_isComparing) {
          _compareCollections();
          return true;
        }
      }
      return false;
    });
  }

  // 清理快捷键
  void _unregisterShortcuts() {
    // 移除快捷键处理
    ServicesBinding.instance.keyboard.removeHandler((event) => false);
  }

  // 构建快捷键提示
  Widget _buildShortcutHint(PlatformService platformService) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              Icons.keyboard,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '快捷键: ${platformService.isMacOS ? "⌘ + Enter 执行比较" : "Ctrl + Enter 执行比较"}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建比较结果预览
  Widget _buildComparisonResultPreview(
    PlatformService platformService,
    double spacing,
  ) {
    if (_comparisonResults == null || _comparisonResults!.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalDiffs = _comparisonResults!.length;
    final addedCount = _comparisonResults!
        .where((diff) => diff.status == 'added')
        .length;
    final removedCount = _comparisonResults!
        .where((diff) => diff.status == 'removed')
        .length;
    final modifiedCount = _comparisonResults!
        .where((diff) => diff.status == 'modified')
        .length;

    return Card(
      elevation: platformService.getPlatformElevation(),
      margin: EdgeInsets.symmetric(vertical: spacing),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('比较结果摘要', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ComparisonResultScreen(
                          results: _comparisonResults!,
                          sourceCollection:
                              '$_sourceDatabase.$_sourceCollection',
                          targetCollection:
                              '$_targetDatabase.$_targetCollection',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('查看详情'),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总差异', totalDiffs, Colors.blue),
                _buildStatItem('新增', addedCount, Colors.green),
                _buildStatItem('删除', removedCount, Colors.red),
                _buildStatItem('修改', modifiedCount, Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建统计项
  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
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
      LogService.instance.error('比较集合失败', e);
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
          return Scaffold(
            body: Center(
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
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoadingIndicator(message: '加载连接信息...', size: 40.0),
              const SizedBox(height: 16),
              Text(
                '正在加载数据库连接...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
      error: (err, stackTrace) {
        // 记录错误
        LogService.instance.error('Failed to load connections', err);

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('加载连接失败', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    err.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(connectionsProvider.notifier).refreshConnections();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      },
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
              // 快捷键提示
              _buildShortcutHint(platformService),
              SizedBox(height: spacing),

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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '源数据库: ${_sourceConnection?.name ?? "未选择"}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (_sourceDatabase != null &&
                              _sourceCollection != null)
                            Chip(
                              label: Text(
                                '$_sourceDatabase.$_sourceCollection',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontSize: 12,
                              ),
                            ),
                        ],
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
                              selectedDatabase: _sourceDatabase,
                              selectedCollection: _sourceCollection,
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '目标数据库: ${_targetConnection?.name ?? "未选择"}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (_targetDatabase != null &&
                              _targetCollection != null)
                            Chip(
                              label: Text(
                                '$_targetDatabase.$_targetCollection',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                                fontSize: 12,
                              ),
                            ),
                        ],
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
                              selectedDatabase: _targetDatabase,
                              selectedCollection: _targetCollection,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '比较规则:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
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
                ),
              ),
              SizedBox(height: spacing),

              // 比较操作区域
              Card(
                elevation: platformService.getPlatformElevation(),
                child: Padding(
                  padding: EdgeInsets.all(spacing),
                  child: Column(
                    children: [
                      // 比较按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isComparing
                              ? null
                              : (_sourceCollection != null &&
                                    _targetCollection != null)
                              ? _compareCollections
                              : null,
                          icon: _isComparing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.compare_arrows),
                          label: Text(_isComparing ? '正在比较...' : '比较集合'),
                        ),
                      ),

                      // 选择状态提示
                      if (_sourceCollection == null ||
                          _targetCollection == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '请先选择源和目标集合',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      // 快捷键提示
                      if (_sourceCollection != null &&
                          _targetCollection != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            platformService.isMacOS
                                ? '快捷键: ⌘ + Enter'
                                : '快捷键: Ctrl + Enter',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 错误信息
              if (_error != null)
                Card(
                  elevation: platformService.getPlatformElevation(),
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withOpacity(0.2),
                  margin: EdgeInsets.symmetric(vertical: spacing),
                  child: Padding(
                    padding: EdgeInsets.all(spacing),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '错误',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 比较结果预览
              if (_comparisonResults != null && _comparisonResults!.isNotEmpty)
                _buildComparisonResultPreview(platformService, spacing),
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
            // 快捷键提示
            _buildShortcutHint(platformService),
            SizedBox(height: spacing),

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
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '源数据库: ${_sourceConnection?.name ?? "未选择"}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                if (_sourceDatabase != null &&
                                    _sourceCollection != null)
                                  Chip(
                                    label: Text(
                                      '$_sourceDatabase.$_sourceCollection',
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    labelStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
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
                                    selectedDatabase: _sourceDatabase,
                                    selectedCollection: _sourceCollection,
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
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '目标数据库: ${_targetConnection?.name ?? "未选择"}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                if (_targetDatabase != null &&
                                    _targetCollection != null)
                                  Chip(
                                    label: Text(
                                      '$_targetDatabase.$_targetCollection',
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                    labelStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
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
                                    selectedDatabase: _targetDatabase,
                                    selectedCollection: _targetCollection,
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

            // 底部操作区域
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 比较规则选择区域
                Expanded(
                  child: Card(
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
                ),

                SizedBox(width: spacing),

                // 比较操作区域
                Card(
                  elevation: platformService.getPlatformElevation(),
                  child: Padding(
                    padding: EdgeInsets.all(spacing),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isComparing
                              ? null
                              : (_sourceCollection != null &&
                                    _targetCollection != null)
                              ? _compareCollections
                              : null,
                          icon: _isComparing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.compare_arrows),
                          label: Text(_isComparing ? '正在比较...' : '比较集合'),
                        ),

                        if (_sourceCollection == null ||
                            _targetCollection == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '请先选择源和目标集合',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 错误信息
            if (_error != null)
              Card(
                elevation: platformService.getPlatformElevation(),
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withOpacity(0.2),
                margin: EdgeInsets.only(top: spacing),
                child: Padding(
                  padding: EdgeInsets.all(spacing),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 比较结果预览
            if (_comparisonResults != null && _comparisonResults!.isNotEmpty)
              _buildComparisonResultPreview(platformService, spacing),
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
