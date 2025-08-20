import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Center;

import '../models/document.dart';
import '../providers/connection_provider.dart';
import '../providers/settings_provider.dart';
import '../services/mongo_service.dart';

class DocumentTreeComparisonScreen extends ConsumerStatefulWidget {
  final String sourceCollection;
  final String targetCollection;
  final String sourceDatabaseName;
  final String targetDatabaseName;
  final String? sourceConnectionId;
  final String? targetConnectionId;
  final String? idField;
  final List<String> ignoredFields;
  final Function(List<String>)? onIgnoredFieldsChanged; // 添加回调函数

  const DocumentTreeComparisonScreen({
    super.key,
    required this.sourceCollection,
    required this.targetCollection,
    required this.sourceDatabaseName,
    required this.targetDatabaseName,
    this.sourceConnectionId,
    this.targetConnectionId,
    this.idField = '_id',
    this.ignoredFields = const [],
    this.onIgnoredFieldsChanged, // 初始化回调函数
  });

  @override
  ConsumerState<DocumentTreeComparisonScreen> createState() =>
      _DocumentTreeComparisonScreenState();
}

class _DocumentTreeComparisonScreenState
    extends ConsumerState<DocumentTreeComparisonScreen> {
  // 存储完整文档数据
  final Map<String, Map<String, dynamic>> _sourceDocuments = {};
  final Map<String, Map<String, dynamic>> _targetDocuments = {};

  // 存储差异字段映射
  final List<DocumentDiff> _diffResults = [];

  // 存储展开状态
  final Map<String, bool> _expandedDocuments = {};

  // 存储选中的节点路径
  String? _selectedPath;
  // 表示当前选择的是源还是目标
  bool _isSourceSelected = true;
  // 滚动控制器
  final ScrollController _sourceScrollController = ScrollController();
  final ScrollController _targetScrollController = ScrollController();
  // 加载状态
  bool _isLoading = true;
  // 存储忽略的字段列表（可变）
  List<String> _ignoredFields = [];

  // 操作状态
  bool _isProcessing = false;
  String? _processingMessage;

  // MongoDB服务实例
  late final MongoService _mongoService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '文档比较: ${widget.sourceCollection} vs ${widget.targetCollection}',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildComparisonView(_diffResults),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mongoService = ref.read(mongoServiceProvider);
    _loadDocuments();
  }

  @override
  void initState() {
    super.initState();
    // 在didChangeDependencies中初始化
    _ignoredFields = [..._ignoredFields, ...widget.ignoredFields];
  }

  // 构建操作按钮栏
  Widget _buildActionBar() {
    final bool canCopyToSource = _selectedPath != null && !_isSourceSelected;
    final bool canCopyToTarget = _selectedPath != null && _isSourceSelected;
    final bool canDeleteSource = _selectedPath != null && _isSourceSelected;
    final bool canDeleteTarget = _selectedPath != null && !_isSourceSelected;

    // 判断选择的是文档还是属性
    String? selectionType;

    if (_selectedPath != null) {
      selectionType = _selectedPath!.contains('.') ? '属性' : '文档';
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 左侧操作按钮（源文档）
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 复制到源按钮
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    selectionType != null ? '复制${selectionType}到源' : '复制到源',
                  ),
                  onPressed: canCopyToSource ? _copyToSource : null,
                ),
                const SizedBox(width: 8),
                // 删除源按钮
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: Text(
                    selectionType != null ? '删除${selectionType}' : '删除',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: canDeleteSource ? _deleteSource : null,
                ),
              ],
            ),
          ),

          // 刷新按钮
          Tooltip(
            message: '刷新数据并重新比较',
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
              onPressed: () async {
                await _reloadFromDatabase();
                await _compareDocuments();
              },
            ),
          ),

          // 中间分隔
          const SizedBox(width: 16),

          // 右侧操作按钮（目标文档）
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 删除目标按钮
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: Text(
                    selectionType != null ? '删除${selectionType}' : '删除',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: canDeleteTarget ? _deleteTarget : null,
                ),
                const SizedBox(width: 8),
                // 复制到目标按钮
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    selectionType != null ? '复制${selectionType}到目标' : '复制到目标',
                  ),
                  onPressed: canCopyToTarget ? _copyToTarget : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建比较视图
  Widget _buildComparisonView(List<DocumentDiff> sortedResults) {
    return Stack(
      children: [
        Column(
          children: [
            // 操作按钮栏
            _buildActionBar(),

            // 忽略字段标签栏
            if (_ignoredFields.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '已忽略的字段：',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _ignoredFields.map((field) {
                          return Chip(
                            label: Text(field),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _ignoredFields.remove(field);
                                _compareDocuments();
                                // 通知父组件忽略字段已更改
                                if (widget.onIgnoredFieldsChanged != null) {
                                  widget.onIgnoredFieldsChanged!(
                                    _ignoredFields,
                                  );
                                }
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelStyle: const TextStyle(fontSize: 12),
                            padding: const EdgeInsets.all(0),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

            // 文档树视图
            Expanded(
              child: Row(
                children: [
                  // 源文档树
                  Expanded(
                    child: _buildDocumentTree(
                      sortedResults,
                      isSource: true,
                      title: '源集合',
                      collection: widget.sourceCollection,
                    ),
                  ),

                  // 中间分隔线
                  Container(width: 1, color: Theme.of(context).dividerColor),

                  // 目标文档树
                  Expanded(
                    child: _buildDocumentTree(
                      sortedResults,
                      isSource: false,
                      title: '目标集合',
                      collection: widget.targetCollection,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 处理中遮罩
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_processingMessage ?? '处理中...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 构建文档项
  Widget _buildDocumentItem(DocumentDiff diff, bool isSource) {
    final String docId = diff.id;
    final bool isExpanded = _expandedDocuments[docId] ?? false;

    // 获取文档数据
    final Map<String, dynamic>? docData = isSource
        ? _sourceDocuments[docId]
        : _targetDocuments[docId];

    // 如果文档不存在，显示占位符
    if (docData == null) {
      return Card(
        margin: const EdgeInsets.all(4.0),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: ListTile(
          title: Text(
            '文档不存在: $docId',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // 判断是否被选中
    final bool isSelected = _selectedPath == docId;

    // 构建文档卡片
    return Card(
      margin: const EdgeInsets.all(4.0),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      elevation: isSelected ? 4 : 1,
      child: Column(
        children: [
          // 文档标题行
          ListTile(
            title: Text(
              '文档: $docId',
              style: TextStyle(
                fontWeight: isSelected && _isSourceSelected == isSource
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            subtitle: Text(
              _getDocumentStatusText(diff, isSource),
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            leading: _getDocumentIcon(diff, isSource),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _expandedDocuments[docId] = !isExpanded;
                });
              },
            ),
            selected: isSelected,
            onTap: () {
              setState(() {
                if (_selectedPath == docId && _isSourceSelected == isSource) {
                  // 如果点击的是已选中的项，则取消选择
                  _selectedPath = null;
                } else {
                  // 否则选中当前项
                  _selectedPath = docId;
                  _isSourceSelected = isSource;
                }
              });

              // 查找对应文档在另一侧的索引位置
              _scrollToMatchingDocument(docId, isSource);
            },
          ),

          // 展开的文档属性
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: _buildNestedFields(
                docData,
                diff,
                isSource,
                parentPath: docId,
              ),
            ),
        ],
      ),
    );
  }

  // 构建文档树
  Widget _buildDocumentTree(
    List<DocumentDiff> diffs, {
    required bool isSource,
    required String title,
    required String collection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: double.infinity,
          child: Text(
            '$title: $collection',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // 文档列表
        Expanded(
          child: ListView.builder(
            controller: isSource
                ? _sourceScrollController
                : _targetScrollController,
            itemCount: diffs.length,
            itemBuilder: (context, index) {
              final diff = diffs[index];
              return _buildDocumentItem(diff, isSource);
            },
          ),
        ),
      ],
    );
  }

  // 构建嵌套字段
  Widget _buildNestedFields(
    Map<String, dynamic> data,
    DocumentDiff diff,
    bool isSource, {
    required String parentPath,
  }) {
    final List<Widget> fieldWidgets = [];

    // 对字段进行排序
    final List<String> sortedKeys = data.keys.toList()
      ..sort()
      ..remove("_id");

    for (final key in sortedKeys) {
      final value = data[key];
      final String fieldPath = '$parentPath.$key';

      // 检查是否为忽略字段
      final bool isIgnored = _ignoredFields.contains(key);

      // 检查字段是否有差异
      final bool hasDiff = _hasFieldDiff(diff, fieldPath);

      // 构建字段行
      final bool isExpanded = _expandedDocuments[fieldPath] ?? false;

      // 判断是否被选中
      final bool isSelected =
          _selectedPath != null && fieldPath.startsWith(_selectedPath!);

      // 字段值的显示文本
      String valueText;
      bool isExpandable = false;
      Map<String, dynamic>? nestedData;

      if (value == null) {
        valueText = 'null';
      } else if (value is Map) {
        valueText = '{...}';
        isExpandable = true;
        nestedData = Map<String, dynamic>.from(value);
      } else if (value is List) {
        valueText = '[${value.length}]';
        // 所有数组都可以展开，不仅仅是包含Map的数组
        isExpandable = true;
        nestedData = {};
        for (int i = 0; i < value.length; i++) {
          nestedData['$i'] = value[i];
        }
      } else {
        valueText = value.toString();
      }

      fieldWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedPath == fieldPath && _isSourceSelected == isSource) {
                // 如果点击的是已选中的项，则取消选择
                _selectedPath = null;
              } else {
                // 否则选中当前项
                _selectedPath = fieldPath;
                _isSourceSelected = isSource;
              }
            });

            // 提取文档ID并滚动到匹配文档
            final docId = parentPath.split('.').first;
            _scrollToMatchingDocument(docId, isSource);
          },
          onSecondaryTapDown: (details) {
            // 显示上下文菜单，使用点击位置
            final RenderBox overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;
            final RelativeRect position = RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx + 1,
              details.globalPosition.dy + 1,
            );

            showMenu(
              context: context,
              position: position,
              items: [
                PopupMenuItem(
                  value: isIgnored ? 'unignore' : 'ignore',
                  child: Row(
                    children: [
                      Icon(
                        isIgnored ? Icons.visibility : Icons.visibility_off,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(isIgnored ? '取消忽略' : '忽略'),
                    ],
                  ),
                ),
              ],
            ).then((value) {
              if (value == 'ignore') {
                // 添加到忽略字段列表
                if (!_ignoredFields.contains(key)) {
                  setState(() {
                    _ignoredFields.add(key);
                    // 重新比较文档
                    _compareDocuments();
                    // 通知父组件忽略字段已更改
                    if (widget.onIgnoredFieldsChanged != null) {
                      widget.onIgnoredFieldsChanged!(_ignoredFields);
                    }
                  });
                }
              } else if (value == 'unignore') {
                // 从忽略字段列表中移除
                if (_ignoredFields.contains(key)) {
                  setState(() {
                    _ignoredFields.remove(key);
                    // 重新比较文档
                    _compareDocuments();
                    // 通知父组件忽略字段已更改
                    if (widget.onIgnoredFieldsChanged != null) {
                      widget.onIgnoredFieldsChanged!(_ignoredFields);
                    }
                  });
                }
              }
            });
          },
          child: Container(
            color: _getFieldBackgroundColor(
              _selectedPath == fieldPath,
              isIgnored,
              hasDiff,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isExpandable)
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _expandedDocuments[fieldPath] = !isExpanded;
                      });
                    },
                  )
                else
                  const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            key,
                            style: TextStyle(
                              fontWeight:
                                  isSelected && _isSourceSelected == isSource
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _getFieldTextColor(isIgnored, hasDiff),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ': $valueText',
                            style: TextStyle(
                              fontWeight:
                                  isSelected && _isSourceSelected == isSource
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _getFieldTextColor(isIgnored, hasDiff),
                            ),
                          ),
                          if (hasDiff)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(
                                Icons.compare_arrows,
                                size: 16,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ],
                      ),

                      // 展开的嵌套字段
                      if (isExpanded && isExpandable && nestedData != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                          child: _buildNestedFields(
                            nestedData,
                            diff,
                            isSource,
                            parentPath: fieldPath,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fieldWidgets,
    );
  }

  // 比较两个文档的字段
  void _compareDocument(
    Map<String, dynamic> sourceDoc,
    Map<String, dynamic> targetDoc,
    String parentPath,
    List<String> fieldDiffs,
  ) {
    // 获取所有字段名
    final Set<String> allFields = {...sourceDoc.keys, ...targetDoc.keys};

    for (final field in allFields) {
      // 跳过忽略的字段
      if (field == "_id" && widget.idField == "_id") continue;
      if (_ignoredFields.contains(field)) continue;

      final String fieldPath = parentPath.isEmpty
          ? field
          : '$parentPath.$field';
      final sourceValue = sourceDoc[field];
      final targetValue = targetDoc[field];

      // 字段只存在于一侧
      if (!sourceDoc.containsKey(field)) {
        // 添加差异字段路径
        if (!fieldDiffs.contains(fieldPath)) {
          fieldDiffs.add(fieldPath);
        }
        continue;
      }

      if (!targetDoc.containsKey(field)) {
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
        );
      } else if (sourceValue is List && targetValue is List) {
        // 比较数组
        if (sourceValue.length != targetValue.length) {
          // 数组长度不同，添加差异字段路径
          if (!fieldDiffs.contains(fieldPath)) {
            fieldDiffs.add(fieldPath);
          }
        }
        //else {
        // 数组长度相同，逐个比较元素
        final len = sourceValue.length > targetValue.length
            ? sourceValue.length
            : targetValue.length;
        for (int i = 0; i < len; i++) {
          // 判断是否下标溢出
          if (i >= sourceValue.length || i >= targetValue.length) {
            final itemPath = '$fieldPath.$i';
            if (!fieldDiffs.contains(itemPath)) {
              fieldDiffs.add(itemPath);
            }
            continue;
          }

          final sourceItem = sourceValue[i];
          final targetItem = targetValue[i];

          if (sourceItem is Map && targetItem is Map) {
            // 递归比较嵌套对象
            _compareDocument(
              Map<String, dynamic>.from(sourceItem),
              Map<String, dynamic>.from(targetItem),
              '$fieldPath.$i',
              fieldDiffs,
            );
          } else if (sourceItem != targetItem) {
            // 值不同，添加差异字段路径
            final itemPath = '$fieldPath.$i';
            if (!fieldDiffs.contains(itemPath)) {
              fieldDiffs.add(itemPath);
            }
          }
        }
        // }
      } else if (sourceValue != targetValue) {
        // 值不同，添加差异字段路径
        if (!fieldDiffs.contains(fieldPath)) {
          fieldDiffs.add(fieldPath);
        }
      }
    }
  }

  // 比较文档
  Future<void> _compareDocuments() async {
    if (_sourceDocuments.isEmpty || _targetDocuments.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先加载文档数据')));
      return;
    }
    setState(() {
      _isProcessing = true;
      _processingMessage = '正在比较文档...';
    });

    try {
      _diffResults.clear();
      // 取源、目标文档的所有id并集，然后进行比较
      final ids = {..._sourceDocuments.keys, ..._targetDocuments.keys}.toList();
      // 更新差异状态
      for (int i = 0; i < ids.length; i++) {
        final docId = ids[i];
        final sourceDoc = _sourceDocuments[docId];
        final targetDoc = _targetDocuments[docId];

        // 比较文档字段
        final fieldDiffs = <String>[];
        if (sourceDoc != null && targetDoc != null) {
          _compareDocument(sourceDoc, targetDoc, docId, fieldDiffs);
        }
        _diffResults.add(
          DocumentDiff(
            id: docId,
            sourceDocument: sourceDoc,
            targetDocument: targetDoc,
            fieldDiffs: fieldDiffs,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('比较文档失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 将文档ID转换为ObjectId
  ObjectId _convertToObjectId(String docId) {
    try {
      // 尝试直接解析
      return ObjectId.parse(docId);
    } catch (e) {
      // 如果失败，可能是 ObjectId("xxx") 格式
      if (docId.startsWith('ObjectId("') && docId.endsWith('")')) {
        // 提取引号中的内容
        final hexString = docId.substring(10, docId.length - 2);
        return ObjectId.parse(hexString);
      } else if (docId.startsWith('ObjectId(\'') && docId.endsWith('\')')) {
        // 处理单引号的情况
        final hexString = docId.substring(10, docId.length - 2);
        return ObjectId.parse(hexString);
      } else {
        // 其他格式，尝试提取任何引号中的内容
        final regex = RegExp(r'"([^"]*)"');
        final match = regex.firstMatch(docId);
        if (match != null && match.groupCount >= 1) {
          return ObjectId.parse(match.group(1)!);
        }

        // 如果所有尝试都失败，抛出异常
        throw FormatException('无法将 $docId 转换为 ObjectId');
      }
    }
  }

  // 复制文档（统一处理源和目标）
  Future<void> _copyDocument(String docId, bool toSource) async {
    final String? connectionId = toSource
        ? widget.sourceConnectionId
        : widget.targetConnectionId;
    if (connectionId == null) return;

    // 获取源文档和目标文档
    final sourceDoc = toSource
        ? _targetDocuments[docId]
        : _sourceDocuments[docId];
    final targetMap = toSource ? _sourceDocuments : _targetDocuments;

    if (sourceDoc == null) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制文档${toSource ? '到源' : '到目标'}...';
    });

    try {
      // 检查目标文档是否已存在
      final targetDoc = targetMap[docId];
      if (targetDoc != null) {
        // 文档已存在，使用更新
        final objectId = _convertToObjectId(docId);
        final docToUpdate = Map<String, dynamic>.from(sourceDoc);
        docToUpdate.remove('_id'); // 移除_id字段，避免更新错误
        await _mongoService.updateDocument(
          connectionId,
          toSource ? widget.sourceDatabaseName : widget.targetDatabaseName,
          toSource ? widget.sourceCollection : widget.targetCollection,
          objectId,
          docToUpdate,
        );
      } else {
        // 文档不存在，使用插入
        await _mongoService.insertDocument(
          connectionId,
          toSource ? widget.sourceDatabaseName : widget.targetDatabaseName,
          toSource ? widget.sourceCollection : widget.targetCollection,
          sourceDoc,
        );
      }

      // 更新本地数据
      setState(() {
        targetMap[docId] = Map<String, dynamic>.from(sourceDoc);
      });

      // 更新文档差异状态
      _updateDocumentDiff(docId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('复制文档${toSource ? '到源' : '到目标'}失败: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 复制字段（统一处理源和目标）
  Future<void> _copyField(String docId, String fieldPath, bool toSource) async {
    final String? connectionId = toSource
        ? widget.sourceConnectionId
        : widget.targetConnectionId;
    if (connectionId == null) return;

    // 获取源文档和目标文档
    final sourceDocMap = toSource ? _targetDocuments : _sourceDocuments;
    final targetDocMap = toSource ? _sourceDocuments : _targetDocuments;

    final sourceDoc = sourceDocMap[docId];
    if (sourceDoc == null) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制字段${toSource ? '到源' : '到目标'}...';
    });

    try {
      // 从源文档中获取字段值
      final fieldValue = _getNestedValue(sourceDoc, fieldPath.split('.'));

      // 检查目标文档是否存在
      final targetDoc = targetDocMap[docId];
      final objectId = _convertToObjectId(docId);

      if (targetDoc == null) {
        // 目标文档不存在，需要先创建一个空文档
        // 创建一个只包含_id和要复制字段的新文档
        final Map<String, dynamic> newDoc = {'_id': objectId};
        _setNestedValue(newDoc, fieldPath.split('.'), fieldValue);

        // 插入新文档
        await _mongoService.insertDocument(
          connectionId,
          toSource ? widget.sourceDatabaseName : widget.targetDatabaseName,
          toSource ? widget.sourceCollection : widget.targetCollection,
          newDoc,
        );

        // 更新本地数据
        setState(() {
          targetDocMap[docId] = newDoc;
        });
      } else {
        // 目标文档存在，使用updateField更新字段
        await _mongoService.updateField(
          connectionId,
          toSource ? widget.sourceDatabaseName : widget.targetDatabaseName,
          toSource ? widget.sourceCollection : widget.targetCollection,
          objectId,
          fieldPath,
          fieldValue,
        );

        // 更新本地数据
        final updatedTargetDoc = Map<String, dynamic>.from(targetDoc);
        _setNestedValue(updatedTargetDoc, fieldPath.split('.'), fieldValue);
        setState(() {
          targetDocMap[docId] = updatedTargetDoc;
        });
      }

      // 更新文档差异状态
      _updateDocumentDiff(docId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('复制字段${toSource ? '到源' : '到目标'}失败: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 复制到源或目标
  Future<void> _copyToDirection(bool toSource) async {
    if (_selectedPath == null) return;

    // 确保选择的是正确的方向
    if (toSource == _isSourceSelected) return;

    final parts = _selectedPath!.split('.');
    final docId = parts.first;

    // 检查是否为文档级别操作
    if (parts.length == 1) {
      await _copyDocument(docId, toSource);
    } else {
      // 字段级别操作
      final fieldPath = parts.sublist(1).join('.');
      await _copyField(docId, fieldPath, toSource);
    }
  }

  // 复制到源
  Future<void> _copyToSource() async {
    await _copyToDirection(true);
  }

  // 复制到目标
  Future<void> _copyToTarget() async {
    await _copyToDirection(false);
  }

  // 删除文档（统一处理源和目标）
  Future<void> _deleteDocument(String docId, bool isSource) async {
    final String? connectionId = isSource
        ? widget.sourceConnectionId
        : widget.targetConnectionId;
    if (connectionId == null) return;

    // 确认删除
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除${isSource ? '源' : '目标'}文档 $docId 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在删除${isSource ? '源' : '目标'}文档...';
    });

    try {
      // 将字符串ID转换为ObjectId
      final objectId = _convertToObjectId(docId);
      await _mongoService.deleteDocument(
        connectionId,
        isSource ? widget.sourceDatabaseName : widget.targetDatabaseName,
        isSource ? widget.sourceCollection : widget.targetCollection,
        objectId,
      );

      // 更新本地数据
      setState(() {
        if (isSource) {
          _sourceDocuments.remove(docId);
        } else {
          _targetDocuments.remove(docId);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除${isSource ? '源' : '目标'}文档失败: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 删除字段（统一处理源和目标）
  Future<void> _deleteField(
    String docId,
    String fieldPath,
    bool isSource,
  ) async {
    final String? connectionId = isSource
        ? widget.sourceConnectionId
        : widget.targetConnectionId;
    if (connectionId == null) return;

    // 获取文档
    final docMap = isSource ? _sourceDocuments : _targetDocuments;
    final doc = docMap[docId];
    if (doc == null) return;

    // 确认删除
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除${isSource ? '源' : '目标'}文档 $docId 的字段 $fieldPath 吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在删除${isSource ? '源' : '目标'}文档字段...';
    });

    try {
      // 将字符串ID转换为ObjectId
      final objectId = _convertToObjectId(docId);

      // 使用removeField方法删除字段
      await _mongoService.removeField(
        connectionId,
        isSource ? widget.sourceDatabaseName : widget.targetDatabaseName,
        isSource ? widget.sourceCollection : widget.targetCollection,
        objectId,
        fieldPath,
      );

      // 更新本地数据
      final updatedDoc = Map<String, dynamic>.from(doc);
      _removeNestedField(updatedDoc, fieldPath.split('.'));
      setState(() {
        docMap[docId] = updatedDoc;
      });

      // 更新文档差异状态
      _updateDocumentDiff(docId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除${isSource ? '源' : '目标'}文档字段失败: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 删除源或目标
  Future<void> _deleteFromDirection(bool isSource) async {
    if (_selectedPath == null) return;

    // 确保选择的是正确的方向
    if (isSource != _isSourceSelected) return;

    final parts = _selectedPath!.split('.');
    final docId = parts.first;

    // 检查是否为文档级别操作
    if (parts.length == 1) {
      await _deleteDocument(docId, isSource);
    } else {
      // 字段级别删除
      final fieldPath = parts.sublist(1).join('.');
      await _deleteField(docId, fieldPath, isSource);
    }
  }

  // 删除源
  Future<void> _deleteSource() async {
    await _deleteFromDirection(true);
  }

  // 删除目标
  Future<void> _deleteTarget() async {
    await _deleteFromDirection(false);
  }

  /// 从文档中提取ID字段的值
  String _extractDocumentId(Map<String, dynamic> doc) {
    return (doc.containsKey(widget.idField))
        ? doc[widget.idField].toString()
        : doc['_id'].toString();
  }

  // 获取文档图标
  Widget _getDocumentIcon(DocumentDiff diff, bool isSource) {
    return diff.sourceDocument == null || diff.targetDocument == null
        ? Icon(Icons.add_circle, color: isSource ? Colors.green : Colors.grey)
        : diff.fieldDiffs?.isEmpty == true
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.edit, color: Colors.amber);
  }

  // 获取文档状态文本
  String _getDocumentStatusText(DocumentDiff diff, bool isSource) {
    return diff.sourceDocument == null || diff.targetDocument == null
        ? (diff.sourceDocument != null
              ? (isSource ? '仅在源中存在' : '不存在')
              : (!isSource ? '仅在目标中存在' : '不存在'))
        : diff.fieldDiffs?.isEmpty == true
        ? '相同'
        : '已修改';
  }

  // 获取字段背景颜色
  Color _getFieldBackgroundColor(
    bool isSelected,
    bool isIgnored,
    bool hasDiff,
  ) {
    if (isSelected) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    if (hasDiff) {
      return Colors.amber.withOpacity(0.1);
    }
    return Colors.transparent;
  }

  // 获取字段文本颜色
  Color _getFieldTextColor(bool isIgnored, bool hasDiff) {
    if (isIgnored) {
      return Theme.of(context).colorScheme.outline;
    }
    if (hasDiff) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  // 获取嵌套字段值
  dynamic _getNestedValue(Map<String, dynamic> doc, List<String> pathParts) {
    dynamic current = doc;

    for (final part in pathParts) {
      if (current is List) {
        final index = int.tryParse(part);
        if (index != null && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        if (current is! Map) return null;
        // 处理对象属性
        current = current[part];
      }

      if (current == null) return null;
    }

    return current;
  }

  // 检查字段是否有差异
  bool _hasFieldDiff(DocumentDiff diff, String fieldPath) {
    if (diff.fieldDiffs == null) return false;

    // 检查完全匹配
    if (diff.fieldDiffs!.contains(fieldPath)) return true;

    // 检查前缀匹配（对于嵌套字段）
    final String prefix = '$fieldPath.';
    for (final path in diff.fieldDiffs!) {
      if (path.startsWith(prefix)) return true;
    }
    return false;
  }

  // 重新比较文档

  // 加载完整文档数据
  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _sourceDocuments.clear();
      _targetDocuments.clear();
    });

    try {
      // 获取最大加载文档数量设置
      final maxDocuments = ref.read(maxDocumentsProvider);

      // 从源数据库加载文档
      if (widget.sourceConnectionId != null) {
        try {
          final sourceDocs = await _mongoService.getDocuments(
            widget.sourceConnectionId!,
            widget.sourceDatabaseName,
            widget.sourceCollection,
            limit: maxDocuments, // 使用设置的最大文档数量
          );

          print('从源数据库加载了 ${sourceDocs.length} 个文档');

          // 将文档添加到源文档映射中
          for (final doc in sourceDocs) {
            var docId = _extractDocumentId(doc.data);
            _sourceDocuments[docId] = doc.data;
          }
        } catch (e) {
          print('加载源数据库文档失败: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('加载源数据库文档失败: $e')));
        }
      }

      // 从目标数据库加载文档
      if (widget.targetConnectionId != null) {
        try {
          final targetDocs = await _mongoService.getDocuments(
            widget.targetConnectionId!,
            widget.targetDatabaseName,
            widget.targetCollection,
            limit: maxDocuments, // 使用设置的最大文档数量
          );

          print('从目标数据库加载了 ${targetDocs.length} 个文档');

          // 将文档添加到目标文档映射中
          for (final doc in targetDocs) {
            var docId = _extractDocumentId(doc.data);
            _targetDocuments[docId] = doc.data;
          }
        } catch (e) {
          print('加载目标数据库文档失败: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('加载目标数据库文档失败: $e')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载文档失败: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 从数据库重新加载数据
  Future<void> _reloadFromDatabase() async {
    await _loadDocuments();
  }

  // 删除嵌套字段
  void _removeNestedField(Map<String, dynamic> doc, List<String> pathParts) {
    if (pathParts.isEmpty) return;

    final lastPart = pathParts.last;
    final parentParts = pathParts.sublist(0, pathParts.length - 1);

    // 如果是顶级字段，直接删除
    if (parentParts.isEmpty) {
      doc.remove(lastPart);
      return;
    }

    // 获取父对象
    dynamic parent = doc;
    for (final part in parentParts) {
      if (parent is List) {
        // 处理数组索引
        final index = int.tryParse(part);

        if (index != null && index < parent.length) {
          parent = parent[index];
        } else {
          return;
        }
      } else {
        if (parent is! Map) return;
        // 处理对象属性
        if (!parent.containsKey(part)) {
          return;
        }
        parent = parent[part];
      }
    }

    // 删除字段
    if (parent is List) {
      final index = int.tryParse(lastPart);
      if (index != null && index < parent.length) {
        // 对于数组，我们不能真正"删除"索引，但可以设置为null
        parent[index] = null;
      }
    } else {
      // 处理对象属性
      if (parent is Map) {
        parent.remove(lastPart);
      }
    }
  }

  // 设置嵌套字段值
  void _setNestedValue(
    Map<String, dynamic> doc,
    List<String> pathParts,
    dynamic value,
  ) {
    if (pathParts.isEmpty) return;

    final lastPart = pathParts.last;
    final parentParts = pathParts.sublist(0, pathParts.length - 1);

    // 获取父对象
    dynamic parent = doc;
    for (final part in parentParts) {
      if (parent is List) {
        // 处理数组索引
        final index = int.tryParse(part);
        if (index != null && index < parent.length) {
          parent = parent[index];
        } else {
          return;
        }
      } else {
        if (parent is! Map) return;
        // 处理对象属性
        if (!parent.containsKey(part)) {
          parent[part] = {};
        }
        parent = parent[part];
      }
    }

    // 设置字段值
    if (parent is List) {
      final index = int.tryParse(lastPart);
      if (index != null) {
        if (index < parent.length) {
          parent[index] = value;
        } else {
          // 如果索引大于现有长度，则添加新元素
          parent.addAll(List.filled(index + 1 - parent.length, null));
          parent[index] = value;
        }
      }
    } else {
      // 处理对象属性
      parent[lastPart] = value;
    }
  }

  // 滚动到匹配的文档
  void _scrollToMatchingDocument(String docId, bool isSource) {
    // 查找文档在列表中的索引
    final index = _diffResults.indexWhere((diff) => diff.id == docId);
    if (index < 0) return;

    // 使用WidgetsBinding.instance.addPostFrameCallback确保在布局完成后获取正确的滚动位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 获取当前滚动位置
      final currentScrollOffset = isSource
          ? _sourceScrollController.offset
          : _targetScrollController.offset;

      // 计算目标滚动控制器
      final targetController = isSource
          ? _targetScrollController
          : _sourceScrollController;

      // 滚动到相同的位置，确保两边对齐
      targetController.jumpTo(currentScrollOffset);

      // 如果需要滚动到特定文档，可以使用以下方法
      // 但这需要知道每个文档项的确切高度，这里我们直接使用相同的滚动偏移量
      /*
      // 计算每个文档的确切高度（这需要更复杂的实现）
      double totalOffset = 0;
      for (int i = 0; i < index; i++) {
        // 这里需要计算每个文档项的实际高度
        // 可以使用GlobalKey或RenderObject来获取
        totalOffset += 120.0; // 假设的高度
      }
      
      targetController.animateTo(
        totalOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      */
    });
  }

  // 更新文档差异状态
  void _updateDocumentDiff(String docId) {
    // 获取源文档和目标文档
    final sourceDoc = _sourceDocuments[docId];
    final targetDoc = _targetDocuments[docId];

    // 如果两边都有文档，重新比较差异
    if (sourceDoc != null && targetDoc != null) {
      // 查找现有的差异记录
      int index = _diffResults.indexWhere((diff) => diff.id == docId);

      // 重新计算字段差异
      final fieldDiffs = <String>[];
      _compareDocument(sourceDoc, targetDoc, docId, fieldDiffs);

      // 更新差异记录
      if (index >= 0) {
        // 更新现有记录
        setState(() {
          _diffResults[index] = DocumentDiff(
            id: docId,
            sourceDocument: sourceDoc,
            targetDocument: targetDoc,
            fieldDiffs: fieldDiffs,
          );
        });
      } else {
        // 添加新记录
        setState(() {
          _diffResults.add(
            DocumentDiff(
              id: docId,
              sourceDocument: sourceDoc,
              targetDocument: targetDoc,
              fieldDiffs: fieldDiffs,
            ),
          );
        });
      }
    }
  }
}
