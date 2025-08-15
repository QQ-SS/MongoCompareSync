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
  final MongoConnection? sourceConnection;
  final MongoConnection? targetConnection;
  final Function(List<CollectionBinding>) onBindingsChanged;
  final Function(CollectionBinding) onCompareBinding;

  const DragDropCompareView({
    super.key,
    required this.sourceConnection,
    required this.targetConnection,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 主要内容
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                ), // 增加左右内边距
                child: Row(
                  children: [
                    // 源集合面板
                    Flexible(
                      flex: 2, // 调整比例，让面板更小
                      child: DatabaseCollectionPanel(
                        key: _sourceKey,
                        connection: widget.sourceConnection,
                        type: PanelType.source,
                        onBindingCheck: _isSourceBound,
                      ),
                    ),

                    const Spacer(flex: 1), // 增加左右面板间距，并分散排列
                    // 目标集合面板
                    Flexible(
                      flex: 2, // 调整比例，让面板更小
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
            ),

            // 连接线
            IgnorePointer(
              // 添加 IgnorePointer 以允许点击穿透
              child: CustomPaint(
                painter: ConnectionLinePainter(
                  bindings: _bindings,
                  sourceKeys: _getSourceKeys(),
                  targetKeys: _getTargetKeys(),
                  context: context,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
            ),

            // 绑定列表
            if (_bindings.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildBindingsList(),
              ),
          ],
        );
      },
    );
  }

  Map<String, GlobalKey> _getSourceKeys() {
    return _sourceKey.currentState?.getCollectionKeys() ?? {};
  }

  Map<String, GlobalKey> _getTargetKeys() {
    return _targetKey.currentState?.getCollectionKeys() ?? {};
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => widget.onCompareBinding(binding),
                          tooltip: '执行比较',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeBinding(binding),
                          tooltip: '删除绑定',
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

    // 检查是否已存在相同的绑定
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
    for (final binding in _bindings) {
      widget.onCompareBinding(binding);
    }
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
  final Map<String, GlobalKey> sourceKeys;
  final Map<String, GlobalKey> targetKeys;
  final BuildContext context;

  ConnectionLinePainter({
    required this.bindings,
    required this.sourceKeys,
    required this.targetKeys,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Theme.of(context).colorScheme.primary.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final binding in bindings) {
      final sourceKey = '${binding.sourceDatabase}_${binding.sourceCollection}';
      final targetKey = '${binding.targetDatabase}_${binding.targetCollection}';

      final sourceGlobalKey = sourceKeys[sourceKey];
      final targetGlobalKey = targetKeys[targetKey];

      if (sourceGlobalKey?.currentContext != null &&
          targetGlobalKey?.currentContext != null) {
        final sourceRenderBox =
            sourceGlobalKey!.currentContext!.findRenderObject() as RenderBox?;
        final targetRenderBox =
            targetGlobalKey!.currentContext!.findRenderObject() as RenderBox?;

        if (sourceRenderBox != null && targetRenderBox != null) {
          // 获取 CustomPaint 自身的 RenderBox
          final RenderBox painterRenderBox =
              context.findRenderObject() as RenderBox;

          // 获取集合项的全局位置
          final sourceGlobalPosition = sourceRenderBox.localToGlobal(
            Offset.zero,
          );
          final targetGlobalPosition = targetRenderBox.localToGlobal(
            Offset.zero,
          );

          // 将全局位置转换为 CustomPaint 的局部位置
          final sourceLocalPosition = painterRenderBox.globalToLocal(
            sourceGlobalPosition,
          );
          final targetLocalPosition = painterRenderBox.globalToLocal(
            targetGlobalPosition,
          );

          // 计算连接点（相对于 CustomPaint 的 Canvas）
          final sourceCenter = Offset(
            sourceLocalPosition.dx + sourceRenderBox.size.width, // 源容器的右边缘
            sourceLocalPosition.dy + sourceRenderBox.size.height / 2,
          );

          final targetCenter = Offset(
            targetLocalPosition.dx, // 目标容器的左边缘
            targetLocalPosition.dy + targetRenderBox.size.height / 2,
          );

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
