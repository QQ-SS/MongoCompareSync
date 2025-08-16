import 'package:flutter/material.dart';

/// 文档树视图组件，用于显示MongoDB文档的树形结构
class DocumentTreeView extends StatefulWidget {
  /// 文档数据
  final Map<String, dynamic> document;

  /// 文档ID
  final String documentId;

  /// 忽略的字段列表
  final List<String> ignoredFields;

  /// 差异字段映射，键为字段路径，值为差异信息
  final Map<String, dynamic>? fieldDiffs;

  /// 选中节点的回调
  final Function(String path)? onNodeSelected;

  /// 当前选中的路径
  final String? selectedPath;

  const DocumentTreeView({
    super.key,
    required this.document,
    required this.documentId,
    this.ignoredFields = const [],
    this.fieldDiffs,
    this.onNodeSelected,
    this.selectedPath,
  });

  @override
  State<DocumentTreeView> createState() => _DocumentTreeViewState();
}

class _DocumentTreeViewState extends State<DocumentTreeView> {
  /// 存储展开状态的Map
  final Map<String, bool> _expandedNodes = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文档ID标题
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.article),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID: ${widget.documentId}',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 文档内容
            Expanded(
              child: SingleChildScrollView(
                child: _buildDocumentTree(widget.document),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建文档树
  Widget _buildDocumentTree(Map<String, dynamic> document) {
    final List<Widget> fieldWidgets = [];

    // 对字段进行排序
    final List<String> sortedKeys = document.keys.toList()..sort();

    for (final key in sortedKeys) {
      final value = document[key];
      final String fieldPath = key;

      // 检查是否为忽略字段
      final bool isIgnored = widget.ignoredFields.contains(key);

      // 检查字段是否有差异
      final bool hasDiff = _hasFieldDiff(fieldPath);

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
      final String nodePath = '${widget.documentId}.$fieldPath';
      final bool isExpanded = _expandedNodes[nodePath] ?? false;
      final bool isSelected = widget.selectedPath == nodePath;

      fieldWidgets.add(
        InkWell(
          onTap: () {
            if (widget.onNodeSelected != null) {
              widget.onNodeSelected!(nodePath);
            }
          },
          child: Container(
            color: _getFieldBackgroundColor(isSelected, isIgnored, hasDiff),
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
                        _expandedNodes[nodePath] = !isExpanded;
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
                          child: _buildNestedFields(nestedData, '$nodePath'),
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

  /// 构建嵌套字段
  Widget _buildNestedFields(Map<String, dynamic> data, String parentPath) {
    final List<Widget> fieldWidgets = [];

    // 对字段进行排序
    final List<String> sortedKeys = data.keys.toList()..sort();

    for (final key in sortedKeys) {
      final value = data[key];
      final String fieldPath = '$parentPath.$key';

      // 检查是否为忽略字段
      final bool isIgnored = widget.ignoredFields.contains(key);

      // 检查字段是否有差异
      final bool hasDiff = _hasFieldDiff(fieldPath);

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
      final bool isExpanded = _expandedNodes[fieldPath] ?? false;
      final bool isSelected = widget.selectedPath == fieldPath;

      fieldWidgets.add(
        InkWell(
          onTap: () {
            if (widget.onNodeSelected != null) {
              widget.onNodeSelected!(fieldPath);
            }
          },
          child: Container(
            color: _getFieldBackgroundColor(isSelected, isIgnored, hasDiff),
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
                        _expandedNodes[fieldPath] = !isExpanded;
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
                          child: _buildNestedFields(nestedData, fieldPath),
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

  /// 获取字段背景颜色
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

  /// 获取字段文本颜色
  Color _getFieldTextColor(bool isIgnored, bool hasDiff) {
    if (isIgnored) {
      return Theme.of(context).colorScheme.outline;
    }
    if (hasDiff) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  /// 检查字段是否有差异
  bool _hasFieldDiff(String fieldPath) {
    if (widget.fieldDiffs == null) return false;
    return widget.fieldDiffs!.containsKey(fieldPath);
  }
}
