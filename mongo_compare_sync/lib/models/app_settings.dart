import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4)
class AppSettings extends HiveObject {
  @HiveField(0)
  String id;

  // 主题设置
  @HiveField(1)
  int themeModeIndex;

  // 语言设置
  @HiveField(2)
  String locale;

  // 数据显示设置
  @HiveField(3)
  int pageSize;

  @HiveField(4)
  bool showObjectIds;

  // 比较设置
  @HiveField(5)
  String? defaultRuleId;

  @HiveField(6)
  bool caseSensitiveComparison;

  // 导出设置
  @HiveField(7)
  int defaultExportFormatIndex;

  // 其他设置
  @HiveField(8)
  bool confirmBeforeSync;

  @HiveField(9)
  bool enableLogging;

  AppSettings({
    required this.id,
    this.themeModeIndex = 0, // 0: system, 1: light, 2: dark
    this.locale = 'zh_CN',
    this.pageSize = 20,
    this.showObjectIds = true,
    this.defaultRuleId,
    this.caseSensitiveComparison = true,
    this.defaultExportFormatIndex = 0, // 0: json, 1: csv, 2: markdown
    this.confirmBeforeSync = true,
    this.enableLogging = false,
  });

  // 获取主题模式
  ThemeMode get themeMode {
    return ThemeMode.values[themeModeIndex];
  }

  // 设置主题模式
  set themeMode(ThemeMode mode) {
    themeModeIndex = mode.index;
  }

  // 获取导出格式
  ExportFormat get defaultExportFormat {
    return ExportFormat.values[defaultExportFormatIndex];
  }

  // 设置导出格式
  set defaultExportFormat(ExportFormat format) {
    defaultExportFormatIndex = format.index;
  }

  // 创建默认设置
  static AppSettings createDefault(String id) {
    return AppSettings(id: id);
  }
}

// 导出格式枚举
@HiveType(typeId: 5)
enum ExportFormat {
  @HiveField(0)
  json,
  @HiveField(1)
  csv,
  @HiveField(2)
  markdown,
}
