import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Center;
import '../models/document.dart';
import '../services/mongo_service.dart';
import '../providers/connection_provider.dart';

class DocumentTreeComparisonScreen extends ConsumerStatefulWidget {
  final List<DocumentDiff> results;
  final String sourceCollection;
  final String targetCollection;
  final String sourceDatabaseName;
  final String targetDatabaseName;
  final String? sourceConnectionId;
  final String? targetConnectionId;
  final String? idField;
  final List<String> ignoredFields;

  const DocumentTreeComparisonScreen({
    super.key,
    required this.results,
    required this.sourceCollection,
    required this.targetCollection,
    required this.sourceDatabaseName,
    required this.targetDatabaseName,
    this.sourceConnectionId,
    this.targetConnectionId,
    this.idField = '_id',
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

  // MongoDB服务实例
  late final MongoService _mongoService;

  @override
  void initState() {
    super.initState();
    // 在didChangeDependencies中初始化
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mongoService = ref.read(mongoServiceProvider);
    _loadDocuments();
  }

  // 从数据库重新加载数据
  Future<void> _reloadFromDatabase() async {
    await _loadDocuments();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已从数据库重新加载文档数据')));
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
      // 从源数据库加载全量文档
      if (widget.sourceConnectionId != null) {
        try {
          final sourceDocs = await _mongoService.getDocuments(
            widget.sourceConnectionId!,
            widget.sourceDatabaseName,
            widget.sourceCollection,
            limit: 0, // 获取所有文档
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

      // 从目标数据库加载全量文档
      if (widget.targetConnectionId != null) {
        try {
          final targetDocs = await _mongoService.getDocuments(
            widget.targetConnectionId!,
            widget.targetDatabaseName,
            widget.targetCollection,
            limit: 0, // 获取所有文档
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
      widget.results.clear();
      // 取源、目标文档的所有id并集，然后进行比较
      final ids = {..._sourceDocuments.keys, ..._targetDocuments.keys}.toList();
      // 更新差异状态
      for (int i = 0; i < ids.length; i++) {
        final docId = ids[i];
        final sourceDoc = _sourceDocuments[docId];
        final targetDoc = _targetDocuments[docId];

        // 比较文档字段
        final fieldDiffs = <String, FieldDiff>{};
        if (sourceDoc != null && targetDoc != null) {
          _compareDocument(sourceDoc, targetDoc, '', fieldDiffs);
        }
        widget.results.add(
          DocumentDiff(
            id: docId,
            sourceDocument: sourceDoc,
            targetDocument: targetDoc,
            fieldDiffs: fieldDiffs,
          ),
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文档比较已更新')));
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

  // 比较两个文档的字段
  void _compareDocument(
    Map<String, dynamic> sourceDoc,
    Map<String, dynamic> targetDoc,
    String parentPath,
    Map<String, FieldDiff> fieldDiffs,
  ) {
    // 获取所有字段名
    final Set<String> allFields = {...sourceDoc.keys, ...targetDoc.keys};

    for (final field in allFields) {
      // 跳过忽略的字段
      if (field == "_id" && widget.idField != "_id") continue;
      if (widget.ignoredFields.contains(field)) continue;

      final String fieldPath = parentPath.isEmpty
          ? field
          : '$parentPath.$field';
      final sourceValue = sourceDoc[field];
      final targetValue = targetDoc[field];

      // 字段只存在于一侧
      if (!sourceDoc.containsKey(field)) {
        fieldDiffs[fieldPath] = FieldDiff(
          fieldPath: fieldPath,
          sourceValue: null,
          targetValue: targetValue,
          status: 'added',
        );
        continue;
      }

      if (!targetDoc.containsKey(field)) {
        fieldDiffs[fieldPath] = FieldDiff(
          fieldPath: fieldPath,
          sourceValue: sourceValue,
          targetValue: null,
          status: 'removed',
        );
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
      } else if (sourceValue != targetValue) {
        // 值不同
        fieldDiffs[fieldPath] = FieldDiff(
          fieldPath: fieldPath,
          sourceValue: sourceValue,
          targetValue: targetValue,
          status: 'modified',
        );
      }
    }
  }

  /// 从文档中提取ID字段的值
  String _extractDocumentId(Map<String, dynamic> doc) {
    return (doc.containsKey(widget.idField))
        ? doc[widget.idField].toString()
        : doc['_id'].toString();
  }

  @override
  Widget build(BuildContext context) {
    // 对文档进行排序：先显示两边都存在的文档，再显示只在一边存在的文档
    final sortedResults = widget.results;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '文档比较: ${widget.sourceCollection} vs ${widget.targetCollection}',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildComparisonView(sortedResults),
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

  // 构建操作按钮栏
  Widget _buildActionBar() {
    final bool canCopyToSource = _selectedTargetPath != null;
    final bool canCopyToTarget = _selectedSourcePath != null;
    final bool canDeleteSource = _selectedSourcePath != null;
    final bool canDeleteTarget = _selectedTargetPath != null;

    // 判断选择的是文档还是属性
    String? sourceSelectionType;
    String? targetSelectionType;

    if (_selectedSourcePath != null) {
      sourceSelectionType = _selectedSourcePath!.contains('.') ? '属性' : '文档';
    }

    if (_selectedTargetPath != null) {
      targetSelectionType = _selectedTargetPath!.contains('.') ? '属性' : '文档';
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
                    targetSelectionType != null
                        ? '复制${targetSelectionType}到源'
                        : '复制到源',
                  ),
                  onPressed: canCopyToSource ? _copyToSource : null,
                ),
                const SizedBox(width: 8),
                // 删除源按钮
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: Text(
                    sourceSelectionType != null
                        ? '删除${sourceSelectionType}'
                        : '删除',
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
                    targetSelectionType != null
                        ? '删除${targetSelectionType}'
                        : '删除',
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
                    sourceSelectionType != null
                        ? '复制${sourceSelectionType}到目标'
                        : '复制到目标',
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
    final bool isSelected = isSource
        ? _selectedSourcePath == docId
        : _selectedTargetPath == docId;

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
              '文档 ID: $docId',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            nestedData['[$i]'] = value[i];
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
            nestedData['[$i]'] = value[i];
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

  // 获取文档图标
  Widget _getDocumentIcon(DocumentDiff diff, bool isSource) {
    return diff.sourceDocument == null || diff.targetDocument == null
        ? Icon(Icons.add_circle, color: isSource ? Colors.green : Colors.grey)
        : diff.fieldDiffs?.keys.isEmpty == true
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.edit, color: Colors.amber);
  }

  // 获取文档状态文本
  String _getDocumentStatusText(DocumentDiff diff, bool isSource) {
    return diff.sourceDocument == null || diff.targetDocument == null
        ? (diff.sourceDocument != null
              ? (isSource ? '仅在源中存在' : '不存在')
              : (!isSource ? '仅在目标中存在' : '不存在'))
        : diff.fieldDiffs?.keys.isEmpty == true
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

  // 删除源
  Future<void> _deleteSource() async {
    if (_selectedSourcePath == null) return;

    final parts = _selectedSourcePath!.split('.');
    final docId = parts.first;

    // 确认删除
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除源文档 $docId 吗？'),
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
      _processingMessage = '正在删除源文档...';
    });

    try {
      if (widget.sourceConnectionId != null) {
        // 将字符串ID转换为ObjectId
        final objectId = _convertToObjectId(docId);
        await _mongoService.deleteDocument(
          widget.sourceConnectionId!,
          widget.sourceDatabaseName,
          widget.sourceCollection,
          objectId,
        );

        // 更新本地数据
        setState(() {
          _sourceDocuments.remove(docId);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('源文档已删除')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除源文档失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 删除目标
  Future<void> _deleteTarget() async {
    if (_selectedTargetPath == null) return;

    final parts = _selectedTargetPath!.split('.');
    final docId = parts.first;

    // 确认删除
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除目标文档 $docId 吗？'),
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
      _processingMessage = '正在删除目标文档...';
    });

    try {
      if (widget.targetConnectionId != null) {
        // 将字符串ID转换为ObjectId
        final objectId = _convertToObjectId(docId);
        await _mongoService.deleteDocument(
          widget.targetConnectionId!,
          widget.targetDatabaseName,
          widget.targetCollection,
          objectId,
        );

        // 更新本地数据
        setState(() {
          _targetDocuments.remove(docId);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('目标文档已删除')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除目标文档失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 复制文档到源
  Future<void> _copyDocumentToSource(String docId) async {
    if (widget.sourceConnectionId == null) return;

    // 获取目标文档
    final targetDoc = _targetDocuments[docId];
    if (targetDoc == null) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制文档到源...';
    });

    try {
      // 检查源文档是否已存在
      final sourceDoc = _sourceDocuments[docId];
      if (sourceDoc != null) {
        // 文档已存在，使用更新
        final objectId = _convertToObjectId(docId);
        final docToUpdate = Map<String, dynamic>.from(targetDoc);
        docToUpdate.remove('_id'); // 移除_id字段，避免更新错误
        await _mongoService.updateDocument(
          widget.sourceConnectionId!,
          widget.sourceDatabaseName,
          widget.sourceCollection,
          objectId,
          docToUpdate,
        );
      } else {
        // 文档不存在，使用插入
        await _mongoService.insertDocument(
          widget.sourceConnectionId!,
          widget.sourceDatabaseName,
          widget.sourceCollection,
          targetDoc,
        );
      }

      // 更新本地数据
      setState(() {
        _sourceDocuments[docId] = Map<String, dynamic>.from(targetDoc);
      });

      // 更新文档差异状态
      _updateDocumentDiff(docId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文档已复制到源')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制文档到源失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 复制字段到源
  Future<void> _copyFieldToSource(String docId, String fieldPath) async {
    if (widget.sourceConnectionId == null) return;

    // 获取源文档和目标文档
    final sourceDoc = _sourceDocuments[docId];
    final targetDoc = _targetDocuments[docId];

    if (sourceDoc == null || targetDoc == null) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制字段到源...';
    });

    try {
      // 从目标文档中获取字段值
      final fieldValue = _getNestedValue(targetDoc, fieldPath.split('.'));

      // 更新源文档中的字段值
      final updatedSourceDoc = Map<String, dynamic>.from(sourceDoc);
      _setNestedValue(updatedSourceDoc, fieldPath.split('.'), fieldValue);

      // 保存更新后的源文档
      final objectId = _convertToObjectId(docId);
      final docToUpdate = Map<String, dynamic>.from(updatedSourceDoc);
      docToUpdate.remove('_id'); // 移除_id字段，避免更新错误
      await _mongoService.updateDocument(
        widget.sourceConnectionId!,
        widget.sourceDatabaseName,
        widget.sourceCollection,
        objectId,
        docToUpdate,
      );

      // 更新本地数据
      setState(() {
        _sourceDocuments[docId] = updatedSourceDoc;
      });

      // 更新文档差异状态
      _updateDocumentDiff(docId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('字段 $fieldPath 已复制到源')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制字段到源失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 复制文档到目标
  Future<void> _copyDocumentToTarget(String docId) async {
    if (widget.targetConnectionId == null) return;

    // 获取源文档
    final sourceDoc = _sourceDocuments[docId];
    if (sourceDoc == null) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制文档到目标...';
    });

    try {
      // 检查目标文档是否已存在
      final targetDoc = _targetDocuments[docId];
      if (targetDoc != null) {
        // 文档已存在，使用更新
        final objectId = _convertToObjectId(docId);
        final docToUpdate = Map<String, dynamic>.from(sourceDoc);
        docToUpdate.remove('_id'); // 移除_id字段，避免更新错误
        await _mongoService.updateDocument(
          widget.targetConnectionId!,
          widget.targetDatabaseName,
          widget.targetCollection,
          objectId,
          docToUpdate,
        );
      } else {
        // 文档不存在，使用插入
        await _mongoService.insertDocument(
          widget.targetConnectionId!,
          widget.targetDatabaseName,
          widget.targetCollection,
          sourceDoc,
        );
      }

      // 更新本地数据
      setState(() {
        _targetDocuments[docId] = Map<String, dynamic>.from(sourceDoc);
      });

      // 更新文档差异状态
      _updateDocumentDiff(docId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文档已复制到目标')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制文档到目标失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 复制字段到目标
  Future<void> _copyFieldToTarget(String docId, String fieldPath) async {
    if (widget.targetConnectionId == null) return;

    // 获取源文档和目标文档
    final sourceDoc = _sourceDocuments[docId];
    final targetDoc = _targetDocuments[docId];

    if (sourceDoc == null || targetDoc == null) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制字段到目标...';
    });

    try {
      // 从源文档中获取字段值
      final fieldValue = _getNestedValue(sourceDoc, fieldPath.split('.'));

      // 更新目标文档中的字段值
      final updatedTargetDoc = Map<String, dynamic>.from(targetDoc);
      _setNestedValue(updatedTargetDoc, fieldPath.split('.'), fieldValue);

      // 保存更新后的目标文档
      final objectId = _convertToObjectId(docId);
      final docToUpdate = Map<String, dynamic>.from(updatedTargetDoc);
      docToUpdate.remove('_id'); // 移除_id字段，避免更新错误
      await _mongoService.updateDocument(
        widget.targetConnectionId!,
        widget.targetDatabaseName,
        widget.targetCollection,
        objectId,
        docToUpdate,
      );

      // 更新本地数据
      setState(() {
        _targetDocuments[docId] = updatedTargetDoc;
      });

      // 更新文档差异状态
      _updateDocumentDiff(docId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('字段 $fieldPath 已复制到目标')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制字段到目标失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 更新文档差异状态
  void _updateDocumentDiff(String docId) {
    // 获取源文档和目标文档
    final sourceDoc = _sourceDocuments[docId];
    final targetDoc = _targetDocuments[docId];

    // 如果两边都有文档，重新比较差异
    if (sourceDoc != null && targetDoc != null) {
      // 查找现有的差异记录
      int index = widget.results.indexWhere((diff) => diff.id == docId);

      // 重新计算字段差异
      final fieldDiffs = <String, FieldDiff>{};
      _compareDocument(sourceDoc, targetDoc, '', fieldDiffs);

      // 更新差异记录
      if (index >= 0) {
        // 更新现有记录
        setState(() {
          widget.results[index] = DocumentDiff(
            id: docId,
            sourceDocument: sourceDoc,
            targetDocument: targetDoc,
            fieldDiffs: fieldDiffs,
          );
        });
      } else {
        // 添加新记录
        setState(() {
          widget.results.add(
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

  // 获取嵌套字段值
  dynamic _getNestedValue(Map<String, dynamic> doc, List<String> pathParts) {
    dynamic current = doc;

    for (final part in pathParts) {
      if (current is! Map) return null;

      if (part.startsWith('[') && part.endsWith(']')) {
        // 处理数组索引
        final indexStr = part.substring(1, part.length - 1);
        final index = int.tryParse(indexStr);

        if (index != null && current is List && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        // 处理对象属性
        current = current[part];
      }

      if (current == null) return null;
    }

    return current;
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
      if (parent is! Map) return;

      if (part.startsWith('[') && part.endsWith(']')) {
        // 处理数组索引
        final indexStr = part.substring(1, part.length - 1);
        final index = int.tryParse(indexStr);

        if (index != null && parent is List && index < parent.length) {
          parent = parent[index];
        } else {
          return;
        }
      } else {
        // 处理对象属性
        if (!parent.containsKey(part)) {
          parent[part] = {};
        }
        parent = parent[part];
      }
    }

    // 设置字段值
    if (lastPart.startsWith('[') && lastPart.endsWith(']')) {
      // 处理数组索引
      final indexStr = lastPart.substring(1, lastPart.length - 1);
      final index = int.tryParse(indexStr);

      if (index != null && parent is List && index < parent.length) {
        parent[index] = value;
      }
    } else {
      // 处理对象属性
      parent[lastPart] = value;
    }
  }
}
