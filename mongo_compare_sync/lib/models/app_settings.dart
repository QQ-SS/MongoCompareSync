import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_settings.g.dart';

@JsonSerializable()
class AppSettings {
  final String id;

  // 主题设置
  final int themeModeIndex;

  // 语言设置
  final String locale;

  // 数据显示设置
  final int pageSize;
  final bool showObjectIds;
  final int maxDocuments;

  // 比较设置
  final String? defaultRuleId;
  final bool caseSensitiveComparison;

  // 导出设置
  final int defaultExportFormatIndex;

  // 其他设置
  final bool confirmBeforeSync;
  final bool enableLogging;

  AppSettings({
    required this.id,
    this.themeModeIndex = 0, // 0: system, 1: light, 2: dark
    this.locale = 'zh_CN',
    this.pageSize = 20,
    this.showObjectIds = true,
    this.maxDocuments = 2000,
    this.defaultRuleId,
    this.caseSensitiveComparison = true,
    this.defaultExportFormatIndex = 0, // 0: json, 1: csv, 2: markdown
    this.confirmBeforeSync = true,
    this.enableLogging = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  // 获取主题模式
  ThemeMode get themeMode {
    return ThemeMode.values[themeModeIndex];
  }

  // 设置主题模式
  AppSettings copyWithThemeMode(ThemeMode mode) {
    return copyWith(themeModeIndex: mode.index);
  }

  // 获取导出格式
  ExportFormat get defaultExportFormat {
    return ExportFormat.values[defaultExportFormatIndex];
  }

  // 设置导出格式
  AppSettings copyWithDefaultExportFormat(ExportFormat format) {
    return copyWith(defaultExportFormatIndex: format.index);
  }

  // 创建默认设置
  static AppSettings createDefault(String id) {
    return AppSettings(id: id);
  }

  AppSettings copyWith({
    String? id,
    int? themeModeIndex,
    String? locale,
    int? pageSize,
    bool? showObjectIds,
    int? maxDocuments,
    String? defaultRuleId,
    bool? caseSensitiveComparison,
    int? defaultExportFormatIndex,
    bool? confirmBeforeSync,
    bool? enableLogging,
  }) {
    return AppSettings(
      id: id ?? this.id,
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      locale: locale ?? this.locale,
      pageSize: pageSize ?? this.pageSize,
      showObjectIds: showObjectIds ?? this.showObjectIds,
      maxDocuments: maxDocuments ?? this.maxDocuments,
      defaultRuleId: defaultRuleId ?? this.defaultRuleId,
      caseSensitiveComparison:
          caseSensitiveComparison ?? this.caseSensitiveComparison,
      defaultExportFormatIndex:
          defaultExportFormatIndex ?? this.defaultExportFormatIndex,
      confirmBeforeSync: confirmBeforeSync ?? this.confirmBeforeSync,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }
}

@JsonEnum()
enum ExportFormat { json, csv, markdown }
