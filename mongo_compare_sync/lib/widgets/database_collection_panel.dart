import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../providers/connection_provider.dart';
import '../services/log_service.dart';
import '../widgets/loading_indicator.dart';

enum PanelType { source, target }

class DatabaseCollectionPanel extends ConsumerStatefulWidget {
  final MongoConnection? connection;
  final PanelType type;
  final Function(String database, String collection, Map<String, String> data)?
  onDragStart;
  final Function(
    String database,
    String collection,
    Map<String, String> sourceData,
  )?
  onDragAccept;
  final Function(String database, String collection) onBindingCheck;

  const DatabaseCollectionPanel({
    super.key,
    required this.connection,
    required this.type,
    this.onDragStart,
    this.onDragAccept,
    required this.onBindingCheck,
  });

  @override
  DatabaseCollectionPanelState createState() => DatabaseCollectionPanelState();
}

class DatabaseCollectionPanelState
    extends ConsumerState<DatabaseCollectionPanel> {
  Map<String, List<String>?> _databases = {};
  bool _isLoading = false;
  String? _error;
  final Map<String, GlobalKey> _collectionKeys = {};
  final Map<String, GlobalKey> _databaseKeys = {}; // 新增：用于存储数据库的GlobalKey
  final Set<String> _loadingCollections = {};

  Map<String, GlobalKey> getCollectionKeys() => _collectionKeys;
  Map<String, GlobalKey> getDatabaseKeys() => _databaseKeys; // 新增：获取数据库Key的方法

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  @override
  void didUpdateWidget(covariant DatabaseCollectionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connection?.id != oldWidget.connection?.id) {
      _loadDatabases();
    }
  }

  Future<void> _loadDatabases() async {
    if (widget.connection == null) {
      setState(() {
        _databases = {};
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mongoService = ref.read(mongoServiceProvider);

      // 确保连接已建立
      final isConnected = await mongoService.connect(widget.connection!);
      if (!isConnected) {
        throw Exception('无法连接到${_getTypeDisplayName()}数据库');
      }

      final databases = await mongoService.getDatabases(widget.connection!.id);
      final Map<String, List<String>?> databaseCollections = {};

      // 只初始化数据库名称，集合列表为null，等待用户点击时加载
      for (final dbName in databases) {
        databaseCollections[dbName] = null;
      }

      if (mounted) {
        setState(() {
          _databases = databaseCollections;
          _isLoading = false;
        });
      }
    } catch (e) {
      LogService.instance.error('加载${_getTypeDisplayName()}数据库失败: $e');
      if (mounted) {
        setState(() {
          _error = '加载${_getTypeDisplayName()}数据库失败: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCollections(String database) async {
    if (_loadingCollections.contains(database)) {
      return; // 避免重复加载
    }

    setState(() {
      _loadingCollections.add(database);
    });

    try {
      final mongoService = ref.read(mongoServiceProvider);
      final collections = await mongoService.getCollections(
        widget.connection!.id,
        database,
      );

      if (mounted) {
        setState(() {
          _databases[database] = collections.map((c) => c.name).toList();
          _loadingCollections.remove(database);
        });
      }
    } catch (e) {
      LogService.instance.error(
        '加载${_getTypeDisplayName()}数据库 $database 的集合失败: $e',
      );
      if (mounted) {
        setState(() {
          _databases[database] = [];
          _loadingCollections.remove(database);
        });
      }
    }
  }

  String _getTypeDisplayName() {
    return widget.type == PanelType.source ? '源' : '目标';
  }

  IconData _getTypeIcon() {
    return widget.type == PanelType.source ? Icons.source : Icons.my_location;
  }

  Color _getTypeColor() {
    return widget.type == PanelType.source
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
  }

  Map<String, GlobalKey> get collectionKeys => _collectionKeys;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 24, // 标准图标宽度
                  height: 24, // 标准图标高度
                  child: Icon(_getTypeIcon(), color: _getTypeColor()),
                ),
                const SizedBox(width: 32), // 与ListTile的默认间距对齐
                Expanded(
                  child: Text(
                    '${_getTypeDisplayName()}集合: ${widget.connection?.name ?? "未选择"}',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildCollectionList()),
        ],
      ),
    );
  }

  Widget _buildCollectionList() {
    if (widget.connection == null) {
      return Center(child: Text('请选择${_getTypeDisplayName()}数据库连接'));
    }

    if (_isLoading) {
      return Center(
        child: LoadingIndicator(
          message: '加载${_getTypeDisplayName()}数据库...',
          size: 24,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadDatabases, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_databases.isEmpty) {
      return const Center(child: Text('没有发现数据库'));
    }

    return ListView(
      children: _databases.entries.map((entry) {
        final database = entry.key;
        final collections = entry.value;

        // 为每个数据库项创建并存储GlobalKey
        if (!_databaseKeys.containsKey(database)) {
          _databaseKeys[database] = GlobalKey();
        }

        return ExpansionTile(
          key: _databaseKeys[database], // 使用存储的GlobalKey
          maintainState: true, // 保持状态
          leading: const Icon(
            Icons.folder_open,
          ), // 默认图标大小24x24，ExpansionTile会处理对齐
          title: Text(database),
          subtitle: Text('${collections?.length ?? 0} 个集合'),
          onExpansionChanged: (isExpanded) {
            print(
              'ExpansionTile onExpansionChanged: $database, isExpanded: $isExpanded, collections: $collections',
            );
            if (isExpanded &&
                collections == null &&
                !_loadingCollections.contains(database)) {
              print('Loading collections for database: $database');
              _loadCollections(database);
            }
          },
          children: _loadingCollections.contains(database)
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingIndicator(message: '加载集合...', size: 16),
                  ),
                ]
              : collections == null || collections.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('暂无集合'),
                  ),
                ]
              : collections.map((collection) {
                  return _buildCollectionItem(database, collection);
                }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildCollectionItem(String database, String collection) {
    final key = '${database}_$collection';
    if (!_collectionKeys.containsKey(key)) {
      _collectionKeys[key] = GlobalKey();
    }

    final isBound = widget.onBindingCheck(database, collection);

    if (widget.type == PanelType.source) {
      return _buildSourceCollectionItem(database, collection, key, isBound);
    } else {
      return _buildTargetCollectionItem(database, collection, key, isBound);
    }
  }

  Widget _buildSourceCollectionItem(
    String database,
    String collection,
    String key,
    bool isBound,
  ) {
    return Draggable<Map<String, String>>(
      data: {'database': database, 'collection': collection, 'type': 'source'},
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$database.$collection',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      childWhenDragging: _buildCollectionContainer(
        key: key,
        collection: collection,
        isBound: isBound,
        isDragging: true,
      ),
      child: _buildCollectionContainer(
        key: key,
        collection: collection,
        isBound: isBound,
        isDragging: false,
      ),
    );
  }

  Widget _buildTargetCollectionItem(
    String database,
    String collection,
    String key,
    bool isBound,
  ) {
    return DragTarget<Map<String, String>>(
      onWillAcceptWithDetails: (details) {
        return details.data['type'] == 'source';
      },
      onAcceptWithDetails: (details) {
        final sourceData = details.data;
        widget.onDragAccept?.call(database, collection, sourceData);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return _buildCollectionContainer(
          key: key,
          collection: collection,
          isBound: isBound,
          isHovered: isHovered,
        );
      },
    );
  }

  Widget _buildCollectionContainer({
    required String key,
    required String collection,
    required bool isBound,
    bool isDragging = false,
    bool isHovered = false,
  }) {
    Color? backgroundColor;
    Border? border;
    Color? textColor;

    if (isDragging) {
      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      border = Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        style: BorderStyle.solid,
      );
      textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    } else if (isHovered) {
      backgroundColor = _getTypeColor().withOpacity(0.7);
      border = Border.all(color: _getTypeColor(), width: 2);
    } else if (isBound) {
      backgroundColor = _getTypeColor().withOpacity(0.3);
      border = Border.all(color: _getTypeColor(), width: 2);
    }

    return Container(
      key: _collectionKeys[key],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24, // 标准图标宽度
            height: 24, // 标准图标高度
            child: Icon(Icons.table_chart, color: textColor ?? _getTypeColor()),
          ),
          const SizedBox(width: 32), // 与ListTile的默认间距对齐
          Expanded(
            child: Text(
              collection,
              style: textColor != null ? TextStyle(color: textColor) : null,
            ),
          ),
          if (isBound)
            Icon(Icons.link, size: 16, color: textColor ?? _getTypeColor()),
        ],
      ),
    );
  }
}
