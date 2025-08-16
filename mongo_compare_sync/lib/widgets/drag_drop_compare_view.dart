import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../widgets/database_collection_panel.dart';

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
  Map<String, bool> _comparisonResults = {};

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
                        // 显示比较状态的图标
                        if (_comparisonResults.containsKey(binding.id))
                          Icon(
                            _comparisonResults[binding.id]!
                                ? Icons.check_circle
                                : Icons.pending,
                            color: _comparisonResults[binding.id]!
                                ? Colors.green
                                : Colors.orange,
                            size: 16,
                          ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            setState(() {
                              _comparisonResults[binding.id] = false;
                            });
                            widget.onCompareBinding(binding);
                            // 模拟比较完成
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                if (mounted) {
                                  setState(() {
                                    _comparisonResults[binding.id] = true;
                                  });
                                }
                              },
                            );
                          },
                          tooltip: '执行比较',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeBinding(binding),
                          tooltip: '删除绑定',
                        ),
                        // 添加滚动到可见区域的按钮
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          iconSize: 20,
                          onPressed: () => _scrollBindingToVisible(binding),
                          tooltip: '滚动到可见区域',
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
    });
    widget.onBindingsChanged(_bindings);
  }

  void _clearAllBindings() {
    setState(() {
      _bindings.clear();
    });
    widget.onBindingsChanged(_bindings);
  }

  void _compareAllBindings() {
    // 清空之前的比较结果
    setState(() {
      _comparisonResults.clear();
    });

    // 对所有绑定进行比较
    for (final binding in _bindings) {
      // 记录比较状态，默认为进行中
      setState(() {
        _comparisonResults[binding.id] = false;
      });

      // 执行比较
      widget.onCompareBinding(binding);

      // 在实际应用中，这里应该有一个回调来更新比较结果
      // 由于我们没有实际的比较结果回调，这里模拟设置为已完成
      setState(() {
        _comparisonResults[binding.id] = true;
      });
    }
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

    // // 如果绑定列表是打开的，关闭它以便更好地查看集合
    // if (_showBindingsList) {
    //   setState(() {
    //     _showBindingsList = false;
    //   });
    // }
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
          // 如果是数据库级别（收缩状态），连接到ExpansionTile的右侧
          // sourceCenter = Offset(
          //   sourceLocalPosition.dx +
          //       sourceRenderBox.size.width -
          //       16, // 右侧留出一些边距
          //   sourceLocalPosition.dy + 24, // ExpansionTile标题的高度约为48，取中点
          // );
          print('ConnectionLinePainter: 使用 数据库项 位置作为源连接点: $sourceCenter');
        } else {
          // 如果是集合级别（展开状态），连接到集合项的右侧
          // sourceCenter = Offset(
          //   sourceLocalPosition.dx + sourceRenderBox.size.width,
          //   sourceLocalPosition.dy + sourceRenderBox.size.height / 2,
          // );
          print('ConnectionLinePainter: 使用 集合项 位置作为源连接点: $sourceCenter');
        }

        targetCenter = Offset(
          targetLocalPosition.dx,
          targetLocalPosition.dy + targetRenderBox.size.height / 2,
        );
        if (isTargetDatabaseCollapsed) {
          // 如果是数据库级别（收缩状态），直接使用固定位置
          // 获取目标数据库项的宽度，用于计算
          // final dbWidth = targetRenderBox.size.width;
          // final dbHeight = targetRenderBox.size.height;

          // print('ConnectionLinePainter: 目标数据库项宽度: $dbWidth, 高度: $dbHeight');

          // // 硬编码连接到数据库项的图标位置
          // targetCenter = Offset(
          //   targetLocalPosition.dx + 40, // 进一步调整水平位置
          //   targetLocalPosition.dy + 24, // 保持垂直位置不变
          // );

          print('ConnectionLinePainter: 使用 数据库项 位置作为目标连接点: $targetCenter');
        } else {
          // 如果是集合级别（展开状态），连接到集合项的左侧
          // targetCenter = Offset(
          //   targetLocalPosition.dx,
          //   targetLocalPosition.dy + targetRenderBox.size.height / 2,
          // );
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
