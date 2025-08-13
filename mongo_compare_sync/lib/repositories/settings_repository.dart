import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  static const String _boxName = 'app_settings';
  static const String _settingsId = 'app_settings_id';
  late Box<AppSettings> _settingsBox;

  // 单例模式
  static SettingsRepository? _instance;

  factory SettingsRepository() {
    _instance ??= SettingsRepository._internal();
    return _instance!;
  }

  SettingsRepository._internal();

  // 初始化存储库
  Future<void> init() async {
    Hive.registerAdapter(AppSettingsAdapter());
    _settingsBox = await Hive.openBox<AppSettings>(_boxName);

    // 如果没有设置，创建默认设置
    if (_settingsBox.isEmpty) {
      final defaultSettings = AppSettings(id: _settingsId);
      await _settingsBox.put(_settingsId, defaultSettings);
    }
  }

  // 获取设置
  AppSettings getSettings() {
    return _settingsBox.get(_settingsId) ?? AppSettings(id: _settingsId);
  }

  // 保存设置
  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(_settingsId, settings);
  }

  // 更新主题模式
  // Future<void> updateThemeMode(ThemeMode themeMode) async {
  //   final settings = getSettings();
  //   settings.themeMode = themeMode;
  //   await saveSettings(settings);
  // }

  // 更新语言
  Future<void> updateLocale(String locale) async {
    final settings = getSettings();
    settings.locale = locale;
    await saveSettings(settings);
  }

  // 更新页面大小
  Future<void> updatePageSize(int pageSize) async {
    final settings = getSettings();
    settings.pageSize = pageSize;
    await saveSettings(settings);
  }

  // 更新是否显示ObjectId
  Future<void> updateShowObjectIds(bool showObjectIds) async {
    final settings = getSettings();
    settings.showObjectIds = showObjectIds;
    await saveSettings(settings);
  }

  // 更新默认规则ID
  Future<void> updateDefaultRuleId(String? defaultRuleId) async {
    final settings = getSettings();
    settings.defaultRuleId = defaultRuleId;
    await saveSettings(settings);
  }

  // 更新是否区分大小写比较
  Future<void> updateCaseSensitiveComparison(
    bool caseSensitiveComparison,
  ) async {
    final settings = getSettings();
    settings.caseSensitiveComparison = caseSensitiveComparison;
    await saveSettings(settings);
  }

  // 更新默认导出格式
  Future<void> updateDefaultExportFormat(
    ExportFormat defaultExportFormat,
  ) async {
    final settings = getSettings();
    settings.defaultExportFormat = defaultExportFormat;
    await saveSettings(settings);
  }

  // 更新是否在同步前确认
  Future<void> updateConfirmBeforeSync(bool confirmBeforeSync) async {
    final settings = getSettings();
    settings.confirmBeforeSync = confirmBeforeSync;
    await saveSettings(settings);
  }

  // 更新是否启用日志记录
  Future<void> updateEnableLogging(bool enableLogging) async {
    final settings = getSettings();
    settings.enableLogging = enableLogging;
    await saveSettings(settings);
  }
}
