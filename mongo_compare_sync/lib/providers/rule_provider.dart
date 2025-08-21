import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compare_rule.dart';
import '../repositories/compare_rule_repository.dart';

// 规则存储库提供者
final ruleRepositoryProvider = Provider<CompareRuleRepository>((ref) {
  return CompareRuleRepository();
});

// 规则列表提供者
final rulesProvider = StateNotifierProvider<RulesNotifier, List<CompareRule>>((
  ref,
) {
  final repository = ref.watch(ruleRepositoryProvider);
  return RulesNotifier(repository);
});

// 规则列表状态管理
class RulesNotifier extends StateNotifier<List<CompareRule>> {
  final CompareRuleRepository _repository;

  RulesNotifier(this._repository) : super([]) {
    _loadRules();
  }

  // 加载所有规则
  Future<void> _loadRules() async {
    final rules = _repository.getAllRules();
    state = rules;
  }

  // 刷新规则列表
  Future<void> refreshRules() async {
    _loadRules();
  }

  // 添加新规则
  Future<void> addRule(CompareRule rule) async {
    await _repository.saveRule(rule);
    _loadRules();
  }

  // 更新规则
  Future<void> updateRule(CompareRule rule) async {
    await _repository.saveRule(rule);
    _loadRules();
  }

  // 删除规则
  Future<void> deleteRule(String id) async {
    await _repository.deleteRule(id);
    _loadRules();
  }
}
