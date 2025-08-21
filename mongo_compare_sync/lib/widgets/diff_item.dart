import 'package:flutter/material.dart';

/// 差异类型枚举
enum DiffType {
  added, // 新增
  removed, // 删除
  modified, // 修改
}

/// 差异项组件，用于显示文档字段的差异
class DiffItem extends StatelessWidget {
  final String fieldPath;
  final dynamic sourceValue;
  final dynamic targetValue;
  final DiffType diffType;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const DiffItem({
    super.key,
    required this.fieldPath,
    required this.sourceValue,
    required this.targetValue,
    required this.diffType,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 差异项头部
          ListTile(
            title: Text(
              fieldPath,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_getDiffTypeText()),
            leading: _getDiffTypeIcon(),
            trailing: onToggleExpand != null
                ? IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: onToggleExpand,
                  )
                : null,
            tileColor: _getDiffTypeColor(context).withOpacity(0.1),
          ),

          // 差异项详情（展开时显示）
          if (isExpanded) _buildDiffDetails(context),
        ],
      ),
    );
  }

  /// 构建差异详情
  Widget _buildDiffDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 源值
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.only(right: 8),
                child: const Text(
                  '源值:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _buildValueDisplay(
                  sourceValue,
                  diffType == DiffType.removed
                      ? Colors.red.shade100
                      : diffType == DiffType.modified
                      ? Colors.amber.shade100
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 目标值
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.only(right: 8),
                child: const Text(
                  '目标值:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _buildValueDisplay(
                  targetValue,
                  diffType == DiffType.added
                      ? Colors.green.shade100
                      : diffType == DiffType.modified
                      ? Colors.amber.shade100
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建值的显示
  Widget _buildValueDisplay(dynamic value, Color? backgroundColor) {
    if (value == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'null',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    // 对于复杂类型（Map、List等），使用格式化的JSON显示
    String displayText;
    if (value is Map || value is List) {
      try {
        // 简单格式化，实际应用中可能需要更复杂的格式化
        displayText = value.toString();
      } catch (e) {
        displayText = value.toString();
      }
    } else {
      displayText = value.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontFamily: 'monospace',
          color: value == null ? Colors.grey : null,
        ),
      ),
    );
  }

  /// 获取差异类型的文本描述
  String _getDiffTypeText() {
    switch (diffType) {
      case DiffType.added:
        return '新增字段';
      case DiffType.removed:
        return '删除字段';
      case DiffType.modified:
        return '修改字段';
    }
  }

  /// 获取差异类型的图标
  Icon _getDiffTypeIcon() {
    switch (diffType) {
      case DiffType.added:
        return const Icon(Icons.add_circle, color: Colors.green);
      case DiffType.removed:
        return const Icon(Icons.remove_circle, color: Colors.red);
      case DiffType.modified:
        return const Icon(Icons.edit, color: Colors.amber);
    }
  }

  /// 获取差异类型的颜色
  Color _getDiffTypeColor(BuildContext context) {
    switch (diffType) {
      case DiffType.added:
        return Colors.green;
      case DiffType.removed:
        return Colors.red;
      case DiffType.modified:
        return Colors.amber;
    }
  }
}
