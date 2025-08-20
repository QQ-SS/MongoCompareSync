import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? 0;
    state = ThemeMode.values[themeModeIndex];
  }

  @override
  set state(ThemeMode value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(ThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', value.index);
  }
}

// 每页显示文档数量状态管理
class PageSizeNotifier extends StateNotifier<int> {
  PageSizeNotifier() : super(20) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('pageSize') ?? 20;
  }

  @override
  set state(int value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pageSize', value);
  }
}

// 是否显示ObjectId状态管理
class ShowObjectIdsNotifier extends StateNotifier<bool> {
  ShowObjectIdsNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('showObjectIds') ?? true;
  }

  @override
  set state(bool value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showObjectIds', value);
  }
}

// 是否区分大小写比较状态管理
class CaseSensitiveComparisonNotifier extends StateNotifier<bool> {
  CaseSensitiveComparisonNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('caseSensitiveComparison') ?? true;
  }

  @override
  set state(bool value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('caseSensitiveComparison', value);
  }
}

// 是否在同步前确认状态管理
class ConfirmBeforeSyncNotifier extends StateNotifier<bool> {
  ConfirmBeforeSyncNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('confirmBeforeSync') ?? true;
  }

  @override
  set state(bool value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('confirmBeforeSync', value);
  }
}

// 是否启用日志记录状态管理
class EnableLoggingNotifier extends StateNotifier<bool> {
  EnableLoggingNotifier() : super(false) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('enableLogging') ?? false;
  }

  @override
  set state(bool value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableLogging', value);
  }
}

// 最大加载文档数量状态管理
class MaxDocumentsNotifier extends StateNotifier<int> {
  MaxDocumentsNotifier() : super(2000) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('maxDocuments') ?? 2000;
  }

  @override
  set state(int value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxDocuments', value);
  }
}

// 默认规则ID状态管理
class DefaultRuleIdNotifier extends StateNotifier<String?> {
  DefaultRuleIdNotifier() : super(null) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('defaultRuleId');
  }

  @override
  set state(String? value) {
    super.state = value;
    _saveSetting(value);
  }

  Future<void> _saveSetting(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value != null) {
      await prefs.setString('defaultRuleId', value);
    } else {
      await prefs.remove('defaultRuleId');
    }
  }
}
