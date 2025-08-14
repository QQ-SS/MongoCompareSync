import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
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
          // 导入按钮
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: '导入规则',
            onPressed: () => _importRules(context),
          ),
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出规则',
            onPressed: () => _exportRules(context),
          ),
          // 添加按钮
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
              // 使用rulesProvider.notifier来删除规则，这样UI会自动更新
              ref.read(rulesProvider.notifier).deleteRule(rule.id);
              Navigator.of(context).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 导入规则
  Future<void> _importRules(BuildContext context) async {
    try {
      // 使用FilePicker让用户选择JSON文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择要导入的规则文件',
      );

      if (result == null || result.files.isEmpty) {
        // 用户取消了选择
        return;
      }

      final file = result.files.first;
      String? filePath = file.path;

      if (filePath == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法获取文件路径')));
        return;
      }

      // 导入规则
      final importedRules = await ref
          .read(ruleRepositoryProvider)
          .importRulesFromFile(filePath);

      if (importedRules.isNotEmpty) {
        // 刷新规则列表
        ref.read(rulesProvider.notifier).refreshRules();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 ${importedRules.length} 条规则')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导入规则失败或文件不包含有效规则')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入规则失败: $e')));
    }
  }

  // 导出规则
  Future<void> _exportRules(BuildContext context) async {
    try {
      // 获取规则的JSON字符串
      final jsonString = ref.read(ruleRepositoryProvider).exportRulesToJson();

      if (jsonString.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有规则可导出')));
        return;
      }

      // 使用FilePicker让用户选择保存位置
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName:
            'mongo_compare_rules_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath == null) {
        // 用户取消了选择
        return;
      }

      // 确保文件名以.json结尾
      if (!outputPath.endsWith('.json')) {
        outputPath = '$outputPath.json';
      }

      // 写入文件
      final file = File(outputPath);
      await file.writeAsString(jsonString);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('规则已导出到: $outputPath')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出规则失败: $e')));
    }
  }
}
