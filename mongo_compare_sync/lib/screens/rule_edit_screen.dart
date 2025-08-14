import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compare_rule.dart';
import '../providers/rule_provider.dart';
import '../widgets/field_rule_item.dart';

class RuleEditScreen extends ConsumerStatefulWidget {
  final CompareRule? rule;

  const RuleEditScreen({super.key, this.rule});

  @override
  ConsumerState<RuleEditScreen> createState() => _RuleEditScreenState();
}

class _RuleEditScreenState extends ConsumerState<RuleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  late List<FieldRule> _fieldRules;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.rule != null;
    _name = widget.rule?.name ?? '';
    _description = widget.rule?.description ?? '';
    _fieldRules = List.from(widget.rule?.fieldRules ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑规则' : '创建规则'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存规则',
            onPressed: _saveRule,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 规则名称
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(
                labelText: '规则名称',
                hintText: '输入规则名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入规则名称';
                }
                return null;
              },
              onSaved: (value) {
                _name = value ?? '';
              },
            ),
            const SizedBox(height: 16),

            // 规则描述
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(
                labelText: '规则描述',
                hintText: '输入规则描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSaved: (value) {
                _description = value ?? '';
              },
            ),
            const SizedBox(height: 24),

            // 字段规则列表
            _buildFieldRulesList(),

            // 添加字段规则按钮
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addFieldRule,
              icon: const Icon(Icons.add),
              label: const Text('添加字段规则'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRulesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '字段规则',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_fieldRules.length} 个规则',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        ..._fieldRules.asMap().entries.map((entry) {
          final index = entry.key;
          final fieldRule = entry.value;
          return FieldRuleItem(
            fieldRule: fieldRule,
            onEdit: () => _editFieldRule(index),
            onDelete: () => _deleteFieldRule(index),
          );
        }),
        if (_fieldRules.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '没有字段规则',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }

  void _addFieldRule() {
    _showFieldRuleDialog();
  }

  void _editFieldRule(int index) {
    _showFieldRuleDialog(_fieldRules[index], index);
  }

  void _deleteFieldRule(int index) {
    setState(() {
      _fieldRules.removeAt(index);
    });
  }

  void _showFieldRuleDialog([FieldRule? fieldRule, int? editIndex]) {
    showDialog(
      context: context,
      builder: (context) => FieldRuleDialog(
        fieldRule: fieldRule,
        onSave: (rule) {
          setState(() {
            if (editIndex != null) {
              _fieldRules[editIndex] = rule;
            } else {
              _fieldRules.add(rule);
            }
          });
        },
      ),
    );
  }

  void _saveRule() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final rule = CompareRule(
        id: widget.rule?.id ?? const Uuid().v4(),
        name: _name,
        description: _description,
        fieldRules: _fieldRules,
      );

      if (_isEditing) {
        ref.read(rulesProvider.notifier).updateRule(rule);
      } else {
        ref.read(rulesProvider.notifier).addRule(rule);
      }

      Navigator.of(context).pop();
    }
  }
}

class FieldRuleDialog extends StatefulWidget {
  final FieldRule? fieldRule;
  final Function(FieldRule) onSave;

  const FieldRuleDialog({super.key, this.fieldRule, required this.onSave});

  @override
  State<FieldRuleDialog> createState() => _FieldRuleDialogState();
}

class _FieldRuleDialogState extends State<FieldRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _fieldPath;
  late RuleType _ruleType;
  late String _pattern;
  late String _transformFunction;
  late bool _isRegex;

  @override
  void initState() {
    super.initState();
    _fieldPath = widget.fieldRule?.fieldPath ?? '';
    _ruleType = widget.fieldRule?.ruleType ?? RuleType.ignore;
    _pattern = widget.fieldRule?.pattern ?? '';
    _transformFunction = widget.fieldRule?.transformFunction ?? '';
    _isRegex = widget.fieldRule?.isRegex ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.fieldRule == null ? '添加字段规则' : '编辑字段规则'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 字段路径
              TextFormField(
                initialValue: _fieldPath,
                decoration: const InputDecoration(
                  labelText: '字段路径',
                  hintText: '例如: user.name 或 *.createdAt',
                  helperText: '支持通配符 * 和 ?',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入字段路径';
                  }
                  return null;
                },
                onSaved: (value) {
                  _fieldPath = value ?? '';
                },
              ),
              const SizedBox(height: 16),

              // 规则类型
              DropdownButtonFormField<RuleType>(
                value: _ruleType,
                decoration: const InputDecoration(labelText: '规则类型'),
                items: RuleType.values.map((type) {
                  String label;
                  switch (type) {
                    case RuleType.ignore:
                      label = '忽略字段';
                      break;
                    case RuleType.transform:
                      label = '转换后比较';
                      break;
                    case RuleType.custom:
                      label = '自定义比较';
                      break;
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _ruleType = value!;
                  });
                },
                onSaved: (value) {
                  _ruleType = value!;
                },
              ),
              const SizedBox(height: 16),

              // 根据规则类型显示不同的选项
              if (_ruleType == RuleType.ignore) ...[
                // 是否使用正则表达式
                CheckboxListTile(
                  title: const Text('使用正则表达式'),
                  value: _isRegex,
                  onChanged: (value) {
                    setState(() {
                      _isRegex = value!;
                    });
                  },
                ),
              ] else if (_ruleType == RuleType.transform) ...[
                // 转换函数
                TextFormField(
                  initialValue: _transformFunction,
                  decoration: const InputDecoration(
                    labelText: '转换函数',
                    hintText: '例如: (value) => value.toString().toLowerCase()',
                  ),
                  maxLines: 3,
                  onSaved: (value) {
                    _transformFunction = value ?? '';
                  },
                ),
              ] else if (_ruleType == RuleType.custom) ...[
                // 自定义比较模式
                TextFormField(
                  initialValue: _pattern,
                  decoration: const InputDecoration(
                    labelText: '比较模式',
                    hintText: '例如: equals, contains, startsWith',
                  ),
                  onSaved: (value) {
                    _pattern = value ?? '';
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _saveFieldRule, child: const Text('保存')),
      ],
    );
  }

  void _saveFieldRule() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final fieldRule = FieldRule(
        fieldPath: _fieldPath,
        ruleType: _ruleType,
        pattern: _ruleType == RuleType.custom ? _pattern : null,
        transformFunction: _ruleType == RuleType.transform
            ? _transformFunction
            : null,
        isRegex: _ruleType == RuleType.ignore ? _isRegex : false,
      );

      widget.onSave(fieldRule);
      Navigator.of(context).pop();
    }
  }
}
