import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/compare_rule.dart';
import '../models/hive_adapters.dart';

class CompareRuleRepository {
  static const String _boxName = 'compare_rules';
  late Box<CompareRule> _rulesBox;

  // 单例模式
  static CompareRuleRepository? _instance;

  factory CompareRuleRepository() {
    _instance ??= CompareRuleRepository._internal();
    return _instance!;
  }

  CompareRuleRepository._internal();

  // 初始化存储库
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CompareRuleAdapter());
    Hive.registerAdapter(FieldRuleAdapter());
    // RuleTypeAdapter已在models/hive_adapters.dart中注册
    _rulesBox = await Hive.openBox<CompareRule>(_boxName);
  }

  // 获取所有比较规则
  List<CompareRule> getAllRules() {
    return _rulesBox.values.toList();
  }

  // 根据ID获取比较规则
  CompareRule? getRule(String id) {
    return _rulesBox.get(id);
  }

  // 保存比较规则
  Future<CompareRule> saveRule(CompareRule rule) async {
    final String id = rule.id.isEmpty ? const Uuid().v4() : rule.id;
    final updatedRule = rule.copyWith(id: id);
    await _rulesBox.put(id, updatedRule);
    return updatedRule;
  }

  // 删除比较规则
  Future<void> deleteRule(String id) async {
    await _rulesBox.delete(id);
  }

  // 导出所有规则到JSON字符串
  String exportRulesToJson() {
    final rules = getAllRules();
    final List<Map<String, dynamic>> rulesJson = [];

    for (var rule in rules) {
      final Map<String, dynamic> ruleMap = {
        'name': rule.name,
        'description': rule.description,
        'fieldRules': rule.fieldRules
            .map(
              (fr) => {
                'fieldPath': fr.fieldPath,
                'ruleType': fr.ruleType.index,
                'pattern': fr.pattern,
                'transformFunction': fr.transformFunction,
                'isRegex': fr.isRegex,
              },
            )
            .toList(),
      };
      rulesJson.add(ruleMap);
    }

    return jsonEncode(rulesJson);
  }

  // 从JSON字符串导入规则
  Future<List<CompareRule>> importRulesFromJson(String jsonString) async {
    try {
      final List<dynamic> rulesJson = jsonDecode(jsonString);
      final List<CompareRule> importedRules = [];

      for (var ruleJson in rulesJson) {
        final List<FieldRule> fieldRules = [];

        for (var frJson in ruleJson['fieldRules']) {
          fieldRules.add(
            FieldRule(
              fieldPath: frJson['fieldPath'],
              ruleType: RuleType.values[frJson['ruleType']],
              pattern: frJson['pattern'],
              transformFunction: frJson['transformFunction'],
              isRegex: frJson['isRegex'],
            ),
          );
        }

        final rule = CompareRule(
          id: const Uuid().v4(), // 生成新的ID
          name: ruleJson['name'],
          description: ruleJson['description'],
          fieldRules: fieldRules,
        );

        // 保存导入的规则
        await saveRule(rule);
        importedRules.add(rule);
      }

      return importedRules;
    } catch (e) {
      print('导入规则失败: $e');
      return [];
    }
  }

  // 导出规则到文件
  Future<String?> exportRulesToFile() async {
    try {
      final jsonString = exportRulesToJson();

      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/mongo_compare_rules_$timestamp.json';

      // 写入文件
      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      print('导出规则到文件失败: $e');
      return null;
    }
  }

  // 从文件导入规则
  Future<List<CompareRule>> importRulesFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      return importRulesFromJson(jsonString);
    } catch (e) {
      print('从文件导入规则失败: $e');
      return [];
    }
  }
}

// Hive适配器
class CompareRuleAdapter extends TypeAdapter<CompareRule> {
  @override
  final int typeId = 1;

  @override
  CompareRule read(BinaryReader reader) {
    return CompareRule(
      id: reader.readString(),
      name: reader.readString(),
      description: reader.readString(),
      fieldRules: List<FieldRule>.from(reader.readList()),
    );
  }

  @override
  void write(BinaryWriter writer, CompareRule obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeList(obj.fieldRules);
  }
}

class FieldRuleAdapter extends TypeAdapter<FieldRule> {
  @override
  final int typeId = 2;

  @override
  FieldRule read(BinaryReader reader) {
    return FieldRule(
      fieldPath: reader.readString(),
      ruleType: reader.read() as RuleType,
      pattern: reader.readString(),
      transformFunction: reader.readString(),
      isRegex: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, FieldRule obj) {
    writer.writeString(obj.fieldPath);
    writer.write(obj.ruleType);
    writer.writeString(obj.pattern ?? '');
    writer.writeString(obj.transformFunction ?? '');
    writer.writeBool(obj.isRegex);
  }
}
