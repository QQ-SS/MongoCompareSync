import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Size;
import '../models/connection.dart';
import '../models/document.dart';
import '../models/collection_compare_result.dart';
import '../screens/document_tree_comparison_screen.dart';
import '../services/mongo_service.dart';
import '../widgets/database_collection_panel.dart';

// 比较结果信息类
class ComparisonResultInfo {
  final bool isCompleted; // 比较是否完成
  final int sameCount; // 相同项数量
  final int diffCount; // 差异项数量

  ComparisonResultInfo({
    required this.isCompleted,
    this.sameCount = 0,
    this.diffCount = 0,
  });
}

class CollectionBinding {
  final String sourceDatabase;
  final String sourceCollection;
  final String targetDatabase;
  final String targetCollection;
  final String id;

  CollectionBinding({
    required this.sourceDatabase,
    required this.sourceCollection,
    required this.targetDatabase,
    required this.targetCollection,
    required this.id,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionBinding &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DragDropCompareView extends ConsumerStatefulWidget {
  final List<MongoConnection> connections;
  final MongoConnection? sourceConnection;
  final MongoConnection? targetConnection;
  final Function(MongoConnection?) onSourceConnectionChanged;
  final Function(MongoConnection?) onTargetConnectionChanged;
  final Function(List<CollectionBinding>) onBindingsChanged;
  final Function(CollectionBinding) onCompareBinding;

  const DragDropCompareView({
    super.key,
    required this.connections,
    required this.sourceConnection,
    required this.targetConnection,
    required this.onSourceConnectionChanged,
    required this.onTargetConnectionChanged,
    required this.onBindingsChanged,
    required this.onCompareBinding,
  });

  @override
  ConsumerState<DragDropCompareView> createState() =>
      _DragDropCompareViewState();
}

class _DragDropCompareViewState extends ConsumerState<DragDropCompareView>
    with TickerProviderStateMixin {
  final List<CollectionBinding> _bindings = [];
  final GlobalKey<DatabaseCollectionPanelState> _sourceKey = GlobalKey();
  final GlobalKey<DatabaseCollectionPanelState> _targetKey = GlobalKey();
  final GlobalKey _painterKey = GlobalKey();
  bool _showBindingsList = false;
  // 存储比较结果，包含状态和详细信息
  Map<String, ComparisonResultInfo> _comparisonResults = {};
  // 存储详细比较结果，用于导航到比较结果页面
  Map<String, CollectionCompareResult> _detailedResults = {};
  // MongoDB服务实例
  final MongoService _mongoService = MongoService();

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                flex: 2,
                child: _buildConnectionDropdown(
                  label: '源连接',
                  selectedConnection: widget.sourceConnection,
                  connections: widget.connections,
                  onConnectionChanged: widget.onSourceConnectionChanged,
                ),
              ),
              const Spacer(flex: 1),
              Flexible(
                flex: 2,
                child: _buildConnectionDropdown(
                  label: '目标连接',
                  selectedConnection: widget.targetConnection,
                  connections: widget.connections,
                  onConnectionChanged: widget.onTargetConnectionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: DatabaseCollectionPanel(
                              key: _sourceKey,
                              connection: widget.sourceConnection,
                              type: PanelType.source,
                              onBindingCheck: _isSourceBound,
                            ),
                          ),
                          const Spacer(flex: 1),
                          Flexible(
                            flex: 2,
                            child: DatabaseCollectionPanel(
                              key: _targetKey,
                              connection: widget.targetConnection,
                              type: PanelType.target,
                              onDragAccept: _createBinding,
                              onBindingCheck: _isTargetBound,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        key: _painterKey,
                        painter: ConnectionLinePainter(
                          bindings: _bindings,
                          sourceKey: _sourceKey,
                          targetKey: _targetKey,
                          context: context,
                          painterRenderBox:
                              _painterKey.currentContext?.findRenderObject()
                                  as RenderBox?,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    ),
                    // 浮动按钮，显示绑定数量
                    if (_bindings.isNotEmpty && !_showBindingsList)
                      Positioned(
                        bottom: 32,
                        right: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton.extended(
                              onPressed: () {
                                setState(() {
                                  _showBindingsList = true;
                                });
                              },
                              icon: const Icon(Icons.link),
                              label: Text(' ${_bindings.length}'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    // 绑定列表，点击浮动按钮后显示
                    if (_bindings.isNotEmpty && _showBindingsList)
                      Positioned(
                        bottom: 32,
                        left: 16,
                        right: 16,
                        child: _buildBindingsList(),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBindingsList() {
    return Card(
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '集合绑定 (${_bindings.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (_bindings.isNotEmpty) ...[
                    Tooltip(
                      message: '将源与目标集合滚动到可见区域',
                      child: TextButton.icon(
                        onPressed: () {
                          if (_bindings.isNotEmpty) {
                            _scrollBindingToVisible(_bindings.first);
                          }
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('滚动到可见区域'),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _compareAllBindings,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('批量比较'),
                    ),
                    TextButton.icon(
                      onPressed: _clearAllBindings,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('清空'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showBindingsList = false;
                        });
                      },
                      tooltip: '关闭',
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _bindings.length,
                itemBuilder: (context, index) {
                  final binding = _bindings[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.compare_arrows,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      '${binding.sourceDatabase}.${binding.sourceCollection}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '→ ${binding.targetDatabase}.${binding.targetCollection}',
                    ),
                    onTap: () => _scrollBindingToVisible(binding),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 显示比较结果文本
                        if (_comparisonResults.containsKey(binding.id) &&
                            _comparisonResults[binding.id]!.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _comparisonResults[binding.id]!.diffCount > 0
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '相同: ${_comparisonResults[binding.id]!.sameCount} | 差异: ${_comparisonResults[binding.id]!.diffCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    _comparisonResults[binding.id]!.diffCount >
                                        0
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        // 显示比较状态的图标
                        if (_comparisonResults.containsKey(binding.id) &&
                            !_comparisonResults[binding.id]!.isCompleted)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        // 滚动到可见区域按钮
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          iconSize: 20,
                          onPressed: () => _scrollBindingToVisible(binding),
                          tooltip: '滚动到可见区域',
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => _compareBinding(binding),
                          tooltip: '执行比较',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeBinding(binding),
                          tooltip: '删除绑定',
                        ),
                        // 查看比较结果按钮
                        IconButton(
                          icon: const Icon(Icons.assessment),
                          iconSize: 20,
                          onPressed: () => _navigateToComparisonResult(binding),
                          tooltip: '查看比较结果',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createBinding(
    String targetDatabase,
    String targetCollection,
    Map<String, String> sourceData,
  ) {
    final binding = CollectionBinding(
      sourceDatabase: sourceData['database']!,
      sourceCollection: sourceData['collection']!,
      targetDatabase: targetDatabase,
      targetCollection: targetCollection,
      id: '${sourceData['database']}_${sourceData['collection']}_${targetDatabase}_$targetCollection',
    );
    if (!_bindings.contains(binding)) {
      setState(() {
        _bindings.add(binding);
      });
      widget.onBindingsChanged(_bindings);
    }
  }

  void _removeBinding(CollectionBinding binding) {
    setState(() {
      _bindings.remove(binding);
      // 同时移除比较结果
      _comparisonResults.remove(binding.id);
      _detailedResults.remove(binding.id);
    });
    widget.onBindingsChanged(_bindings);
  }

  void _clearAllBindings() {
    setState(() {
      _bindings.clear();
      _comparisonResults.clear();
      _detailedResults.clear();
    });
    widget.onBindingsChanged(_bindings);
  }

  // 比较单个绑定
  Future<void> _compareBinding(CollectionBinding binding) async {
    // 设置比较状态为进行中
    setState(() {
      _comparisonResults[binding.id] = ComparisonResultInfo(isCompleted: false);
    });

    try {
      // 执行比较
      widget.onCompareBinding(binding);
    } catch (e) {
      // 处理错误
      if (mounted) {
        setState(() {
          _comparisonResults[binding.id] = ComparisonResultInfo(
            isCompleted: true,
            sameCount: 0,
            diffCount: 0,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('比较失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 批量比较所有绑定
  Future<void> _compareAllBindings() async {
    if (_bindings.isEmpty) return;

    // 显示一个短暂的提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('开始批量比较...'),
        duration: Duration(seconds: 1),
      ),
    );

    // 确保连接已建立
    if (widget.sourceConnection != null && widget.targetConnection != null) {
      try {
        await _mongoService.connect(widget.sourceConnection!);
        await _mongoService.connect(widget.targetConnection!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('连接失败: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先选择源连接和目标连接'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // 对所有绑定进行比较
    for (final binding in _bindings) {
      await _compareBinding(binding);
    }

    // 显示比较完成提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('批量比较完成'), duration: Duration(seconds: 1)),
      );
    }
  }

  // 导航到比较结果页面
  Future<void> _navigateToComparisonResult(CollectionBinding binding) async {
    // 导航到比较结果页面 - 使用新的文档树比较界面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentTreeComparisonScreen(
          results: [],
          sourceCollection: binding.sourceCollection,
          targetCollection: binding.targetCollection,
          sourceDatabaseName: binding.sourceDatabase,
          targetDatabaseName: binding.targetDatabase,
          mongoService: _mongoService,
          sourceConnectionId: widget.sourceConnection?.id,
          targetConnectionId: widget.targetConnection?.id,
          ignoredFields: [], // 可以从设置中获取忽略字段
        ),
      ),
    );
  }

  // 滚动单个绑定到可见区域
  void _scrollBindingToVisible(CollectionBinding binding) {
    // 确保源面板和目标面板的状态都存在
    final sourceState = _sourceKey.currentState;
    final targetState = _targetKey.currentState;

    if (sourceState == null || targetState == null) return;

    // 展开源数据库并滚动到源集合
    sourceState.expandDatabase(binding.sourceDatabase);
    sourceState.scrollToCollection(
      binding.sourceDatabase,
      binding.sourceCollection,
    );

    // 展开目标数据库并滚动到目标集合
    targetState.expandDatabase(binding.targetDatabase);
    targetState.scrollToCollection(
      binding.targetDatabase,
      binding.targetCollection,
    );

    // 显示一个短暂的提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已滚动到绑定的集合'),
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  bool _isSourceBound(String database, String collection) {
    return _bindings.any(
      (binding) =>
          binding.sourceDatabase == database &&
          binding.sourceCollection == collection,
    );
  }

  bool _isTargetBound(String database, String collection) {
    return _bindings.any(
      (binding) =>
          binding.targetDatabase == database &&
          binding.targetCollection == collection,
    );
  }
}

class ConnectionLinePainter extends CustomPainter {
  final List<CollectionBinding> bindings;
  final GlobalKey<DatabaseCollectionPanelState> sourceKey;
  final GlobalKey<DatabaseCollectionPanelState> targetKey;
  final BuildContext context;
  final RenderBox? painterRenderBox;

  ConnectionLinePainter({
    required this.bindings,
    required this.sourceKey,
    required this.targetKey,
    required this.context,
    this.painterRenderBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Theme.of(context).colorScheme.primary.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (painterRenderBox == null) {
      print('ConnectionLinePainter: painterRenderBox is null');
      return;
    }

    print('ConnectionLinePainter: 开始绘制连接线，共有 ${bindings.length} 个绑定');

    for (final binding in bindings) {
      print(
        'ConnectionLinePainter: 处理绑定 ${binding.sourceDatabase}.${binding.sourceCollection} -> ${binding.targetDatabase}.${binding.targetCollection}',
      );

      // 修改key的格式，使用 数据库名.集合名 作为key
      final sourceCollectionKey =
          '${binding.sourceDatabase}.${binding.sourceCollection}';
      final targetCollectionKey =
          '${binding.targetDatabase}.${binding.targetCollection}';

      final isSourceDatabaseCollapsed =
          sourceKey.currentState?.isDatabaseCollapsed(binding.sourceDatabase) ??
          true;
      final isTargetDatabaseCollapsed =
          targetKey.currentState?.isDatabaseCollapsed(binding.targetDatabase) ??
          true;

      // 获取ValueKey对应的BuildContext
      final sourceContext = _findContextForKey(
        sourceKey.currentState?.nodeKeys[isSourceDatabaseCollapsed
            ? binding.sourceDatabase
            : sourceCollectionKey],
        PanelType.source,
      );
      final targetContext = _findContextForKey(
        targetKey.currentState?.nodeKeys[isTargetDatabaseCollapsed
            ? binding.targetDatabase
            : targetCollectionKey],
        PanelType.target,
      );

      // 从BuildContext获取RenderBox
      RenderBox? sourceRenderBox =
          sourceContext?.findRenderObject() as RenderBox?;
      RenderBox? targetRenderBox =
          targetContext?.findRenderObject() as RenderBox?;

      if (sourceRenderBox != null && targetRenderBox != null) {
        // 获取全局位置
        final sourceGlobalPosition = sourceRenderBox.localToGlobal(Offset.zero);
        final targetGlobalPosition = targetRenderBox.localToGlobal(Offset.zero);

        // 转换为画布的本地坐标
        final sourceLocalPosition = painterRenderBox!.globalToLocal(
          sourceGlobalPosition,
        );
        final targetLocalPosition = painterRenderBox!.globalToLocal(
          targetGlobalPosition,
        );

        // 计算连接线的起点和终点
        Offset sourceCenter;
        Offset targetCenter;

        sourceCenter = Offset(
          sourceLocalPosition.dx + sourceRenderBox.size.width,
          sourceLocalPosition.dy + sourceRenderBox.size.height / 2,
        );

        // 根据是否为数据库级别调整连接点位置
        if (isSourceDatabaseCollapsed) {
          print('ConnectionLinePainter: 使用 数据库项 位置作为源连接点: $sourceCenter');
        } else {
          print('ConnectionLinePainter: 使用 集合项 位置作为源连接点: $sourceCenter');
        }

        targetCenter = Offset(
          targetLocalPosition.dx,
          targetLocalPosition.dy + targetRenderBox.size.height / 2,
        );
        if (isTargetDatabaseCollapsed) {
          print('ConnectionLinePainter: 使用 数据库项 位置作为目标连接点: $targetCenter');
        } else {
          print('ConnectionLinePainter: 使用 集合项 位置作为目标连接点: $targetCenter');
        }

        // 绘制贝塞尔曲线
        final path = Path();
        path.moveTo(sourceCenter.dx, sourceCenter.dy);

        final controlPoint1 = Offset(
          sourceCenter.dx + (targetCenter.dx - sourceCenter.dx) * 0.5,
          sourceCenter.dy,
        );

        final controlPoint2 = Offset(
          sourceCenter.dx + (targetCenter.dx - sourceCenter.dx) * 0.5,
          targetCenter.dy,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          targetCenter.dx,
          targetCenter.dy,
        );

        canvas.drawPath(path, paint);
      }
    }
  }

  // 辅助方法：从ValueKey获取BuildContext
  BuildContext? _findContextForKey(ValueKey? key, PanelType type) {
    if (key == null) return null;

    // 使用Element.visitChildElements递归查找具有指定key的元素
    BuildContext? result;

    void visitor(Element element) {
      if (element.widget is DatabaseCollectionPanel) {
        if ((element.widget as DatabaseCollectionPanel).type == type) {
          element.visitChildren(visitor);
        }
        return;
      }
      if (element.widget.key == key) {
        result = element;
        return;
      }
      element.visitChildren(visitor);
    }

    // 从根元素开始访问
    (context as Element).visitChildElements(visitor);

    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
