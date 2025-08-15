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
                          sourceCollectionKeys: _getSourceCollectionKeys(),
                          targetCollectionKeys: _getTargetCollectionKeys(),
                          sourceDatabaseKeys: _getSourceDatabaseKeys(),
                          targetDatabaseKeys: _getTargetDatabaseKeys(),
                          context: context,
                          painterRenderBox:
                              _painterKey.currentContext?.findRenderObject()
                                  as RenderBox?,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  Map<String, GlobalKey> _getSourceCollectionKeys() =>
      _sourceKey.currentState?.getCollectionKeys() ?? {};
  Map<String, GlobalKey> _getTargetCollectionKeys() =>
      _targetKey.currentState?.getCollectionKeys() ?? {};
  Map<String, GlobalKey> _getSourceDatabaseKeys() =>
      _sourceKey.currentState?.getDatabaseKeys() ?? {};
  Map<String, GlobalKey> _getTargetDatabaseKeys() =>
      _targetKey.currentState?.getDatabaseKeys() ?? {};

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
  final Map<String, GlobalKey> sourceCollectionKeys;
  final Map<String, GlobalKey> targetCollectionKeys;
  final Map<String, GlobalKey> sourceDatabaseKeys;
  final Map<String, GlobalKey> targetDatabaseKeys;
  final BuildContext context;
  final RenderBox? painterRenderBox;

  ConnectionLinePainter({
    required this.bindings,
    required this.sourceCollectionKeys,
    required this.targetCollectionKeys,
    required this.sourceDatabaseKeys,
    required this.targetDatabaseKeys,
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
      return;
    }

    for (final binding in bindings) {
      final sourceCollectionKey =
          '${binding.sourceDatabase}_${binding.sourceCollection}';
      final targetCollectionKey =
          '${binding.targetDatabase}_${binding.targetCollection}';
      RenderBox? sourceRenderBox =
          sourceCollectionKeys[sourceCollectionKey]?.currentContext
                  ?.findRenderObject()
              as RenderBox?;
      RenderBox? targetRenderBox =
          targetCollectionKeys[targetCollectionKey]?.currentContext
                  ?.findRenderObject()
              as RenderBox?;

      if (sourceRenderBox == null) {
        sourceRenderBox =
            sourceDatabaseKeys[binding.sourceDatabase]?.currentContext
                    ?.findRenderObject()
                as RenderBox?;
      }
      if (targetRenderBox == null) {
        targetRenderBox =
            targetDatabaseKeys[binding.targetDatabase]?.currentContext
                    ?.findRenderObject()
                as RenderBox?;
      }

      if (sourceRenderBox != null && targetRenderBox != null) {
        final sourceGlobalPosition = sourceRenderBox.localToGlobal(Offset.zero);
        final targetGlobalPosition = targetRenderBox.localToGlobal(Offset.zero);
        final sourceLocalPosition = painterRenderBox!.globalToLocal(
          sourceGlobalPosition,
        );
        final targetLocalPosition = painterRenderBox!.globalToLocal(
          targetGlobalPosition,
        );

        final sourceCenter = Offset(
          sourceLocalPosition.dx + sourceRenderBox.size.width,
          sourceLocalPosition.dy + sourceRenderBox.size.height / 2,
        );
        final targetCenter = Offset(
          targetLocalPosition.dx,
          targetLocalPosition.dy + targetRenderBox.size.height / 2,
        );

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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
