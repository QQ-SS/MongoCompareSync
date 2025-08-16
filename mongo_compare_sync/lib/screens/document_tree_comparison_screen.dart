import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/document.dart';
import '../services/mongo_service.dart';
import '../models/collection_compare_result.dart';

class DocumentTreeComparisonScreen extends ConsumerStatefulWidget {
  final List<DocumentDiff> results;
  final String sourceCollection;
  final String targetCollection;
  final MongoService mongoService;
  final String? sourceConnectionId;
  final String? targetConnectionId;
  final List<String> ignoredFields;

  const DocumentTreeComparisonScreen({
    super.key,
    required this.results,
    required this.sourceCollection,
    required this.targetCollection,
    required this.mongoService,
    this.sourceConnectionId,
    this.targetConnectionId,
    this.ignoredFields = const [],
  });

  @override
  ConsumerState<DocumentTreeComparisonScreen> createState() =>
      _DocumentTreeComparisonScreenState();
}

class _DocumentTreeComparisonScreenState
    extends ConsumerState<DocumentTreeComparisonScreen> {
  // 存储展开状态
  final Map<String, bool> _expandedDocuments = {};

  // 存储选中的节点路径
  String? _selectedSourcePath;
  String? _selectedTargetPath;

  // 存储完整文档数据
  final Map<String, Map<String, dynamic>> _sourceDocuments = {};
  final Map<String, Map<String, dynamic>> _targetDocuments = {};

  // 加载状态
  bool _isLoading = true;

  // 操作状态
  bool _isProcessing = false;
  String? _processingMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  // 加载完整文档数据
  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 按ID分组文档差异
      final Map<String, DocumentDiff> diffsByDocId = {};
      for (final diff in widget.results) {
        diffsByDocId[diff.sourceDocument.id] = diff;
      }

      // 获取所有文档ID
      final Set<String> allDocIds = diffsByDocId.keys.toSet();

      // 加载源文档
      for (final id in allDocIds) {
        final diff = diffsByDocId[id];
        if (diff != null &&
            diff.diffType != DocumentDiffType.removed &&
            widget.sourceConnectionId != null) {
          try {
            // 使用getDocuments方法获取单个文档
            final docs = await widget.mongoService.getDocuments(
              widget.sourceConnectionId!,
              diff.sourceDocument.databaseName,
              diff.sourceDocument.collectionName,
              query: {'_id': ObjectId.parse(id)},
            );
            if (docs.isNotEmpty) {
              _sourceDocuments[id] = docs.first.data;
            }
          } catch (e) {
            print('无法加载源文档 $id: $e');
          }
        }
      }

      // 加载目标文档
      for (final id in allDocIds) {
        final diff = diffsByDocId[id];
        if (diff != null &&
            diff.diffType != DocumentDiffType.added &&
            widget.targetConnectionId != null &&
            diff.targetDocument != null) {
          try {
            // 使用getDocuments方法获取单个文档
            final docs = await widget.mongoService.getDocuments(
              widget.targetConnectionId!,
              diff.targetDocument!.databaseName,
              diff.targetDocument!.collectionName,
              query: {'_id': ObjectId.parse(id)},
            );
            if (docs.isNotEmpty) {
              _targetDocuments[id] = docs.first.data;
            }
          } catch (e) {
            print('无法加载目标文档 $id: $e');
          }
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

  @override
  Widget build(BuildContext context) {
    // 对文档进行排序：先显示两边都存在的文档，再显示只在一边存在的文档
    final sortedResults = _sortDocumentDiffs(widget.results);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '文档比较: ${widget.sourceCollection} vs ${widget.targetCollection}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildComparisonView(sortedResults),
    );
  }

  // 对文档差异进行排序
  List<DocumentDiff> _sortDocumentDiffs(List<DocumentDiff> diffs) {
    final List<DocumentDiff> bothExist = [];
    final List<DocumentDiff> sourceOnly = [];
    final List<DocumentDiff> targetOnly = [];

    for (final diff in diffs) {
      switch (diff.diffType) {
        case DocumentDiffType.modified:
          bothExist.add(diff);
          break;
        case DocumentDiffType.added:
          sourceOnly.add(diff);
          break;
        case DocumentDiffType.removed:
          targetOnly.add(diff);
          break;
        case DocumentDiffType.unchanged:
          bothExist.add(diff);
          break;
      }
    }

    // 先显示两边都存在的文档，再显示只在一边存在的文档
    return [...bothExist, ...sourceOnly, ...targetOnly];
  }

  // 构建比较视图
  Widget _buildComparisonView(List<DocumentDiff> sortedResults) {
    return Stack(
      children: [
        Column(
          children: [
            // 操作按钮栏
            _buildActionBar(),

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

                  // 分隔线
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

  // 构建操作按钮栏
  Widget _buildActionBar() {
    final bool canCopyToSource = _selectedTargetPath != null;
    final bool canCopyToTarget = _selectedSourcePath != null;
    final bool canDeleteSource = _selectedSourcePath != null;
    final bool canDeleteTarget = _selectedTargetPath != null;

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
                  label: const Text('复制到源'),
                  onPressed: canCopyToSource ? _copyToSource : null,
                ),
                const SizedBox(width: 8),
                // 删除源按钮
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('删除'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: canDeleteSource ? _deleteSource : null,
                ),
              ],
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
                  label: const Text('删除'),
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
                  label: const Text('复制到目标'),
                  onPressed: canCopyToTarget ? _copyToTarget : null,
                ),
              ],
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

  // 构建文档项
  Widget _buildDocumentItem(DocumentDiff diff, bool isSource) {
    final String docId = diff.sourceDocument.id;
    final bool isExpanded = _expandedDocuments[docId] ?? false;

    // 确定文档是否存在于当前侧
    bool docExists = true;
    if (isSource && diff.diffType == DocumentDiffType.removed) {
      docExists = false;
    } else if (!isSource && diff.diffType == DocumentDiffType.added) {
      docExists = false;
    }

    // 获取文档数据
    final Map<String, dynamic>? docData = isSource
        ? _sourceDocuments[docId]
        : _targetDocuments[docId];

    // 如果文档不存在，显示占位符
    if (!docExists) {
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

    // 如果文档数据未加载，显示加载中
    if (docData == null) {
      return Card(
        margin: const EdgeInsets.all(4.0),
        child: ListTile(
          title: Text('文档 ID: $docId'),
          subtitle: const Text('加载中...'),
          leading: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 构建文档卡片
    return Card(
      margin: const EdgeInsets.all(4.0),
      color: _getDocumentCardColor(diff, isSource),
      child: Column(
        children: [
          // 文档标题行
          ListTile(
            title: Text('文档 ID: $docId'),
            subtitle: Text(_getDocumentStatusText(diff, isSource)),
            leading: _getDocumentIcon(diff, isSource),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _expandedDocuments[docId] = !isExpanded;
                });
              },
            ),
            selected: isSource
                ? _selectedSourcePath == docId
                : _selectedTargetPath == docId,
            onTap: () {
              setState(() {
                if (isSource) {
                  _selectedSourcePath = _selectedSourcePath == docId
                      ? null
                      : docId;
                  _selectedTargetPath = null;
                } else {
                  _selectedTargetPath = _selectedTargetPath == docId
                      ? null
                      : docId;
                  _selectedSourcePath = null;
                }
              });
            },
          ),

          // 展开的文档属性
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: _buildDocumentFields(
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

  // 构建文档字段树
  Widget _buildDocumentFields(
    Map<String, dynamic> data,
    DocumentDiff diff,
    bool isSource, {
    required String parentPath,
  }) {
    final List<Widget> fieldWidgets = [];

    // 对字段进行排序
    final List<String> sortedKeys = data.keys.toList()..sort();

    for (final key in sortedKeys) {
      final value = data[key];
      final String fieldPath = '$parentPath.$key';

      // 检查是否为忽略字段
      final bool isIgnored = widget.ignoredFields.contains(key);

      // 检查字段是否有差异
      final bool hasDiff = _hasFieldDiff(diff, key);

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
        if (value.isNotEmpty && value.first is Map) {
          isExpandable = true;
          nestedData = {};
          for (int i = 0; i < value.length; i++) {
            nestedData!['[$i]'] = value[i];
          }
        }
      } else {
        valueText = value.toString();
      }

      // 构建字段行
      final bool isExpanded = _expandedDocuments[fieldPath] ?? false;

      fieldWidgets.add(
        InkWell(
          onTap: () {
            setState(() {
              if (isSource) {
                _selectedSourcePath = _selectedSourcePath == fieldPath
                    ? null
                    : fieldPath;
                _selectedTargetPath = null;
              } else {
                _selectedTargetPath = _selectedTargetPath == fieldPath
                    ? null
                    : fieldPath;
                _selectedSourcePath = null;
              }
            });
          },
          child: Container(
            color: _getFieldBackgroundColor(
              isSource
                  ? _selectedSourcePath == fieldPath
                  : _selectedTargetPath == fieldPath,
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
                              fontWeight: FontWeight.bold,
                              color: _getFieldTextColor(isIgnored, hasDiff),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ': $valueText',
                            style: TextStyle(
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

  // 构建嵌套字段
  Widget _buildNestedFields(
    Map<String, dynamic> data,
    DocumentDiff diff,
    bool isSource, {
    required String parentPath,
  }) {
    final List<Widget> fieldWidgets = [];

    // 对字段进行排序
    final List<String> sortedKeys = data.keys.toList()..sort();

    for (final key in sortedKeys) {
      final value = data[key];
      final String fieldPath = '$parentPath.$key';

      // 检查是否为忽略字段
      final bool isIgnored = widget.ignoredFields.contains(key);

      // 检查字段是否有差异
      final bool hasDiff = _hasFieldDiff(diff, key);

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
        if (value.isNotEmpty && value.first is Map) {
          isExpandable = true;
          nestedData = {};
          for (int i = 0; i < value.length; i++) {
            nestedData!['[$i]'] = value[i];
          }
        }
      } else {
        valueText = value.toString();
      }

      // 构建字段行
      final bool isExpanded = _expandedDocuments[fieldPath] ?? false;

      fieldWidgets.add(
        InkWell(
          onTap: () {
            setState(() {
              if (isSource) {
                _selectedSourcePath = _selectedSourcePath == fieldPath
                    ? null
                    : fieldPath;
                _selectedTargetPath = null;
              } else {
                _selectedTargetPath = _selectedTargetPath == fieldPath
                    ? null
                    : fieldPath;
                _selectedSourcePath = null;
              }
            });
          },
          child: Container(
            color: _getFieldBackgroundColor(
              isSource
                  ? _selectedSourcePath == fieldPath
                  : _selectedTargetPath == fieldPath,
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
                              fontWeight: FontWeight.bold,
                              color: _getFieldTextColor(isIgnored, hasDiff),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ': $valueText',
                            style: TextStyle(
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

  // 获取文档卡片颜色
  Color _getDocumentCardColor(DocumentDiff diff, bool isSource) {
    switch (diff.diffType) {
      case DocumentDiffType.added:
        return isSource
            ? Colors.green.withOpacity(0.1)
            : Theme.of(context).colorScheme.surfaceContainerLowest;
      case DocumentDiffType.removed:
        return !isSource
            ? Colors.red.withOpacity(0.1)
            : Theme.of(context).colorScheme.surfaceContainerLowest;
      case DocumentDiffType.modified:
        return Colors.amber.withOpacity(0.1);
      case DocumentDiffType.unchanged:
        return Theme.of(context).colorScheme.surfaceContainerLowest;
    }
  }

  // 获取文档图标
  Widget _getDocumentIcon(DocumentDiff diff, bool isSource) {
    switch (diff.diffType) {
      case DocumentDiffType.added:
        return Icon(
          Icons.add_circle,
          color: isSource ? Colors.green : Colors.grey,
        );
      case DocumentDiffType.removed:
        return Icon(
          Icons.remove_circle,
          color: !isSource ? Colors.red : Colors.grey,
        );
      case DocumentDiffType.modified:
        return const Icon(Icons.edit, color: Colors.amber);
      case DocumentDiffType.unchanged:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }

  // 获取文档状态文本
  String _getDocumentStatusText(DocumentDiff diff, bool isSource) {
    switch (diff.diffType) {
      case DocumentDiffType.added:
        return isSource ? '仅在源中存在' : '不存在';
      case DocumentDiffType.removed:
        return !isSource ? '仅在目标中存在' : '不存在';
      case DocumentDiffType.modified:
        return '已修改';
      case DocumentDiffType.unchanged:
        return '相同';
    }
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

  // 检查字段是否有差异
  bool _hasFieldDiff(DocumentDiff diff, String fieldPath) {
    if (diff.fieldDiffs == null) return false;
    return diff.fieldDiffs!.containsKey(fieldPath);
  }

  // 复制到源
  Future<void> _copyToSource() async {
    if (_selectedTargetPath == null) return;

    final parts = _selectedTargetPath!.split('.');
    final docId = parts.first;

    // 检查是否为文档级别操作
    if (parts.length == 1) {
      await _copyDocumentToSource(docId);
    } else {
      // 字段级别操作
      final fieldPath = parts.sublist(1).join('.');
      await _copyFieldToSource(docId, fieldPath);
    }
  }

  // 复制到目标
  Future<void> _copyToTarget() async {
    if (_selectedSourcePath == null) return;

    final parts = _selectedSourcePath!.split('.');
    final docId = parts.first;

    // 检查是否为文档级别操作
    if (parts.length == 1) {
      await _copyDocumentToTarget(docId);
    } else {
      // 字段级别操作
      final fieldPath = parts.sublist(1).join('.');
      await _copyFieldToTarget(docId, fieldPath);
    }
  }

  // 删除源
  Future<void> _deleteSource() async {
    if (_selectedSourcePath == null) return;

    final parts = _selectedSourcePath!.split('.');
    final docId = parts.first;

    // 检查是否为文档级别操作
    if (parts.length == 1) {
      await _deleteSourceDocument(docId);
    } else {
      // 字段级别操作
      final fieldPath = parts.sublist(1).join('.');
      await _deleteSourceField(docId, fieldPath);
    }
  }

  // 删除目标
  Future<void> _deleteTarget() async {
    if (_selectedTargetPath == null) return;

    final parts = _selectedTargetPath!.split('.');
    final docId = parts.first;

    // 检查是否为文档级别操作
    if (parts.length == 1) {
      await _deleteTargetDocument(docId);
    } else {
      // 字段级别操作
      final fieldPath = parts.sublist(1).join('.');
      await _deleteTargetField(docId, fieldPath);
    }
  }

  // 复制文档到源
  Future<void> _copyDocumentToSource() async {
    // 实现复制文档到源的逻辑
  }

  // 复制文档到目标
  Future<void> _copyDocumentToTarget(String docId) async {
    if (widget.sourceConnectionId == null ||
        widget.targetConnectionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('连接ID不可用')));
      return;
    }

    final sourceDoc = _sourceDocuments[docId];
    if (sourceDoc == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('源文档数据不可用')));
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: Text('确定要将文档 $docId 从源复制到目标吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context