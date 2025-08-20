import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comparison_task.dart';
import '../models/connection.dart';
import '../widgets/database_collection_panel.dart';
import '../widgets/binding_list_button.dart';
import '../providers/connection_provider.dart';

class DragDropCompareView extends ConsumerStatefulWidget {
  const DragDropCompareView({super.key});

  @override
  ConsumerState<DragDropCompareView> createState() =>
      _DragDropCompareViewState();
}

class _DragDropCompareViewState extends ConsumerState<DragDropCompareView>
    with TickerProviderStateMixin {
  final List<BindingConfig> _bindings = [];
  final GlobalKey<DatabaseCollectionPanelState> _sourceKey = GlobalKey();
  final GlobalKey<DatabaseCollectionPanelState> _targetKey = GlobalKey();
  final GlobalKey _painterKey = GlobalKey();
  // MongoDB服务实例通过Provider获取
  MongoConnection? _sourceConnection;
  MongoConnection? _targetConnection;

  Widget _buildConnectionDropdown({
    required String label,
    required List<MongoConnection> connections,
    required Function(MongoConnection?) onConnectionChanged,
    MongoConnection? selectedConnection,
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
          value: selectedConnection?.id,
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
    // 从 ConnectionProvider 获取连接列表
    final connectionsState = ref.watch(connectionsProvider);

    return connectionsState.when(
      data: (connections) {
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
                      connections: connections,
                      onConnectionChanged: onSourceConnectionChanged,
                      selectedConnection: _sourceConnection,
                    ),
                  ),
                  const Spacer(flex: 1),
                  Flexible(
                    flex: 2,
                    child: _buildConnectionDropdown(
                      label: '目标连接',
                      connections: connections,
                      onConnectionChanged: onTargetConnectionChanged,
                      selectedConnection: _targetConnection,
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
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                          ),
                        ),
                        // 使用独立的绑定列表按钮组件
                        Positioned.fill(
                          child: BindingListButton(
                            bindings: _bindings,
                            sourceConnection: _sourceConnection,
                            targetConnection: _targetConnection,
                            onRemoveBinding: _removeBinding,
                            onScrollToBinding: _scrollBindingToVisible,
                            onClearAllBindings: _clearAllBindings,
                            onAddBinding: _addBinding,
                            onConnectionChange: _onConnectionChange,
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('加载连接失败: $error')),
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
    String targetDatabaseName,
    String targetCollection,
    Map<String, String> sourceData,
  ) {
    final binding = BindingConfig(
      id: '${sourceData['database']}_${sourceData['collection']}_${targetDatabaseName}_$targetCollection',
      sourceDatabaseName: sourceData['database']!,
      sourceCollection: sourceData['collection']!,
      targetDatabaseName: targetDatabaseName,
      targetCollection: targetCollection,
      idField: '_id', // 默认使用_id作为ID字段
      ignoredFields: [], // 默认为空，可以在比较界面中设置
    );
    if (!_bindings.contains(binding)) {
      setState(() {
        _bindings.add(binding);
      });
    }
  }

  void _removeBinding(BindingConfig binding) {
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
  void _scrollBindingToVisible(BindingConfig binding) {
    // 确保源面板和目标面板的状态都存在
    final sourceState = _sourceKey.currentState;
    final targetState = _targetKey.currentState;

    if (sourceState == null || targetState == null) return;

    // 展开源数据库并滚动到源集合
    sourceState.expandDatabase(binding.sourceDatabaseName);
    sourceState.scrollToCollection(
      binding.sourceDatabaseName,
      binding.sourceCollection,
    );

    // 展开目标数据库并滚动到目标集合
    targetState.expandDatabase(binding.targetDatabaseName);
    targetState.scrollToCollection(
      binding.targetDatabaseName,
      binding.targetCollection,
    );
  }

  bool _isSourceBound(String database, String collection) {
    return _bindings.any(
      (binding) =>
          binding.sourceDatabaseName == database &&
          binding.sourceCollection == collection,
    );
  }

  bool _isTargetBound(String database, String collection) {
    return _bindings.any(
      (binding) =>
          binding.targetDatabaseName == database &&
          binding.targetCollection == collection,
    );
  }

  // 添加绑定
  void _addBinding(BindingConfig binding) {
    if (!_bindings.contains(binding)) {
      setState(() {
        _bindings.add(binding);
      });
    }
  }

  // 更改连接
  void _onConnectionChange(
    String? sourceConnectionId,
    String? targetConnectionId,
  ) {
    if (sourceConnectionId != null || targetConnectionId != null) {
      final connectionsState = ref.read(connectionsProvider);

      connectionsState.whenData((connections) {
        // 更新源连接
        if (sourceConnectionId != null) {
          final sourceConn = connections.firstWhere(
            (conn) => conn.id == sourceConnectionId,
            orElse: () => _sourceConnection ?? connections.first,
          );
          onSourceConnectionChanged(sourceConn);
        }

        // 更新目标连接
        if (targetConnectionId != null) {
          final targetConn = connections.firstWhere(
            (conn) => conn.id == targetConnectionId,
            orElse: () => _targetConnection ?? connections.first,
          );
          onTargetConnectionChanged(targetConn);
        }
      });
    }
  }
}

class ConnectionLinePainter extends CustomPainter {
  final List<BindingConfig> bindings;
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
        'ConnectionLinePainter: 处理绑定 ${binding.sourceDatabaseName}.${binding.sourceCollection} -> ${binding.targetDatabaseName}.${binding.targetCollection}',
      );

      // 修改key的格式，使用 数据库名.集合名 作为key
      final sourceCollectionKey =
          '${binding.sourceDatabaseName}.${binding.sourceCollection}';
      final targetCollectionKey =
          '${binding.targetDatabaseName}.${binding.targetCollection}';

      final isSourceDatabaseCollapsed =
          sourceKey.currentState?.isDatabaseCollapsed(
            binding.sourceDatabaseName,
          ) ??
          true;
      final isTargetDatabaseCollapsed =
          targetKey.currentState?.isDatabaseCollapsed(
            binding.targetDatabaseName,
          ) ??
          true;

      // 获取ValueKey对应的BuildContext
      final sourceContext = _findContextForKey(
        sourceKey.currentState?.nodeKeys[isSourceDatabaseCollapsed
            ? binding.sourceDatabaseName
            : sourceCollectionKey],
        PanelType.source,
      );
      final targetContext = _findContextForKey(
        targetKey.currentState?.nodeKeys[isTargetDatabaseCollapsed
            ? binding.targetDatabaseName
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
