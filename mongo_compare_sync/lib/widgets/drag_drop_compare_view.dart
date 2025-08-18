import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../models/collection_binding.dart';
import '../services/mongo_service.dart';
import '../widgets/database_collection_panel.dart';
import '../widgets/binding_list_button.dart';

class DragDropCompareView extends ConsumerStatefulWidget {
  final List<MongoConnection> connections;

  const DragDropCompareView({super.key, required this.connections});

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
  // MongoDB服务实例
  final MongoService _mongoService = MongoService();
  MongoConnection? _sourceConnection;
  MongoConnection? _targetConnection;

  Widget _buildConnectionDropdown({
    required String label,
    required List<MongoConnection> connections,
    required Function(MongoConnection?) onConnectionChanged,
  }) {
    final uniqueConnections = <String, MongoConnection>{};
    for (final conn in connections) {
      uniqueConnections[conn.id] = conn;
    }
    final uniqueConnectionsList = uniqueConnections.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          // value:selectedConnection.id,
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
                  connections: widget.connections,
                  onConnectionChanged: onSourceConnectionChanged,
                ),
              ),
              const Spacer(flex: 1),
              Flexible(
                flex: 2,
                child: _buildConnectionDropdown(
                  label: '目标连接',
                  connections: widget.connections,
                  onConnectionChanged: onTargetConnectionChanged,
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
                              connection: _sourceConnection,
                              type: PanelType.source,
                              onBindingCheck: _isSourceBound,
                            ),
                          ),
                          const Spacer(flex: 1),
                          Flexible(
                            flex: 2,
                            child: DatabaseCollectionPanel(
                              key: _targetKey,
                              connection: _targetConnection,
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
                    // 使用独立的绑定列表按钮组件
                    Positioned.fill(
                      child: BindingListButton(
                        bindings: _bindings,
                        mongoService: _mongoService,
                        sourceConnection: _sourceConnection,
                        targetConnection: _targetConnection,
                        onRemoveBinding: _removeBinding,
                        onScrollToBinding: _scrollBindingToVisible,
                        onClearAllBindings: _clearAllBindings,
                      ),
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

  void onSourceConnectionChanged(MongoConnection? connection) {
    setState(() {
      _sourceConnection = connection;
    });
  }

  void onTargetConnectionChanged(MongoConnection? connection) {
    setState(() {
      _targetConnection = connection;
    });
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
    }
  }

  void _removeBinding(CollectionBinding binding) {
    setState(() {
      _bindings.remove(binding);
    });
  }

  void _clearAllBindings() {
    setState(() {
      _bindings.clear();
    });
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
