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
  final VoidCallback? onCollectionsLoaded; // 添加回调函数，当集合加载完成时通知父组件

  const DatabaseCollectionPanel({
    super.key,
    required this.connection,
    required this.type,
    this.onDragStart,
    this.onDragAccept,
    required this.onBindingCheck,
    this.onCollectionsLoaded, // 添加回调函数参数
  });

  @override
  DatabaseCollectionPanelState createState() => DatabaseCollectionPanelState();
}

class DatabaseCollectionPanelState
    extends ConsumerState<DatabaseCollectionPanel> {
  Map<String, List<String>?> _databases = {};
  bool _isLoading = false;
  String? _error;
  final Map<String, ValueKey> _nodeKeys = {};
  final Set<String> _loadingCollections = {};
  // 存储数据库的收缩状态，true表示收缩，false表示展开
  final Map<String, bool> _databaseCollapsedState = {};

  Map<String, ValueKey> get nodeKeys => _nodeKeys;
  Map<String, ValueKey> getNodeKeys() => _nodeKeys;

  // 判断数据库是否处于收缩状态
  bool isDatabaseCollapsed(String database) =>
      _databaseCollapsedState[database] ?? true;

  // 展开指定数据库
  void expandDatabase(String database) {
    if (_databaseCollapsedState[database] ?? true) {
      setState(() {
        _databaseCollapsedState[database] = false;
      });

      // 如果集合尚未加载，则加载集合
      if (_databases.containsKey(database) && _databases[database] == null) {
        _loadCollections(database);
      }
    }
  }

  // 滚动到指定集合
  void scrollToCollection(String database, String collection) {
    // 确保数据库已展开
    expandDatabase(database);

    // 获取集合的key
    final collectionKey = '$database.$collection';
    final valueKey = _nodeKeys[collectionKey];

    if (valueKey != null) {
      // 使用延迟确保UI已更新
      Future.delayed(const Duration(milliseconds: 100), () {
        // 查找具有该key的BuildContext
        BuildContext? context = _findContextForKey(valueKey);
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5, // 居中显示
          );
        }
      });
    }
  }

  // 查找具有指定key的BuildContext
  BuildContext? _findContextForKey(ValueKey key) {
    BuildContext? result;

    void visitor(Element element) {
      if (element.widget.key == key) {
        result = element;
        return;
      }
      element.visitChildren(visitor);
    }

    // 从当前上下文开始访问
    (context as Element).visitChildElements(visitor);

    return result;
  }

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
    await Future.microtask(() {
      setState(() {
        _loadingCollections.add(database);
      });
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

        // 通知父组件集合已加载完成，需要重绘连接线
        if (widget.onCollectionsLoaded != null) {
          // 使用 WidgetsBinding 确保在下一帧绘制
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCollectionsLoaded!();
          });
        }
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
        if (!_nodeKeys.containsKey(database)) {
          _nodeKeys[database] = PageStorageKey(database);
        }

        return ExpansionTile(
          key: _nodeKeys[database], // 使用存储的GlobalKey
          maintainState: true, // 保持状态
          leading: const Icon(Icons.folder_open), // 使用包含GlobalKey的图标Widget
          title: Text(database),
          // 绑定展开状态
          initiallyExpanded: _databaseCollapsedState[database] ?? false,
          subtitle: collections == null
              ? null // 当集合未加载时不显示副标题
              : Text('${collections.length} 个集合'),
          onExpansionChanged: (isExpanded) async {
            print(
              'ExpansionTile onExpansionChanged: $database, isExpanded: $isExpanded, collections: $collections',
            );
            await Future.microtask(() {
              setState(() {
                _databaseCollapsedState[database] = !isExpanded;
              });
            });
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
    // 修改key的命名方式，使用 数据库名.集合名 作为key
    final key = '$database.$collection';
    if (!_nodeKeys.containsKey(key)) {
      _nodeKeys[key] = ValueKey(key);
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
      key: _nodeKeys[key],
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
