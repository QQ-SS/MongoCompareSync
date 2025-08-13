import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compare_rule.dart';
import '../providers/rule_provider.dart';
import 'rule_edit_screen.dart';

class RuleListScreen extends ConsumerStatefulWidget {
  const RuleListScreen({super.key});

  @override
  ConsumerState<RuleListScreen> createState() => _RuleListScreenState();
}

class _RuleListScreenState extends ConsumerState<RuleListScreen> {
  @override
  void initState() {
    super.initState();
    // 加载规则列表
    Future.microtask(() => ref.read(ruleRepositoryProvider).getAllRules());
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(rulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('比较规则管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '创建新规则',
            onPressed: () => _navigateToRuleEdit(context),
          ),
        ],
      ),
      body: rules.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return _buildRuleItem(context, rule);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rule_folder, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '没有比较规则',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右上角的加号创建新规则',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToRuleEdit(context),
            icon: const Icon(Icons.add),
            label: const Text('创建规则'),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, CompareRule rule) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(rule.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rule.description),
            const SizedBox(height: 4),
            Text(
              '${rule.fieldRules.length} 个字段规则',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        leading: const Icon(Icons.rule),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '编辑规则',
              onPressed: () => _navigateToRuleEdit(context, rule),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '删除规则',
              onPressed: () => _showDeleteConfirmation(context, rule),
            ),
          ],
        ),
        onTap: () => _navigateToRuleEdit(context, rule),
      ),
    );
  }

  void _navigateToRuleEdit(BuildContext context, [CompareRule? rule]) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => RuleEditScreen(rule: rule)));
  }

  void _showDeleteConfirmation(BuildContext context, CompareRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定要删除规则 "${rule.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(ruleRepositoryProvider).deleteRule(rule.id);
              Navigator.of(context).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
