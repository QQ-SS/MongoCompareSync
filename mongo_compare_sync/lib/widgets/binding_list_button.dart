import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection_binding.dart';
import '../models/connection.dart';
import '../screens/document_tree_comparison_screen.dart';

class BindingListButton extends ConsumerStatefulWidget {
  final List<CollectionBinding> bindings;
  final MongoConnection? sourceConnection;
  final MongoConnection? targetConnection;
  final Function(CollectionBinding) onRemoveBinding;
  final Function(CollectionBinding) onScrollToBinding;
  final Function() onClearAllBindings;

  const BindingListButton({
    super.key,
    required this.bindings,
    required this.sourceConnection,
    required this.targetConnection,
    required this.onRemoveBinding,
    required this.onScrollToBinding,
    required this.onClearAllBindings,
  });

  @override
  ConsumerState<BindingListButton> createState() => _BindingListButtonState();
}

class _BindingListButtonState extends ConsumerState<BindingListButton> {
  bool _showBindingsList = false;

  @override
  Widget build(BuildContext context) {
    if (widget.bindings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 浮动按钮，显示绑定数量
        if (!_showBindingsList)
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
                  label: Text(' ${widget.bindings.length}'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        // 绑定列表，点击浮动按钮后显示
        if (_showBindingsList)
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: _buildBindingsList(),
          ),
      ],
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
                    '集合绑定 (${widget.bindings.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (widget.bindings.isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: widget.onClearAllBindings,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('清空'),
                    ),
                    TextButton.icon(
                      onPressed: onCompareAllBindings,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('批量比较'),
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
                itemCount: widget.bindings.length,
                itemBuilder: (context, index) {
                  final binding = widget.bindings[index];
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
                    onTap: () => widget.onScrollToBinding(binding),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => widget.onRemoveBinding(binding),
                          tooltip: '删除绑定',
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => onNavigateToComparison(binding),
                          tooltip: '执行比较',
                        ),
                        // 滚动到可见区域按钮
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          iconSize: 20,
                          onPressed: () => widget.onScrollToBinding(binding),
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

  Future<void> onCompareAllBindings() async {}

  // 导航到比较结果页面
  Future<void> onNavigateToComparison(CollectionBinding binding) async {
    // 导航到比较结果页面 - 使用新的文档树比较界面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentTreeComparisonScreen(
          sourceCollection: binding.sourceCollection,
          targetCollection: binding.targetCollection,
          sourceDatabaseName: binding.sourceDatabase,
          targetDatabaseName: binding.targetDatabase,
          sourceConnectionId: widget.sourceConnection?.id,
          targetConnectionId: widget.targetConnection?.id,
          ignoredFields: [], // 可以从设置中获取忽略字段
        ),
      ),
    );
  }
}
