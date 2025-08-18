import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Center;
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

  // 从数据库重新加载数据
  Future<void> _reloadFromDatabase() async {
    setState(() {
      _isLoading = true;
      _sourceDocuments.clear();
      _targetDocuments.clear();
    });

    await _loadDocuments();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已从数据库重新加载文档数据')));
  }

  // 重新比较文档
  Future<void> _recompareDocuments() async {
    if (_sourceDocuments.isEmpty || _targetDocuments.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先加载文档数据')));
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在重新比较文档...';
    });

    try {
      // 更新差异状态
      for (int i = 0; i < widget.results.length; i++) {
        final docId = widget.results[i].sourceDocument.id;
        final sourceDoc = _sourceDocuments[docId];
        final targetDoc = _targetDocuments[docId];

        if (sourceDoc != null && targetDoc != null) {
          // 比较文档字段
          final fieldDiffs = <String, FieldDiff>{};
          _compareDocuments(sourceDoc, targetDoc, '', fieldDiffs);

          // 更新差异类型
          DocumentDiffType diffType = fieldDiffs.isEmpty
              ? DocumentDiffType.unchanged
              : DocumentDiffType.modified;

          widget.results[i] = DocumentDiff(
            sourceDocument: widget.results[i].sourceDocument,
            targetDocument: widget.results[i].targetDocument,
            diffType: diffType,
            fieldDiffs: fieldDiffs,
          );
        } else if (sourceDoc != null && targetDoc == null) {
          widget.results[i] = DocumentDiff(
            sourceDocument: widget.results[i].sourceDocument,
            targetDocument: widget.results[i].targetDocument,
            diffType: DocumentDiffType.added,
            fieldDiffs: {},
          );
        } else if (sourceDoc == null && targetDoc != null) {
          widget.results[i] = DocumentDiff(
            sourceDocument: widget.results[i].sourceDocument,
            targetDocument: widget.results[i].targetDocument,
            diffType: DocumentDiffType.removed,
            fieldDiffs: {},
          );
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文档比较已更新')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('重新比较文档失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 比较两个文档的字段
  void _compareDocuments(
    Map<String, dynamic> sourceDoc,
    Map<String, dynamic> targetDoc,
    String parentPath,
    Map<String, FieldDiff> fieldDiffs,
  ) {
    // 获取所有字段名
    final Set<String> allFields = {...sourceDoc.keys, ...targetDoc.keys};

    for (final field in allFields) {
      // 跳过忽略的字段
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
        _compareDocuments(
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
            // 处理ID格式
            ObjectId? objectId;
            String cleanId = id;

            // 检查ID是否已经是ObjectId("...")格式
            if (id.startsWith('ObjectId("') && id.endsWith('")')) {
              // 提取引号内的十六进制字符串
              cleanId = id.substring(10, id.length - 2);
              print('从ObjectId字符串中提取ID: $cleanId');
            }

            try {
              objectId = ObjectId.parse(cleanId);
              print('成功解析源文档ID为ObjectId: $cleanId');
            } catch (e) {
              print('无法将源文档ID解析为ObjectId: $cleanId, 错误: $e');
              // 如果无法解析为ObjectId，尝试使用字符串ID查询
              try {
                final docs = await widget.mongoService.getDocuments(
                  widget.sourceConnectionId!,
                  diff.sourceDocument.databaseName,
                  diff.sourceDocument.collectionName,
                  query: {'_id': cleanId},
                );
                if (docs.isNotEmpty) {
                  _sourceDocuments[id] = docs.first.data;
                  print('使用字符串ID成功加载源文档: $cleanId');
                  continue;
                }
              } catch (e2) {
                print('使用字符串ID查询源文档失败: $cleanId, 错误: $e2');
              }
              continue;
            }

            // 使用ObjectId查询文档
            try {
              final docs = await widget.mongoService.getDocuments(
                widget.sourceConnectionId!,
                diff.sourceDocument.databaseName,
                diff.sourceDocument.collectionName,
                query: {'_id': objectId},
              );
              if (docs.isNotEmpty) {
                _sourceDocuments[id] = docs.first.data;
                print('成功加载源文档: $id');
              } else {
                print('未找到源文档: $id');
              }
            } catch (e) {
              print('加载源文档失败: $id, 错误: $e');
            }
          } catch (e) {
            print('处理源文档时出错: $id, 错误: $e');
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
            // 处理ID格式
            ObjectId? objectId;
            String cleanId = id;

            // 检查ID是否已经是ObjectId("...")格式
            if (id.startsWith('ObjectId("') && id.endsWith('")')) {
              // 提取引号内的十六进制字符串
              cleanId = id.substring(10, id.length - 2);
              print('从ObjectId字符串中提取目标ID: $cleanId');
            }

            try {
              objectId = ObjectId.parse(cleanId);
              print('成功解析目标文档ID为ObjectId: $cleanId');
            } catch (e) {
              print('无法将目标文档ID解析为ObjectId: $cleanId, 错误: $e');
              // 如果无法解析为ObjectId，尝试使用字符串ID查询
              try {
                final docs = await widget.mongoService.getDocuments(
                  widget.targetConnectionId!,
                  diff.targetDocument!.databaseName,
                  diff.targetDocument!.collectionName,
                  query: {'_id': cleanId},
                );
                if (docs.isNotEmpty) {
                  _targetDocuments[id] = docs.first.data;
                  print('使用字符串ID成功加载目标文档: $cleanId');
                  continue;
                }
              } catch (e2) {
                print('使用字符串ID查询目标文档失败: $cleanId, 错误: $e2');
              }
              continue;
            }

            // 使用ObjectId查询文档
            try {
              final docs = await widget.mongoService.getDocuments(
                widget.targetConnectionId!,
                diff.targetDocument!.databaseName,
                diff.targetDocument!.collectionName,
                query: {'_id': objectId},
              );
              if (docs.isNotEmpty) {
                _targetDocuments[id] = docs.first.data;
                print('成功加载目标文档: $id');
              } else {
                print('未找到目标文档: $id');
              }
            } catch (e) {
              print('加载目标文档失败: $id, 错误: $e');
            }
          } catch (e) {
            print('处理目标文档时出错: $id, 错误: $e');
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

          // 中间刷新按钮
          Tooltip(
            message: '刷新数据并重新比较',
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
              onPressed: () async {
                await _reloadFromDatabase();
                await _recompareDocuments();
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
  Future<void> _copyDocumentToSource(String docId) async {
    if (widget.sourceConnectionId == null ||
        widget.targetConnectionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('连接ID不可用')));
      return;
    }

    // 获取目标文档数据
    Map<String, dynamic>? targetDoc = _targetDocuments[docId];

    // 如果本地没有缓存目标文档数据，尝试从数据库加载
    if (targetDoc == null) {
      try {
        // 获取文档差异信息
        final diff = widget.results.firstWhere(
          (d) => d.sourceDocument.id == docId,
          orElse: () => throw Exception('未找到文档差异信息'),
        );

        if (diff.targetDocument == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('目标文档不存在')));
          return;
        }

        // 处理ID格式
        String cleanId = docId;
        if (docId.startsWith('ObjectId("') && docId.endsWith('")')) {
          cleanId = docId.substring(10, docId.length - 2);
        }

        // 尝试从数据库加载目标文档
        final docs = await widget.mongoService.getDocuments(
          widget.targetConnectionId!,
          diff.targetDocument!.databaseName,
          diff.targetDocument!.collectionName,
          query: {'_id': ObjectId.parse(cleanId)},
        );

        if (docs.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('无法从数据库加载目标文档')));
          return;
        }

        // 使用从数据库加载的文档
        targetDoc = docs.first.data;
        // 更新本地缓存
        _targetDocuments[docId] = targetDoc;
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载目标文档失败: $e')));
        return;
      }
    }

    if (targetDoc == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目标文档数据不可用')));
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: Text('确定要将文档 $docId 从目标复制到源吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制文档...';
    });

    try {
      // 获取源文档的数据库和集合名称
      final diff = widget.results.firstWhere(
        (d) => d.sourceDocument.id == docId,
      );
      final sourceDb = diff.sourceDocument.databaseName;
      final sourceColl = diff.sourceDocument.collectionName;

      // 复制文档
      await widget.mongoService.updateDocument(
        widget.sourceConnectionId!,
        sourceDb,
        sourceColl,
        ObjectId.parse(docId),
        targetDoc,
      );

      // 更新本地数据
      setState(() {
        _sourceDocuments[docId] = Map<String, dynamic>.from(targetDoc!);

        // 更新文档差异状态
        for (int i = 0; i < widget.results.length; i++) {
          if (widget.results[i].sourceDocument.id == docId) {
            // 如果是已删除文档（源中不存在），则更新差异类型为已修改
            if (widget.results[i].diffType == DocumentDiffType.removed) {
              widget.results[i] = DocumentDiff(
                sourceDocument: MongoDocument(
                  id: docId,
                  data: Map<String, dynamic>.from(targetDoc),
                  collectionName: widget.sourceCollection,
                  databaseName: widget.results[i].sourceDocument.databaseName,
                  connectionId: widget.sourceConnectionId ?? '',
                ),
                targetDocument: widget.results[i].targetDocument,
                diffType: DocumentDiffType.modified,
                fieldDiffs: {}, // 复制后字段差异为空
              );
            }
            break;
          }
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文档已成功复制到源')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 复制字段到源
  Future<void> _copyFieldToSource(String docId, String fieldPath) async {
    if (widget.sourceConnectionId == null ||
        widget.targetConnectionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('连接ID不可用')));
      return;
    }

    final sourceDoc = _sourceDocuments[docId];
    final targetDoc = _targetDocuments[docId];
    if (sourceDoc == null || targetDoc == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文档数据不可用')));
      return;
    }

    // 获取字段值
    final fieldValue = _getNestedValue(targetDoc, fieldPath.split('.'));
    if (fieldValue == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('字段值不可用')));
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: Text('确定要将字段 $fieldPath 从目标复制到源吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制字段...';
    });

    try {
      // 获取源文档的数据库和集合名称
      final diff = widget.results.firstWhere(
        (d) => d.sourceDocument.id == docId,
      );
      final sourceDb = diff.sourceDocument.databaseName;
      final sourceColl = diff.sourceDocument.collectionName;

      // 更新字段
      // 获取完整文档并更新特定字段
      final updatedDoc = Map<String, dynamic>.from(sourceDoc);
      _setNestedValue(updatedDoc, fieldPath.split('.'), fieldValue);

      // 使用updateDocument方法更新整个文档
      await widget.mongoService.updateDocument(
        widget.sourceConnectionId!,
        sourceDb,
        sourceColl,
        ObjectId.parse(docId),
        updatedDoc,
      );

      // 更新本地数据
      final updatedSourceDoc = Map<String, dynamic>.from(sourceDoc);
      _setNestedValue(updatedSourceDoc, fieldPath.split('.'), fieldValue);
      setState(() {
        _sourceDocuments[docId] = updatedSourceDoc;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('字段已成功复制到源')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制文档...';
    });

    try {
      // 获取目标文档的数据库和集合名称
      final diff = widget.results.firstWhere(
        (d) => d.sourceDocument.id == docId,
      );
      final targetDb = diff.targetDocument?.databaseName ?? '';
      final targetColl = diff.targetDocument?.collectionName ?? '';

      if (targetDb.isEmpty || targetColl.isEmpty) {
        throw Exception('目标数据库或集合名称不可用');
      }

      // 复制文档 - 使用insertDocument或updateDocument
      try {
        // 先尝试更新文档
        await widget.mongoService.updateDocument(
          widget.targetConnectionId!,
          targetDb,
          targetColl,
          ObjectId.parse(docId),
          sourceDoc,
        );
      } catch (e) {
        // 如果更新失败（可能是文档不存在），则尝试插入
        await widget.mongoService.insertDocument(
          widget.targetConnectionId!,
          targetDb,
          targetColl,
          sourceDoc,
        );
      }

      // 更新本地数据
      setState(() {
        _targetDocuments[docId] = Map<String, dynamic>.from(sourceDoc);

        // 更新文档差异状态
        for (int i = 0; i < widget.results.length; i++) {
          if (widget.results[i].sourceDocument.id == docId) {
            // 如果是新增文档（目标中不存在），则更新差异类型为已修改
            if (widget.results[i].diffType == DocumentDiffType.added) {
              widget.results[i] = DocumentDiff(
                sourceDocument: widget.results[i].sourceDocument,
                targetDocument: MongoDocument(
                  id: docId,
                  data: Map<String, dynamic>.from(sourceDoc),
                  collectionName: widget.targetCollection,
                  databaseName:
                      widget.results[i].targetDocument?.databaseName ?? '',
                  connectionId: widget.targetConnectionId ?? '',
                ),
                diffType: DocumentDiffType.modified,
                fieldDiffs: {}, // 复制后字段差异为空
              );
            }
            break;
          }
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文档已成功复制到目标')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 复制字段到目标
  Future<void> _copyFieldToTarget(String docId, String fieldPath) async {
    if (widget.sourceConnectionId == null ||
        widget.targetConnectionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('连接ID不可用')));
      return;
    }

    final sourceDoc = _sourceDocuments[docId];
    final targetDoc = _targetDocuments[docId];
    if (sourceDoc == null || targetDoc == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文档数据不可用')));
      return;
    }

    // 获取字段值
    final fieldValue = _getNestedValue(sourceDoc, fieldPath.split('.'));
    if (fieldValue == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('字段值不可用')));
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: Text('确定要将字段 $fieldPath 从源复制到目标吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在复制字段...';
    });

    try {
      // 获取目标文档的数据库和集合名称
      final diff = widget.results.firstWhere(
        (d) => d.sourceDocument.id == docId,
      );
      final targetDb = diff.targetDocument?.databaseName ?? '';
      final targetColl = diff.targetDocument?.collectionName ?? '';

      if (targetDb.isEmpty || targetColl.isEmpty) {
        throw Exception('目标数据库或集合名称不可用');
      }

      // 更新字段 - 获取完整文档并更新特定字段
      final updatedDoc = Map<String, dynamic>.from(targetDoc);
      _setNestedValue(updatedDoc, fieldPath.split('.'), fieldValue);

      // 使用updateDocument方法更新整个文档
      await widget.mongoService.updateDocument(
        widget.targetConnectionId!,
        targetDb,
        targetColl,
        ObjectId.parse(docId),
        updatedDoc,
      );

      // 更新本地数据
      final updatedTargetDoc = Map<String, dynamic>.from(targetDoc);
      _setNestedValue(updatedTargetDoc, fieldPath.split('.'), fieldValue);
      setState(() {
        _targetDocuments[docId] = updatedTargetDoc;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('字段已成功复制到目标')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 删除源文档
  Future<void> _deleteSourceDocument(String docId) async {
    if (widget.sourceConnectionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('连接ID不可用')));
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除源文档 $docId 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在删除文档...';
    });

    try {
      // 获取源文档的数据库和集合名称
      final diff = widget.results.firstWhere(
        (d) => d.sourceDocument.id == docId,
      );
      final sourceDb = diff.sourceDocument.databaseName;
      final sourceColl = diff.sourceDocument.collectionName;

      // 删除文档
      await widget.mongoService.deleteDocument(
        widget.sourceConnectionId!,
        sourceDb,
        sourceColl,
        ObjectId.parse(docId),
      );

      // 更新本地数据
      setState(() {
        _sourceDocuments.remove(docId);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('源文档已成功删除')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 删除源字段
  Future<void> _deleteSourceField(String docId, String fieldPath) async {
    if (widget.sourceConnectionId == null) {
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
        title: const Text('确认删除'),
        content: Text('确定要删除源文档中的字段 $fieldPath 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在删除字段...';
    });

    try {
      // 获取源文档的数据库和集合名称
      final diff = widget.results.firstWhere(
        (d) => d.sourceDocument.id == docId,
      );
      final sourceDb = diff.sourceDocument.databaseName;
      final sourceColl = diff.sourceDocument.collectionName;

      // 删除字段 - 获取完整文档并删除特定字段
      final docWithDeletedField = Map<String, dynamic>.from(sourceDoc);
      _deleteNestedValue(docWithDeletedField, fieldPath.split('.'));

      // 使用updateDocument方法更新整个文档
      await widget.mongoService.updateDocument(
        widget.sourceConnectionId!,
        sourceDb,
        sourceColl,
        ObjectId.parse(docId),
        docWithDeletedField,
      );

      // 更新本地数据
      final updatedSourceDoc = Map<String, dynamic>.from(sourceDoc);
      _deleteNestedValue(updatedSourceDoc, fieldPath.split('.'));
      setState(() {
        _sourceDocuments[docId] = updatedSourceDoc;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('源字段已成功删除')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 删除目标文档
  Future<void> _deleteTargetDocument(String docId) async {
    if (widget.targetConnectionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('连接ID不可用')));
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除目标文档 $docId 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在删除文档...';
    });

    try {
      // 获取目标文档的数据库和集合名称
      final diff = widget.results.firstWhere(
        (d) => d.sourceDocument.id == docId,
      );
      final targetDb = diff.targetDocument?.databaseName ?? '';
      final targetColl = diff.targetDocument?.collectionName ?? '';

      if (targetDb.isEmpty || targetColl.isEmpty) {
        throw Exception('目标数据库或集合名称不可用');
      }

      // 删除文档
      await widget.mongoService.deleteDocument(
        widget.targetConnectionId!,
        targetDb,
        targetColl,
        ObjectId.parse(docId),
      );

      // 更新本地数据
      setState(() {
        _targetDocuments.remove(docId);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目标文档已成功删除')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 删除目标字段
  Future<void> _deleteTargetField(String docId, String fieldPath) async {
    if (widget.targetConnectionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('连接ID不可用')));
      return;
    }

    final targetDoc = _targetDocuments[docId];
    if (targetDoc == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目标文档数据不可用')));
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除目标文档中的字段 $fieldPath 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = '正在删除字段...';
    });

    try {
      // 获取目标文档的数据库和集合名称
      final diff = widget.results.firstWhere(
        (d) => d.sourceDocument.id == docId,
      );
      final targetDb = diff.targetDocument?.databaseName ?? '';
      final targetColl = diff.targetDocument?.collectionName ?? '';

      if (targetDb.isEmpty || targetColl.isEmpty) {
        throw Exception('目标数据库或集合名称不可用');
      }

      // 删除字段 - 获取完整文档并删除特定字段
      final targetDocWithDeletedField = Map<String, dynamic>.from(targetDoc);
      _deleteNestedValue(targetDocWithDeletedField, fieldPath.split('.'));

      // 使用updateDocument方法更新整个文档
      await widget.mongoService.updateDocument(
        widget.targetConnectionId!,
        targetDb,
        targetColl,
        ObjectId.parse(docId),
        targetDocWithDeletedField,
      );

      // 更新本地数据
      final updatedTargetDoc = Map<String, dynamic>.from(targetDoc);
      _deleteNestedValue(updatedTargetDoc, fieldPath.split('.'));
      setState(() {
        _targetDocuments[docId] = updatedTargetDoc;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目标字段已成功删除')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 获取嵌套字段值
  dynamic _getNestedValue(Map<String, dynamic> data, List<String> pathParts) {
    dynamic current = data;
    for (final part in pathParts) {
      if (current is! Map) return null;
      if (!current.containsKey(part)) return null;
      current = current[part];
    }
    return current;
  }

  // 设置嵌套字段值
  void _setNestedValue(
    Map<String, dynamic> data,
    List<String> pathParts,
    dynamic value,
  ) {
    if (pathParts.isEmpty) return;

    if (pathParts.length == 1) {
      data[pathParts.first] = value;
      return;
    }

    final firstPart = pathParts.first;
    final remainingParts = pathParts.sublist(1);

    if (!data.containsKey(firstPart) || data[firstPart] is! Map) {
      data[firstPart] = <String, dynamic>{};
    }

    _setNestedValue(
      data[firstPart] as Map<String, dynamic>,
      remainingParts,
      value,
    );
  }

  // 删除嵌套字段值
  void _deleteNestedValue(Map<String, dynamic> data, List<String> pathParts) {
    if (pathParts.isEmpty) return;

    if (pathParts.length == 1) {
      data.remove(pathParts.first);
      return;
    }

    final firstPart = pathParts.first;
    final remainingParts = pathParts.sublist(1);

    if (data.containsKey(firstPart) && data[firstPart] is Map) {
      _deleteNestedValue(
        data[firstPart] as Map<String, dynamic>,
        remainingParts,
      );
    }
  }
}
