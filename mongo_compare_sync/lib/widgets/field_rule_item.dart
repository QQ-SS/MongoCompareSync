import 'package:flutter/material.dart';
import '../models/compare_rule.dart';

class FieldRuleItem extends StatelessWidget {
  final FieldRule fieldRule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FieldRuleItem({
    super.key,
    required this.fieldRule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(fieldRule.fieldPath),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getRuleTypeText()),
            if (_getDetailText().isNotEmpty)
              Text(
                _getDetailText(),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        leading: _getRuleTypeIcon(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '编辑规则',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '删除规则',
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  String _getRuleTypeText() {
    switch (fieldRule.ruleType) {
      case RuleType.ignore:
        return '忽略字段';
      case RuleType.transform:
        return '转换后比较';
      case RuleType.custom:
        return '自定义比较';
    }
  }

  Icon _getRuleTypeIcon() {
    switch (fieldRule.ruleType) {
      case RuleType.ignore:
        return const Icon(Icons.visibility_off);
      case RuleType.transform:
        return const Icon(Icons.transform);
      case RuleType.custom:
        return const Icon(Icons.code);
    }
  }

  String _getDetailText() {
    switch (fieldRule.ruleType) {
      case RuleType.ignore:
        return fieldRule.isRegex ? '使用正则表达式' : '';
      case RuleType.transform:
        return fieldRule.transformFunction != null &&
                fieldRule.transformFunction!.isNotEmpty
            ? '转换函数: ${_truncateText(fieldRule.transformFunction!, 30)}'
            : '';
      case RuleType.custom:
        return fieldRule.pattern != null && fieldRule.pattern!.isNotEmpty
            ? '比较模式: ${fieldRule.pattern}'
            : '';
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
