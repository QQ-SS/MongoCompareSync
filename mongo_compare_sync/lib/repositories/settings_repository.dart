import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  static const String _fileName = 'app_settings.json';
  static const String _settingsId = 'app_settings_id'; // 保持ID不变
  AppSettings? _currentSettings; // 内存中的设置对象

  // 单例模式
  static SettingsRepository? _instance;

  factory SettingsRepository() {
    _instance ??= SettingsRepository._internal();
    return _instance!;
  }

  SettingsRepository._internal();

  // 获取设置文件路径
  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  // 从文件读取设置
  Future<AppSettings?> _readSettingsFromFile() async {
    try {
      final file = File(await _getFilePath());
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(contents);
        return AppSettings.fromJson(json);
      }
    } catch (e) {
      print('Error reading settings from file: $e');
    }
    return null;
  }

  // 将设置写入文件
  Future<void> _writeSettingsToFile(AppSettings settings) async {
    try {
      final file = File(await _getFilePath());
      final json = jsonEncode(settings.toJson());
      await file.writeAsString(json);
    } catch (e) {
      print('Error writing settings to file: $e');
    }
  }

  // 初始化存储库
  Future<void> init() async {
    _currentSettings = await _readSettingsFromFile();

    // 如果没有设置，创建默认设置并保存
    if (_currentSettings == null) {
      _currentSettings = AppSettings(id: _settingsId);
      await _writeSettingsToFile(_currentSettings!);
    }
  }

  // 获取设置
  AppSettings getSettings() {
    // 确保在调用此方法前 init() 已完成
    return _currentSettings ?? AppSettings(id: _settingsId);
  }

  // 保存设置
  Future<void> saveSettings(AppSettings settings) async {
    _currentSettings = settings; // 更新内存中的设置
    await _writeSettingsToFile(settings); // 异步写入文件
  }

  // 更新语言
  Future<void> updateLocale(String locale) async {
    final settings = getSettings().copyWith(locale: locale);
    await saveSettings(settings);
  }

  // 更新页面大小
  Future<void> updatePageSize(int pageSize) async {
    final settings = getSettings().copyWith(pageSize: pageSize);
    await saveSettings(settings);
  }

  // 更新是否显示ObjectId
  Future<void> updateShowObjectIds(bool showObjectIds) async {
    final settings = getSettings().copyWith(showObjectIds: showObjectIds);
    await saveSettings(settings);
  }

  // 更新默认规则ID
  Future<void> updateDefaultRuleId(String? defaultRuleId) async {
    final settings = getSettings().copyWith(defaultRuleId: defaultRuleId);
    await saveSettings(settings);
  }

  // 更新是否区分大小写比较
  Future<void> updateCaseSensitiveComparison(
    bool caseSensitiveComparison,
  ) async {
    final settings = getSettings().copyWith(
      caseSensitiveComparison: caseSensitiveComparison,
    );
    await saveSettings(settings);
  }

  // 更新默认导出格式
  Future<void> updateDefaultExportFormat(
    ExportFormat defaultExportFormat,
  ) async {
    final settings = getSettings().copyWith(
      defaultExportFormatIndex: defaultExportFormat.index,
    );
    await saveSettings(settings);
  }

  // 更新是否在同步前确认
  Future<void> updateConfirmBeforeSync(bool confirmBeforeSync) async {
    final settings = getSettings().copyWith(
      confirmBeforeSync: confirmBeforeSync,
    );
    await saveSettings(settings);
  }

  // 更新是否启用日志记录
  Future<void> updateEnableLogging(bool enableLogging) async {
    final settings = getSettings().copyWith(enableLogging: enableLogging);
    await saveSettings(settings);
  }
}
