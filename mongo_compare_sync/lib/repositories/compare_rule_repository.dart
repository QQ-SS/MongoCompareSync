import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
