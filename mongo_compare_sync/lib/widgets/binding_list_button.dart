import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comparison_task.dart';
import '../models/connection.dart';
import '../models/document.dart';
import '../providers/connection_provider.dart';
import '../providers/compare_view_provider.dart';
import '../repositories/comparison_task_repository.dart';
import '../screens/document_tree_comparison_screen.dart';
import '../services/mongo_service.dart';

class BindingListButton extends ConsumerStatefulWidget {
  final String? taskName;
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
    required this.taskName,
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
  bool _isExpanded = false; // 添加控制列表是否放大的状态
  final ComparisonTaskRepository _taskRepository = ComparisonTaskRepository();
  List<ComparisonTask>? _savedTasks;
  String? _currentTaskName; // 添加当前任务名变量

  @override
  void initState() {
    super.initState();
    _currentTaskName = widget.taskName;
  }

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
        constraints: BoxConstraints(maxHeight: _isExpanded ? 400 : 200),
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
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    tooltip: _isExpanded ? '恢复默认大小' : '放大显示',
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
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.bindings.length,
                itemBuilder: (context, index) {
                  final binding = widget.bindings[index];
                  final compareStatus = _bindingCompareStatus[binding.id];
                  final bool isCompared =
                      compareStatus != null &&
                      compareStatus['isCompared'] == true;
                  final bool hasError =
                      compareStatus != null &&
                      compareStatus['hasError'] == true;

                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: Icon(
                          isCompared
                              ? (hasError
                                    ? Icons.error
                                    : compareStatus['diffCount'] > 0 ||
                                          compareStatus['sourceOnlyCount'] >
                                              0 ||
                                          compareStatus['targetOnlyCount'] > 0
                                    ? Icons.warning
                                    : Icons.check_circle)
                              : Icons.compare_arrows,
                          color: isCompared
                              ? (hasError
                                    ? Colors.red
                                    : compareStatus['diffCount'] > 0 ||
                                          compareStatus['sourceOnlyCount'] >
                                              0 ||
                                          compareStatus['targetOnlyCount'] > 0
                                    ? Colors.orange
                                    : Colors.green)
                              : Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          '${binding.sourceDatabaseName}.${binding.sourceCollection} → ${binding.targetDatabaseName}.${binding.targetCollection}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isCompared && !hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '相同: ${compareStatus['sameCount']}, 差异: ${compareStatus['diffCount']}, 仅源: ${compareStatus['sourceOnlyCount']}, 仅目标: ${compareStatus['targetOnlyCount']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            if (isCompared && hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '比较失败: ${compareStatus['error']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
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
                              onPressed: () =>
                                  widget.onScrollToBinding(binding),
                              tooltip: '滚动到可见区域',
                            ),
                          ],
                        ),
                      ),
                      if (index < widget.bindings.length - 1)
                        const Divider(height: 1),
                    ],
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

    // 更新全局状态中的任务名称
    ref.read(compareViewProvider.notifier).setTaskName(name);

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

    // 显示选择对话框
    _showBindingSelectionDialog(task);
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

    // 导入到Provider中
    final compareViewNotifier = ref.read(compareViewProvider.notifier);
    compareViewNotifier.loadTaskState(
      taskName: task.name,
      bindings: task.bindings,
      sourceConnectionId: task.sourceConnectionId,
      targetConnectionId: task.targetConnectionId,
    );

    // 更改连接（如果提供了回调）
    if (widget.onConnectionChange != null) {
      widget.onConnectionChange!(
        task.sourceConnectionId,
        task.targetConnectionId,
      );
    }

    // 显示成功消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已加载任务 "${task.name}" 的 ${task.bindings.length} 个绑定'),
      ),
    );

    // // 关闭绑定列表面板
    // setState(() {
    //   _showBindingsList = false;
    // });
  }

  Future<void> onCompareAllBindings() async {
    if (widget.bindings.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可比较的绑定')));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // 依次处理每个绑定
    for (int i = 0; i < widget.bindings.length; i++) {
      final binding = widget.bindings[i];

      setState(() {
        _processingMessage =
            '正在比较 ${i + 1}/${widget.bindings.length}: ${binding.sourceCollection} vs ${binding.targetCollection}';
      });

      try {
        // 使用MongoService直接比较集合
        final mongoService = ref.read(mongoServiceProvider);

        // 创建结果对象
        final result = await _compareCollections(
          mongoService,
          binding,
          widget.sourceConnection?.id,
          widget.targetConnection?.id,
        );

        // 保存比较结果
        final String bindingKey =
            '${binding.sourceDatabaseName}.${binding.sourceCollection}_${binding.targetDatabaseName}.${binding.targetCollection}';
        _comparisonResults[bindingKey] = result;

        // 保存比较状态到绑定状态Map
        _bindingCompareStatus[binding.id] = {
          'sameCount': result['sameCount'],
          'diffCount': result['diffCount'],
          'sourceOnlyCount': result['sourceOnlyCount'],
          'targetOnlyCount': result['targetOnlyCount'],
          'isCompared': true,
        };
      } catch (e) {
        // 记录错误状态
        _bindingCompareStatus[binding.id] = {
          'error': e.toString(),
          'isCompared': true,
          'hasError': true,
        };

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '比较失败: ${binding.sourceCollection} vs ${binding.targetCollection} - $e',
            ),
          ),
        );
      }

      // 短暂延迟，避免过度占用资源
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() {
      _isProcessing = false;
      _processingMessage = null;
    });

    // 显示完成消息
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('批量比较完成，结果已显示在列表中')));
  }

  // 存储比较结果的Map
  final Map<String, Map<String, dynamic>> _comparisonResults = {};
  bool _isProcessing = false;
  String? _processingMessage;

  // 存储每个绑定的比较状态
  final Map<String, Map<String, dynamic>> _bindingCompareStatus = {};

  // 导航到比较结果页面
  Future<void> onNavigateToComparison(BindingConfig binding) async {
    // 检查是否已存在比较结果
    final String bindingKey =
        '${binding.sourceDatabaseName}.${binding.sourceCollection}_${binding.targetDatabaseName}.${binding.targetCollection}';
    final existingResult = _comparisonResults[bindingKey];

    if (existingResult != null) {
      // 已存在比较结果，直接显示
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DocumentTreeComparisonScreen.fromExistingResult(
            existingResult: existingResult,
            sourceCollection: binding.sourceCollection,
            targetCollection: binding.targetCollection,
            sourceDatabaseName: binding.sourceDatabaseName,
            targetDatabaseName: binding.targetDatabaseName,
            sourceConnectionId: widget.sourceConnection?.id,
            targetConnectionId: widget.targetConnection?.id,
            idField: binding.idField,
            ignoredFields: binding.ignoredFields ?? [],
            onIgnoredFieldsChanged: (updatedIgnoredFields) {
              _updateBindingIgnoredFields(binding, updatedIgnoredFields);
            },
          ),
        ),
      );
    } else {
      // 不存在比较结果，创建新的比较
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
            ignoredFields: binding.ignoredFields ?? [],
            onIgnoredFieldsChanged: (updatedIgnoredFields) {
              _updateBindingIgnoredFields(binding, updatedIgnoredFields);
            },
            onComparisonComplete: (result) {
              // 保存比较结果
              _comparisonResults[bindingKey] = result;
            },
          ),
        ),
      );
    }
  }

  // 比较两个集合并返回结果
  Future<Map<String, dynamic>> _compareCollections(
    MongoService mongoService,
    BindingConfig binding,
    String? sourceConnectionId,
    String? targetConnectionId,
  ) async {
    // 存储文档数据
    final Map<String, Map<String, dynamic>> sourceDocuments = {};
    final Map<String, Map<String, dynamic>> targetDocuments = {};

    // 从源数据库加载文档
    if (sourceConnectionId != null) {
      try {
        final sourceDocs = await mongoService.getDocuments(
          sourceConnectionId,
          binding.sourceDatabaseName,
          binding.sourceCollection,
        );

        for (final doc in sourceDocs) {
          final docId = _extractDocumentId(doc.data, binding.idField);
          sourceDocuments[docId] = doc.data;
        }
      } catch (e) {
        print('加载源数据库文档失败: $e');
      }
    }

    // 从目标数据库加载文档
    if (targetConnectionId != null) {
      try {
        final targetDocs = await mongoService.getDocuments(
          targetConnectionId,
          binding.targetDatabaseName,
          binding.targetCollection,
        );

        for (final doc in targetDocs) {
          final docId = _extractDocumentId(doc.data, binding.idField);
          targetDocuments[docId] = doc.data;
        }
      } catch (e) {
        print('加载目标数据库文档失败: $e');
      }
    }

    // 比较文档
    final ids = <String>{
      ...sourceDocuments.keys,
      ...targetDocuments.keys,
    }.toList();

    int sameCount = 0;
    int diffCount = 0;
    int sourceOnlyCount = 0;
    int targetOnlyCount = 0;
    final diffResults = [];

    for (final docId in ids) {
      final sourceDoc = sourceDocuments[docId];
      final targetDoc = targetDocuments[docId];

      if (sourceDoc != null && targetDoc != null) {
        // 比较文档字段
        final fieldDiffs = <String>[];
        _compareDocument(
          sourceDoc,
          targetDoc,
          docId,
          fieldDiffs,
          binding.ignoredFields ?? [],
        );

        if (fieldDiffs.isEmpty) {
          sameCount++;
        } else {
          diffCount++;
        }

        // 添加到差异结果列表
        diffResults.add(
          DocumentDiff(
            id: docId,
            sourceDocument: sourceDoc,
            targetDocument: targetDoc,
            fieldDiffs: fieldDiffs,
          ),
        );
      } else if (sourceDoc != null) {
        sourceOnlyCount++;
        // 添加到差异结果列表
        diffResults.add(
          DocumentDiff(
            id: docId,
            sourceDocument: sourceDoc,
            targetDocument: null,
            fieldDiffs: [],
          ),
        );
      } else if (targetDoc != null) {
        targetOnlyCount++;
        // 添加到差异结果列表
        diffResults.add(
          DocumentDiff(
            id: docId,
            sourceDocument: null,
            targetDocument: targetDoc,
            fieldDiffs: [],
          ),
        );
      }
    }

    // 创建结果对象
    return {
      'sameCount': sameCount,
      'diffCount': diffCount,
      'sourceOnlyCount': sourceOnlyCount,
      'targetOnlyCount': targetOnlyCount,
      'diffResults': diffResults,
    };
  }

  // 从文档中提取ID字段的值
  String _extractDocumentId(Map<String, dynamic> doc, String? idField) {
    return (idField != null && doc.containsKey(idField))
        ? doc[idField].toString()
        : doc['_id'].toString();
  }

  // 比较两个文档的字段
  void _compareDocument(
    Map<String, dynamic> sourceDoc,
    Map<String, dynamic> targetDoc,
    String parentPath,
    List<String> fieldDiffs,
    List<String> ignoredFields,
  ) {
    // 获取所有字段名
    final Set<String> allFields = {...sourceDoc.keys, ...targetDoc.keys};

    for (final field in allFields) {
      // 跳过忽略的字段
      if (field == "_id") continue;
      if (ignoredFields.contains(field)) continue;

      final String fieldPath = parentPath.isEmpty
          ? field
          : '$parentPath.$field';
      final sourceValue = sourceDoc[field];
      final targetValue = targetDoc[field];

      // 字段只存在于一侧
      if (!sourceDoc.containsKey(field) || !targetDoc.containsKey(field)) {
        // 添加差异字段路径
        if (!fieldDiffs.contains(fieldPath)) {
          fieldDiffs.add(fieldPath);
        }
        continue;
      }

      // 两侧都有字段，比较值
      if (sourceValue is Map && targetValue is Map) {
        // 递归比较嵌套对象
        _compareDocument(
          Map<String, dynamic>.from(sourceValue),
          Map<String, dynamic>.from(targetValue),
          fieldPath,
          fieldDiffs,
          ignoredFields,
        );
      } else if (sourceValue is List && targetValue is List) {
        // 比较数组
        if (sourceValue.length != targetValue.length) {
          // 数组长度不同，添加差异字段路径
          if (!fieldDiffs.contains(fieldPath)) {
            fieldDiffs.add(fieldPath);
          }
        } else {
          // 数组长度相同，逐个比较元素
          for (int i = 0; i < sourceValue.length; i++) {
            final sourceItem = sourceValue[i];
            final targetItem = targetValue[i];

            if (sourceItem is Map && targetItem is Map) {
              // 递归比较嵌套对象
              _compareDocument(
                Map<String, dynamic>.from(sourceItem),
                Map<String, dynamic>.from(targetItem),
                '$fieldPath.$i',
                fieldDiffs,
                ignoredFields,
              );
            } else if (sourceItem != targetItem) {
              // 值不同，添加差异字段路径
              final itemPath = '$fieldPath.$i';
              if (!fieldDiffs.contains(itemPath)) {
                fieldDiffs.add(itemPath);
              }
            }
          }
        }
      } else if (sourceValue != targetValue) {
        // 值不同，添加差异字段路径
        if (!fieldDiffs.contains(fieldPath)) {
          fieldDiffs.add(fieldPath);
        }
      }
    }
  }

  // 更新绑定的忽略字段列表
  void _updateBindingIgnoredFields(
    BindingConfig binding,
    List<String> updatedIgnoredFields,
  ) {
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
  }
}
