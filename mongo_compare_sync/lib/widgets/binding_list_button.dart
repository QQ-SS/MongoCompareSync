import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comparison_task.dart';
import '../models/connection.dart';
import '../repositories/comparison_task_repository.dart';
import '../screens/document_tree_comparison_screen.dart';

class BindingListButton extends ConsumerStatefulWidget {
  final List<BindingConfig> bindings;
  final MongoConnection? sourceConnection;
  final MongoConnection? targetConnection;
  final Function(BindingConfig) onRemoveBinding;
  final Function(BindingConfig) onScrollToBinding;
  final Function() onClearAllBindings;
  final Function(BindingConfig)? onAddBinding; // 新增：添加绑定的回调
  final Function(String?, String?)? onConnectionChange; // 新增：更改连接的回调

  const BindingListButton({
    super.key,
    required this.bindings,
    required this.sourceConnection,
    required this.targetConnection,
    required this.onRemoveBinding,
    required this.onScrollToBinding,
    required this.onClearAllBindings,
    this.onAddBinding, // 可选参数
    this.onConnectionChange, // 可选参数
  });

  @override
  ConsumerState<BindingListButton> createState() => _BindingListButtonState();
}

class _BindingListButtonState extends ConsumerState<BindingListButton> {
  bool _showBindingsList = false;
  final ComparisonTaskRepository _taskRepository = ComparisonTaskRepository();
  List<ComparisonTask>? _savedTasks;
  String? _currentTaskName; // 添加当前任务名变量

  @override
  Widget build(BuildContext context) {
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
                    // 添加间隔
                    const SizedBox(width: 16),
                    // 保存任务按钮
                    TextButton.icon(
                      onPressed: _showSaveTaskDialog,
                      icon: const Icon(Icons.save),
                      label: const Text('保存任务'),
                    ),
                  ],
                  // 加载任务按钮
                  TextButton.icon(
                    onPressed: _showLoadTaskDialog,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('加载任务'),
                  ),
                  const SizedBox(width: 16),
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
                      '${binding.sourceDatabaseName}.${binding.sourceCollection}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '→ ${binding.targetDatabaseName}.${binding.targetCollection}',
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

  // 显示保存任务对话框
  void _showSaveTaskDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _currentTaskName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存比较任务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '任务名称',
                hintText: '输入任务名称',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _saveTask(nameController.text);
                setState(() {
                  _currentTaskName = nameController.text;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 保存任务
  Future<void> _saveTask(String name) async {
    if (widget.bindings.isEmpty) return;

    // 将所有绑定转换为BindingConfig列表
    final bindingConfigs = widget.bindings
        .map(
          (binding) => BindingConfig(
            id: binding.id,
            sourceCollection: binding.sourceCollection,
            targetCollection: binding.targetCollection,
            sourceDatabaseName: binding.sourceDatabaseName,
            targetDatabaseName: binding.targetDatabaseName,
            idField: binding.idField ?? '_id', // 默认使用_id作为ID字段
            ignoredFields: binding.ignoredFields ?? [], // 默认为空，可以在比较界面中设置
          ),
        )
        .toList();

    // 创建任务
    final task = ComparisonTask(
      name: name,
      bindings: bindingConfigs,
      sourceConnectionId: widget.sourceConnection?.id,
      targetConnectionId: widget.targetConnection?.id,
    );

    // 保存任务
    await _taskRepository.saveTask(task);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('任务 "$name" 已保存，包含 ${bindingConfigs.length} 个绑定')),
    );
  }

  // 显示加载任务对话框
  Future<void> _showLoadTaskDialog() async {
    // 加载所有保存的任务
    _savedTasks = await _taskRepository.getAllTasks();

    if (_savedTasks == null || _savedTasks!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有保存的任务')));
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加载比较任务'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _savedTasks!.length,
            itemBuilder: (context, index) {
              final task = _savedTasks![index];
              return ListTile(
                title: Text(task.name),
                subtitle: Text(
                  '${task.sourceDatabaseName}.${task.sourceCollection} → ${task.targetDatabaseName}.${task.targetCollection}',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _loadTask(task);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _taskRepository.deleteTask(task.name);
                    setState(() {
                      _savedTasks!.removeAt(index);
                    });
                    if (_savedTasks!.isEmpty) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // 加载任务
  void _loadTask(ComparisonTask task) {
    if (task.bindings.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('任务中没有绑定信息')));
      return;
    }

    // 如果任务包含多个绑定，显示选择对话框
    if (task.bindings.length > 1) {
      _showBindingSelectionDialog(task);
    } else {
      // 只有一个绑定，直接导航到比较结果页面
      _navigateToComparisonScreen(task, task.bindings.first);
    }
  }

  // 显示绑定选择对话框
  void _showBindingSelectionDialog(ComparisonTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('加载任务 - ${task.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('此操作将清空当前的集合绑定列表，并加载以下 ${task.bindings.length} 个绑定：'),
              const SizedBox(height: 8),
              // 使用固定数量的绑定显示，而不是ListView
              ...task.bindings
                  .take(5)
                  .map(
                    (binding) => Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${binding.sourceDatabaseName}.${binding.sourceCollection}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '→ ${binding.targetDatabaseName}.${binding.targetCollection}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              // 如果绑定数量超过5个，显示"更多"提示
              if (task.bindings.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '...以及其他 ${task.bindings.length - 5} 个绑定',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadAllBindings(task);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  // 加载所有绑定到列表
  void _loadAllBindings(ComparisonTask task) {
    // 保存当前任务名
    setState(() {
      _currentTaskName = task.name;
    });

    // 清空当前绑定列表
    widget.onClearAllBindings();

    // 更改连接（如果提供了回调）
    if (widget.onConnectionChange != null) {
      widget.onConnectionChange!(
        task.sourceConnectionId,
        task.targetConnectionId,
      );
    }

    // 将任务中的所有绑定添加到绑定列表
    for (final bindingConfig in task.bindings) {
      final binding = BindingConfig(
        id: '${bindingConfig.sourceDatabaseName}_${bindingConfig.sourceCollection}_${bindingConfig.targetDatabaseName}_${bindingConfig.targetCollection}',
        sourceCollection: bindingConfig.sourceCollection,
        targetCollection: bindingConfig.targetCollection,
        sourceDatabaseName: bindingConfig.sourceDatabaseName,
        targetDatabaseName: bindingConfig.targetDatabaseName,
        idField: bindingConfig.idField,
        ignoredFields: bindingConfig.ignoredFields,
      );

      // 如果提供了添加绑定的回调，使用它来添加绑定
      if (widget.onAddBinding != null) {
        widget.onAddBinding!(binding);
      }
    }

    // 显示成功消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已加载任务 "${task.name}" 的 ${task.bindings.length} 个绑定'),
      ),
    );

    // 关闭绑定列表面板
    setState(() {
      _showBindingsList = false;
    });
  }

  // 导航到比较结果页面
  void _navigateToComparisonScreen(ComparisonTask task, BindingConfig binding) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentTreeComparisonScreen(
          sourceCollection: binding.sourceCollection,
          targetCollection: binding.targetCollection,
          sourceDatabaseName: binding.sourceDatabaseName,
          targetDatabaseName: binding.targetDatabaseName,
          sourceConnectionId: task.sourceConnectionId,
          targetConnectionId: task.targetConnectionId,
          idField: binding.idField,
          ignoredFields: binding.ignoredFields,
        ),
      ),
    );
  }

  Future<void> onCompareAllBindings() async {}

  // 导航到比较结果页面
  Future<void> onNavigateToComparison(BindingConfig binding) async {
    // 导航到比较结果页面 - 使用新的文档树比较界面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentTreeComparisonScreen(
          sourceCollection: binding.sourceCollection,
          targetCollection: binding.targetCollection,
          sourceDatabaseName: binding.sourceDatabaseName,
          targetDatabaseName: binding.targetDatabaseName,
          sourceConnectionId: widget.sourceConnection?.id,
          targetConnectionId: widget.targetConnection?.id,
          idField: binding.idField,
          ignoredFields: binding.ignoredFields,
          onIgnoredFieldsChanged: (updatedIgnoredFields) {
            // 更新绑定中的忽略字段列表
            final index = widget.bindings.indexOf(binding);
            if (index >= 0) {
              // 创建一个新的绑定对象，因为BindingConfig是不可变的
              final updatedBinding = BindingConfig(
                id: binding.id,
                sourceCollection: binding.sourceCollection,
                targetCollection: binding.targetCollection,
                sourceDatabaseName: binding.sourceDatabaseName,
                targetDatabaseName: binding.targetDatabaseName,
                idField: binding.idField,
                ignoredFields: updatedIgnoredFields,
              );

              // 替换原有的绑定
              setState(() {
                widget.bindings[index] = updatedBinding;
              });
            }
          },
        ),
      ),
    );
  }
}
