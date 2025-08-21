import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/compare_rule.dart';

class CompareRuleRepository {
  static const String _fileName = 'compare_rules.json';
  List<CompareRule> _currentRules = []; // 内存中的规则列表

  // 单例模式
  static CompareRuleRepository? _instance;

  factory CompareRuleRepository() {
    _instance ??= CompareRuleRepository._internal();
    return _instance!;
  }

  CompareRuleRepository._internal();

  // 获取规则文件路径
  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  // 从文件读取规则
  Future<List<CompareRule>?> _readRulesFromFile() async {
    try {
      final file = File(await _getFilePath());
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        return jsonList.map((json) => CompareRule.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error reading rules from file: $e');
    }
    return null;
  }

  // 将规则写入文件
  Future<void> _writeRulesToFile(List<CompareRule> rules) async {
    try {
      final file = File(await _getFilePath());
      final json = jsonEncode(rules.map((rule) => rule.toJson()).toList());
      await file.writeAsString(json);
    } catch (e) {
      print('Error writing rules to file: $e');
    }
  }

  // 初始化存储库
  Future<void> init() async {
    _currentRules = (await _readRulesFromFile()) ?? [];
  }

  // 获取所有比较规则
  List<CompareRule> getAllRules() {
    return List.from(_currentRules); // 返回副本以防止外部修改
  }

  // 根据ID获取比较规则
  CompareRule? getRule(String id) {
    return _currentRules.firstWhereOrNull((rule) => rule.id == id);
  }

  // 保存比较规则
  Future<CompareRule> saveRule(CompareRule rule) async {
    final String id = rule.id.isEmpty ? const Uuid().v4() : rule.id;
    final updatedRule = rule.copyWith(id: id);

    final index = _currentRules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _currentRules[index] = updatedRule;
    } else {
      _currentRules.add(updatedRule);
    }
    await _writeRulesToFile(_currentRules);
    return updatedRule;
  }

  // 删除比较规则
  Future<void> deleteRule(String id) async {
    _currentRules.removeWhere((rule) => rule.id == id);
    await _writeRulesToFile(_currentRules);
  }

  // 导出所有规则到JSON字符串
  String exportRulesToJson() {
    return jsonEncode(_currentRules.map((rule) => rule.toJson()).toList());
  }

  // 从JSON字符串导入规则
  Future<List<CompareRule>> importRulesFromJson(String jsonString) async {
    try {
      final List<dynamic> rulesJson = jsonDecode(jsonString);
      final List<CompareRule> importedRules = [];

      for (var ruleJson in rulesJson) {
        final rule = CompareRule.fromJson(ruleJson);
        final newRule = rule.copyWith(id: const Uuid().v4()); // 生成新的ID
        await saveRule(newRule); // 保存导入的规则
        importedRules.add(newRule);
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

// 扩展List，提供firstWhereOrNull方法
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
