import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';

// 使用SharedPreferences来存储设置，而不是Hive
// 这样可以避免与现有的Hive模型冲突

// 主题模式提供者
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

// 每页显示文档数量提供者
final pageSizeProvider = StateNotifierProvider<PageSizeNotifier, int>(
  (ref) => PageSizeNotifier(),
);

// 是否显示ObjectId提供者
final showObjectIdsProvider =
    StateNotifierProvider<ShowObjectIdsNotifier, bool>(
      (ref) => ShowObjectIdsNotifier(),
    );

// 是否区分大小写比较提供者
final caseSensitiveComparisonProvider =
    StateNotifierProvider<CaseSensitiveComparisonNotifier, bool>(
      (ref) => CaseSensitiveComparisonNotifier(),
    );

// 是否在同步前确认提供者
final confirmBeforeSyncProvider =
    StateNotifierProvider<ConfirmBeforeSyncNotifier, bool>(
      (ref) => ConfirmBeforeSyncNotifier(),
    );

// 是否启用日志记录提供者
final enableLoggingProvider =
    StateNotifierProvider<EnableLoggingNotifier, bool>(
      (ref) => EnableLoggingNotifier(),
    );

// 最大加载文档数量提供者
final maxDocumentsProvider = StateNotifierProvider<MaxDocumentsNotifier, int>(
  (ref) => MaxDocumentsNotifier(),
);

// 默认规则ID提供者
final defaultRuleIdProvider =
    StateNotifierProvider<DefaultRuleIdNotifier, String?>(
      (ref) => DefaultRuleIdNotifier(),
    );

// 主题模式状态管理
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _repository = SettingsRepository();

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final settings = _repository.getSettings();
    state = ThemeMode.values[settings.themeModeIndex];
  }

  @override
  set state(ThemeMode value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(ThemeMode value) async {
    await _repository.updateThemeMode(value);
  }
}

// 每页显示文档数量状态管理
class PageSizeNotifier extends StateNotifier<int> {
  final SettingsRepository _repository = SettingsRepository();

  PageSizeNotifier() : super(20) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final settings = _repository.getSettings();
    state = settings.pageSize;
  }

  @override
  set state(int value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(int value) async {
    await _repository.updatePageSize(value);
  }
}

// 是否显示ObjectId状态管理
class ShowObjectIdsNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository = SettingsRepository();

  ShowObjectIdsNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final settings = _repository.getSettings();
    state = settings.showObjectIds;
  }

  @override
  set state(bool value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(bool value) async {
    await _repository.updateShowObjectIds(value);
  }
}

// 是否区分大小写比较状态管理
class CaseSensitiveComparisonNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository = SettingsRepository();

  CaseSensitiveComparisonNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final settings = _repository.getSettings();
    state = settings.caseSensitiveComparison;
  }

  @override
  set state(bool value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(bool value) async {
    await _repository.updateCaseSensitiveComparison(value);
  }
}

// 是否在同步前确认状态管理
class ConfirmBeforeSyncNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository = SettingsRepository();

  ConfirmBeforeSyncNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final settings = _repository.getSettings();
    state = settings.confirmBeforeSync;
  }

  @override
  set state(bool value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(bool value) async {
    await _repository.updateConfirmBeforeSync(value);
  }
}

// 是否启用日志记录状态管理
class EnableLoggingNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository = SettingsRepository();

  EnableLoggingNotifier() : super(false) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final settings = _repository.getSettings();
    state = settings.enableLogging;
  }

  @override
  set state(bool value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(bool value) async {
    await _repository.updateEnableLogging(value);
  }
}

// 最大加载文档数量状态管理
class MaxDocumentsNotifier extends StateNotifier<int> {
  final SettingsRepository _repository = SettingsRepository();

  MaxDocumentsNotifier() : super(2000) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final settings = _repository.getSettings();
    state = settings.maxDocuments;
  }

  @override
  set state(int value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(int value) async {
    await _repository.updateMaxDocuments(value);
  }
}

// 默认规则ID状态管理
class DefaultRuleIdNotifier extends StateNotifier<String?> {
  final SettingsRepository _repository = SettingsRepository();

  DefaultRuleIdNotifier() : super(null) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final settings = _repository.getSettings();
    state = settings.defaultRuleId;
  }

  @override
  set state(String? value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(String? value) async {
    await _repository.updateDefaultRuleId(value);
  }
}
