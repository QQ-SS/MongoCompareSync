import 'package:flutter/material.dart';
import '../models/collection_binding.dart';

class BindingListButton extends StatefulWidget {
  final List<CollectionBinding> bindings;
  final Map<String, ComparisonResultInfo> comparisonResults;
  final Function(CollectionBinding) onRemoveBinding;
  final Function(CollectionBinding) onNavigateToComparison;
  final Function(CollectionBinding) onScrollToBinding;
  final Function() onClearAllBindings;
  final Function() onCompareAllBindings;

  const BindingListButton({
    Key? key,
    required this.bindings,
    required this.comparisonResults,
    required this.onRemoveBinding,
    required this.onNavigateToComparison,
    required this.onScrollToBinding,
    required this.onClearAllBindings,
    required this.onCompareAllBindings,
  }) : super(key: key);

  @override
  State<BindingListButton> createState() => _BindingListButtonState();
}

class _BindingListButtonState extends State<BindingListButton> {
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
                      onPressed: widget.onCompareAllBindings,
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
                        // 显示比较结果文本
                        if (widget.comparisonResults.containsKey(binding.id) &&
                            widget.comparisonResults[binding.id]!.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget
                                          .comparisonResults[binding.id]!
                                          .diffCount >
                                      0
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '相同: ${widget.comparisonResults[binding.id]!.sameCount} | 差异: ${widget.comparisonResults[binding.id]!.diffCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    widget
                                            .comparisonResults[binding.id]!
                                            .diffCount >
                                        0
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        // 显示比较状态的图标
                        if (widget.comparisonResults.containsKey(binding.id) &&
                            !widget.comparisonResults[binding.id]!.isCompleted)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => widget.onRemoveBinding(binding),
                          tooltip: '删除绑定',
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () =>
                              widget.onNavigateToComparison(binding),
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
}
