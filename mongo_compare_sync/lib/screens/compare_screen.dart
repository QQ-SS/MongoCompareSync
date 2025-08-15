import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../models/collection.dart';
import '../models/document.dart';
import '../models/compare_rule.dart';
import '../providers/connection_provider.dart' hide ConnectionState;
import '../providers/rule_provider.dart';
import '../widgets/database_browser.dart';
import '../widgets/drag_drop_compare_view.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/skeleton_loader.dart';
import '../services/platform_service.dart';
import '../services/log_service.dart';
import 'comparison_result_screen.dart';
import 'rule_list_screen.dart';
import '../repositories/connection_repository.dart';

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

  List<CollectionBinding> _dragDropBindings = [];

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  void _loadConnections() {
    // 不自动设置连接，让用户手动选择
    // 这样可以避免使用过期的连接ID
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

  void _handleBindingsChanged(List<CollectionBinding> bindings) {
    setState(() {
      _dragDropBindings = bindings;
    });
  }

  void _handleCompareBinding(CollectionBinding binding) {
    _compareSpecificCollections(
      binding.sourceDatabase,
      binding.sourceCollection,
      binding.targetDatabase,
      binding.targetCollection,
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

    await _compareSpecificCollections(
      _sourceDatabase!,
      _sourceCollection!,
      _targetDatabase!,
      _targetCollection!,
    );
  }

  Future<void> _compareSpecificCollections(
    String sourceDatabase,
    String sourceCollection,
    String targetDatabase,
    String targetCollection,
  ) async {
    if (_sourceConnection == null || _targetConnection == null) {
      setState(() {
        _error = '请选择源和目标连接';
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
        sourceDatabase,
        sourceCollection,
        _targetConnection!.id,
        targetDatabase,
        targetCollection,
        fieldRules: _selectedRule?.fieldRules,
      );

      setState(() {
        _comparisonResults = results;
        _isComparing = false;
      });

      if (results.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ComparisonResultScreen(
              results: results,
              sourceCollection: '$sourceDatabase.$sourceCollection',
              targetCollection: '$targetDatabase.$targetCollection',
            ),
          ),
        );
      } else {
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

    return connectionsState.when(
      data: (connections) {
        final allConnections = connections;

        if (allConnections.isEmpty) {
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
                    '没有可用的数据库连接',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '请先在连接管理页面添加至少一个数据库连接',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('前往连接管理'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('集合比较')),
          body: _buildDragDropCompareView(allConnections),
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

  Widget _buildDragDropCompareView(List<MongoConnection> allConnections) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: DragDropCompareView(
              connections: allConnections,
              sourceConnection: _sourceConnection,
              targetConnection: _targetConnection,
              onSourceConnectionChanged: _handleSourceConnectionChanged,
              onTargetConnectionChanged: _handleTargetConnectionChanged,
              onBindingsChanged: _handleBindingsChanged,
              onCompareBinding: _handleCompareBinding,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionDropdown({
    required String label,
    required MongoConnection? selectedConnection,
    required List<MongoConnection> connections,
    required Function(MongoConnection?) onConnectionChanged,
  }) {
    final uniqueConnections = <String, MongoConnection>{};
    for (final conn in connections) {
      uniqueConnections[conn.id] = conn;
    }
    final uniqueConnectionsList = uniqueConnections.values.toList();

    final selectedConnectionExists = selectedConnection == null
        ? false
        : uniqueConnections.containsKey(selectedConnection.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: selectedConnectionExists ? selectedConnection.id : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            hintText: '选择连接',
          ),
          items: uniqueConnectionsList.map((conn) {
            return DropdownMenuItem<String?>(
              value: conn.id,
              child: Text(conn.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final connection = uniqueConnectionsList.firstWhere(
                (conn) => conn.id == value,
                orElse: () => uniqueConnectionsList.first,
              );
              onConnectionChanged(connection);
            } else {
              onConnectionChanged(null);
            }
          },
        ),
      ],
    );
  }
}
